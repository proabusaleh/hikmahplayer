package com.hikmah.player

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.MediaStore
import java.io.File

/**
 * Native half of the Dart [MediaScanner] bridge
 * (see lib/core/utils/media_scanner.dart).
 *
 * Discovers videos and audio across EVERY readable storage volume — the
 * internal "device" storage, removable microSD cards, USB-OTG flash drives and
 * any other mounted volume. Two strategies are used, in order of preference:
 *
 *  1. Direct filesystem walk: when "All files access"
 *     (MANAGE_EXTERNAL_STORAGE, Android 11+) is granted — or on Android ≤ 10
 *     once READ_EXTERNAL_STORAGE is granted — every mount under `/storage` is
 *     walked recursively. This finds everything the MediaStore may not index
 *     (OTG drives, freshly copied files) and yields real `file://` paths that
 *     libmpv plays natively.
 *
 *  2. MediaStore fallback (every API level): each external volume known to
 *     MediaStore ([MediaStore.getExternalVolumeNames]) is queried separately
 *     using its own `content://media/<volume>/...` URI. The primary volume
 *     keeps the legacy `content://media/external/...` URI so previously
 *     indexed rows are preserved.
 *
 * Rows are returned as maps whose keys match the Dart [ScannedMedia] model.
 */
object MediaStoreScanner {

  const val KIND_VIDEO = "video"
  const val KIND_AUDIO = "audio"

  private val VIDEO_EXTENSIONS = setOf(
    "mkv", "mp4", "m4v", "avi", "mov", "wmv", "flv", "webm", "mpg", "mpeg",
    "ts", "m2ts", "3gp", "3g2", "ogv", "divx", "rm", "rmvb", "vob", "mts",
  )

  private val AUDIO_EXTENSIONS = setOf(
    "mp3", "m4a", "aac", "flac", "wav", "ogg", "opus", "wma", "aiff", "aif",
    "amr", "mid", "midi", "mka", "ac3", "mp2", "ape", "alac",
  )

  @Volatile
  private var cancelled = false

  /** Marks the current (and any future) scan as cancelled. */
  fun cancel() {
    cancelled = true
    synchronized(this) { pendingWalkRows = null }
  }

