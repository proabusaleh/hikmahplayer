package com.hikmah.player

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore

/**
 * Native half of the Dart [MediaScanner] bridge
 * (see lib/core/utils/media_scanner.dart).
 *
 * Enumerates on-device videos and audio by querying the Android MediaStore.
 * On Android 13+ the queries are backed by the READ_MEDIA_VIDEO /
 * READ_MEDIA_AUDIO permissions granted during onboarding; on older versions
 * READ_EXTERNAL_STORAGE applies. MediaStore only returns rows the calling
 * app has read access to, which respects scoped storage.
 *
 * The returned map keys match the ScannedMedia model consumed on the Dart
 * side so no further transformation is needed.
 */
object MediaStoreScanner {

  const val KIND_VIDEO = "video"
  const val KIND_AUDIO = "audio"

  @Volatile
  private var cancelled = false

  /** Marks the current (and any future) scan as cancelled. */
  fun cancel() {
    cancelled = true
  }

  /**
   * Lists the media rows of [kind] (one of [KIND_VIDEO], [KIND_AUDIO]).
   *
   * Runs synchronously on the calling thread; the channel handler schedules
   * it off the UI thread. Never throws for an unusable cursor — a missing
   * permission simply yields an empty list.
   */
  fun scan(context: Context, kind: String): List<Map<String, Any?>> {
    cancelled = false
    val results = ArrayList<Map<String, Any?>>()

    val collection: Uri =
      if (kind == KIND_VIDEO) {
        MediaStore.Video.Media.EXTERNAL_CONTENT_URI
      } else {
        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
      }

    val projection = buildProjection(kind)
    val resolver: ContentResolver = context.contentResolver

    runCatching {
      resolver.query(
        collection,
        projection.toTypedArray(),
        null,
        null,
        null,
      )
    }.getOrNull()?.use { cursor ->
      val indices = Index(
        id = cursor.getColumnIndex(MediaStore.MediaColumns._ID),
        displayName = cursor.getColumnIndex(MediaStore.MediaColumns.DISPLAY_NAME),
        title = cursor.getColumnIndex(MediaStore.MediaColumns.TITLE),
        size = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE),
        mimeType = cursor.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE),
        dateAdded = cursor.getColumnIndex(MediaStore.MediaColumns.DATE_ADDED),
        dateModified = cursor.getColumnIndex(MediaStore.MediaColumns.DATE_MODIFIED),
        relativePath =
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            cursor.getColumnIndex(MediaStore.MediaColumns.RELATIVE_PATH)
          } else {
            -1
          },
        data = cursor.getColumnIndex(MediaStore.MediaColumns.DATA),
        duration = cursor.getColumnIndex(if (kind == KIND_VIDEO) MediaStore.Video.Media.DURATION else MediaStore.Audio.Media.DURATION),
        width = if (kind == KIND_VIDEO) cursor.getColumnIndex(MediaStore.Video.Media.WIDTH) else -1,
        height = if (kind == KIND_VIDEO) cursor.getColumnIndex(MediaStore.Video.Media.HEIGHT) else -1,
        artist = if (kind == KIND_AUDIO) cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST) else -1,
        album = if (kind == KIND_AUDIO) cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM) else -1,
      )

      while (cursor.moveToNext()) {
        if (cancelled) break
        val row = buildRow(cursor, indices, collection)
        if (row != null) results.add(row)
      }
    }

    return results
  }

  private fun buildProjection(kind: String): MutableList<String> {
    val projection = ArrayList<String>()
    projection.add(MediaStore.MediaColumns._ID)
    projection.add(MediaStore.MediaColumns.DISPLAY_NAME)
    projection.add(MediaStore.MediaColumns.TITLE)
    projection.add(MediaStore.MediaColumns.SIZE)
    projection.add(MediaStore.MediaColumns.MIME_TYPE)
    projection.add(MediaStore.MediaColumns.DATE_ADDED)
    projection.add(MediaStore.MediaColumns.DATE_MODIFIED)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      projection.add(MediaStore.MediaColumns.RELATIVE_PATH)
    } else {
      projection.add(MediaStore.MediaColumns.DATA)
    }
    if (kind == KIND_VIDEO) {
      projection.add(MediaStore.Video.Media.DURATION)
      projection.add(MediaStore.Video.Media.WIDTH)
      projection.add(MediaStore.Video.Media.HEIGHT)
    } else {
      projection.add(MediaStore.Audio.Media.DURATION)
      projection.add(MediaStore.Audio.Media.ARTIST)
      projection.add(MediaStore.Audio.Media.ALBUM)
    }
    return projection
  }

  private fun buildRow(
    cursor: android.database.Cursor,
    indices: Index,
    collection: Uri,
  ): Map<String, Any?>? {
    val id = cursor.getLong(indices.id)
    if (id <= 0L) return null

    val uri = ContentUris.withAppendedId(collection, id).toString()
    val displayName = cursor.getString(indices.displayName)
    val rawTitle = cursor.getString(indices.title)

    val folderPath = folderPathOf(cursor, indices)
    val folderName = folderNameOf(folderPath)

    val row = HashMap<String, Any?>()
    row["id"] = id.toString()
    row["uri"] = uri
    row["fileName"] = displayName
    row["title"] = if (rawTitle.isNullOrBlank()) displayName else rawTitle
    row["size"] = if (cursor.isNull(indices.size)) null else cursor.getLong(indices.size)
    row["mimeType"] = cursor.getString(indices.mimeType)
    row["folderPath"] = folderPath
    row["folderName"] = folderName
    row["dateAdded"] = if (cursor.isNull(indices.dateAdded)) null else cursor.getLong(indices.dateAdded) * 1000L
    row["dateModified"] = if (cursor.isNull(indices.dateModified)) null else cursor.getLong(indices.dateModified) * 1000L
    row["durationMs"] = if (cursor.isNull(indices.duration)) null else cursor.getLong(indices.duration)

    if (collection == MediaStore.Video.Media.EXTERNAL_CONTENT_URI) {
      row["width"] = if (indices.width >= 0 && !cursor.isNull(indices.width)) cursor.getInt(indices.width) else null
      row["height"] = if (indices.height >= 0 && !cursor.isNull(indices.height)) cursor.getInt(indices.height) else null
    } else {
      row["artist"] = if (indices.artist >= 0) cursor.getString(indices.artist) else null
      row["album"] = if (indices.album >= 0) cursor.getString(indices.album) else null
    }
    return row
  }

  private fun folderPathOf(cursor: android.database.Cursor, indices: Index): String {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && indices.relativePath >= 0) {
      val relative = cursor.getString(indices.relativePath)
      if (!relative.isNullOrBlank()) return relative.trimEnd('/')
    }
    if (indices.data >= 0) {
      val data = cursor.getString(indices.data)
      if (!data.isNullOrBlank()) {
        val slash = data.lastIndexOf('/')
        if (slash > 0) return data.substring(0, slash)
      }
    }
    return "/"
  }

  private fun folderNameOf(folderPath: String): String =
    folderPath.substring(folderPath.lastIndexOf('/') + 1).ifBlank { folderPath }

  private data class Index(
    val id: Int,
    val displayName: Int,
    val title: Int,
    val size: Int,
    val mimeType: Int,
    val dateAdded: Int,
    val dateModified: Int,
    val relativePath: Int,
    val data: Int,
    val duration: Int,
    val width: Int,
    val height: Int,
    val artist: Int,
    val album: Int,
  )
}