  /**
   * Whether the app may read raw filesystem paths (SD/USB/OTG) directly.
   *
   * Android 11+ requires MANAGE_EXTERNAL_STORAGE ("All files access");
   * Android 10 and below are covered by a granted READ_EXTERNAL_STORAGE
   * (scoped storage is not enforced there for legacy apps).
   */
  fun hasFullFileAccess(context: Context): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      return Environment.isExternalStorageManager()
    }
    return hasRuntimePermission(context, android.Manifest.permission.READ_EXTERNAL_STORAGE)
  }

  private fun hasRuntimePermission(context: Context, permission: String): Boolean {
    return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
      context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
  }

  /**
   * Lists the media rows of [kind] (one of [KIND_VIDEO], [KIND_AUDIO]).
   *
   * Uses the filesystem walk when full file access is granted, otherwise
   * queries every MediaStore volume. Runs synchronously on the calling thread;
   * the channel handler schedules it off the UI thread. Never throws for an
   * unusable cursor — a missing permission simply yields an empty list.
   */
  fun scan(context: Context, kind: String): List<Map<String, Any?>> {
    cancelled = false
    if (hasFullFileAccess(context)) {
      // The walker builds both kinds in a single traversal and caches the
      // "other" half so scanVideo() + scanAudio() only walk the tree once.
      return walkOrServeCached(kind)
    }
    return scanMediaStoreVolumes(context, kind)
  }

  // --------------------------------------------------------------------------
  // Filesystem walker
  // --------------------------------------------------------------------------

  /** Cached rows for the kind NOT requested by the first walk of the pair. */
  @Volatile
  private var pendingWalkRows: List<Map<String, Any?>>? = null

  private fun walkOrServeCached(kind: String): List<Map<String, Any?>> {
    synchronized(this) {
      val cached = pendingWalkRows
      if (cached != null) {
        pendingWalkRows = null
        return cached
      }
    }

    val (own, other) = FileSystemWalker.walkStorage(kind)
    synchronized(this) {
      pendingWalkRows = other
    }
    return own
  }

  private object FileSystemWalker {

    /**
     * Walks every mounted volume under `/storage` once, returning
     * `(rowsForRequestedKind, rowsForOtherKind)` so the caller can cache the
     * second half instead of walking the tree twice.
     */
    fun walkStorage(kind: String): Pair<List<Map<String, Any?>>, List<Map<String, Any?>>> {
      val videos = ArrayList<Map<String, Any?>>()
      val audio = ArrayList<Map<String, Any?>>()
      val roots = File("/storage").listFiles() ?: return Pair(videos, audio)
      val visited = HashSet<String>()

      for (root in roots) {
        if (cancelled) break
        if (!root.isDirectory) continue
        visit(root, videos, audio, visited, depth = 0)
      }

      return when (kind) {
        KIND_VIDEO -> Pair(videos, audio)
        else -> Pair(audio, videos)
      }
    }

    private fun visit(
      dir: File,
      videos: MutableList<Map<String, Any?>>,
      audio: MutableList<Map<String, Any?>>,
      visited: MutableSet<String>,
      depth: Int,
    ) {
      if (cancelled || depth > 32) return
      // Guard against symlink cycles (e.g. /storage/emulated/0/self).
      val real = dir.canonicalPath
      if (!visited.add(real)) return

      val children = dir.listFiles() ?: return

      for (child in children) {
        if (cancelled) return
        val name = child.name
        if (name.startsWith(".")) continue

        if (child.isDirectory) {
          if (child.list().orEmpty().any { it.equals(".nomedia", ignoreCase = true) }) {
            continue
          }
          visit(child, videos, audio, visited, depth + 1)
        } else {
          addFileRow(child, videos, audio)
        }
      }
    }

    private fun addFileRow(
      file: File,
      videos: MutableList<Map<String, Any?>>,
      audio: MutableList<Map<String, Any?>>,
    ) {
      if (!file.isFile) return
      val name = file.name ?: return
      val dot = name.lastIndexOf('.')
      if (dot <= 0) return
      val ext = name.substring(dot + 1).lowercase()

      val kind: String = when {
        ext in VIDEO_EXTENSIONS -> KIND_VIDEO
        ext in AUDIO_EXTENSIONS -> KIND_AUDIO
        else -> return
      }

      val parent = file.parentFile
      val folderPath = parent?.absolutePath ?: "/"
      val folderName = parent?.name ?: ""

      val row = HashMap<String, Any?>()
      row["id"] = Math.abs(file.absolutePath.hashCode()).toString()
      row["uri"] = "file://${file.absolutePath}"
      row["fileName"] = name
      row["title"] = name.substring(0, dot)
      row["size"] = file.length().let { if (it > 0) it else null }
      row["mimeType"] = mimeFor(ext)
      row["folderPath"] = folderPath
      row["folderName"] = folderName
      row["dateAdded"] = file.lastModified().takeIf { it > 0 }
      row["dateModified"] = file.lastModified().takeIf { it > 0 }
      row["durationMs"] = null
      row["width"] = null
      row["height"] = null
      row["artist"] = null
      row["album"] = null

      if (kind == KIND_VIDEO) videos.add(row) else audio.add(row)
    }

    private fun mimeFor(ext: String): String = when (ext) {
      in AUDIO_EXTENSIONS -> "audio/$ext"
      else -> "video/$ext"
    }
  }

  // --------------------------------------------------------------------------
  // MediaStore (per-volume) fallback
  // --------------------------------------------------------------------------

  private fun scanMediaStoreVolumes(context: Context, kind: String): List<Map<String, Any?>> {
    val results = ArrayList<Map<String, Any?>>()

    val volumes = runCatching {
      MediaStore.getExternalVolumeNames(context)
    }.getOrDefault(setOf("external_primary"))

    for (volume in volumes) {
      if (cancelled) break
      if (volume == "internal") continue

      val collection: Uri =
        if (volume == "external_primary") {
          if (kind == KIND_VIDEO) MediaStore.Video.Media.EXTERNAL_CONTENT_URI
          else MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        } else {
          if (kind == KIND_VIDEO) MediaStore.Video.Media.getContentUri(volume)
          else MediaStore.Audio.Media.getContentUri(volume)
        }

      runCatching { queryVolume(context, collection, volume, kind) }
        .onFailure { error ->
          android.util.Log.w("MediaStoreScanner", "volume $volume query failed: ${error.message}")
        }
        .getOrNull()
        ?.let(results::addAll)
    }
    return results
  }

  private fun queryVolume(
    context: Context,
    collection: Uri,
    volume: String,
    kind: String,
  ): List<Map<String, Any?>> {
    val projection = buildProjection(kind)
    val resolver: ContentResolver = context.contentResolver

    val rows = ArrayList<Map<String, Any?>>()
    resolver.query(
      collection,
      projection.toTypedArray(),
      null,
      null,
      null,
    )?.use { cursor ->
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

      val volumeRoot = rootOfVolume(context, volume)

      while (cursor.moveToNext()) {
        if (cancelled) break
        val row = buildRow(cursor, indices, collection, volume, volumeRoot, kind)
        if (row != null) rows.add(row)
      }
    }
    return rows
  }

  /**
   * Resolves the mounted root (`/storage/...`) of a MediaStore [volumeName],
   * or `null` when it cannot be determined (typical without All Files Access).
   */
  private fun rootOfVolume(context: Context, volumeName: String): String? {
    val manager = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager
      ?: return null
    for (volume in manager.storageVolumes) {
      val mount = runCatching { volume.directory }.getOrNull() ?: continue
      if (volumeName == mount.name || volume.uuid == volumeName || volume.isPrimary) {
        if (volume.isPrimary && volumeName == "external_primary") return mount.absolutePath
        if (volume.uuid == volumeName || volumeName == mount.name) return mount.absolutePath
      }
    }
    return null
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
    volume: String,
    volumeRoot: String?,
    kind: String,
  ): Map<String, Any?>? {
    val id = cursor.getLong(indices.id)
    if (id <= 0L) return null

    val uri = ContentUris.withAppendedId(collection, id).toString()
    val displayName = cursor.getString(indices.displayName)
    val rawTitle = cursor.getString(indices.title)

    val folderPath = folderPathOf(cursor, indices, volume, volumeRoot)
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

    if (kind == KIND_VIDEO) {
      row["width"] = if (indices.width >= 0 && !cursor.isNull(indices.width)) cursor.getInt(indices.width) else null
      row["height"] = if (indices.height >= 0 && !cursor.isNull(indices.height)) cursor.getInt(indices.height) else null
      row["artist"] = null
      row["album"] = null
    } else {
      row["width"] = null
      row["height"] = null
      row["artist"] = if (indices.artist >= 0) cursor.getString(indices.artist) else null
      row["album"] = if (indices.album >= 0) cursor.getString(indices.album) else null
    }
    return row
  }

  private fun folderPathOf(
    cursor: android.database.Cursor,
    indices: Index,
    volume: String,
    volumeRoot: String?,
  ): String {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && indices.relativePath >= 0) {
      val relative = cursor.getString(indices.relativePath)
      if (!relative.isNullOrBlank()) {
        val trimmed = relative.trimEnd('/')
        // Use an absolute path when the volume's mount point is resolvable so
        // MediaStore rows match the filesystem-walker rows in the library view.
        val root = volumeRoot
        if (root != null && trimmed.isNotEmpty()) return "$root/$trimmed"
        // Otherwise keep folders volume-relative (like the primary volume
        // today), prefixing non-primary volumes with their name so SD/USB
        // folders do not collide in the folder view.
        return if (volume == "external_primary") trimmed else "$volume/$trimmed"
      }
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