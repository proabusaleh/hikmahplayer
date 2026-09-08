package com.hikmah.player

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    val messenger = flutterEngine.dartExecutor.binaryMessenger

    val mediaScanner =
      MethodChannel(messenger, "com.hikmahplayer/media_scanner")
    mediaScanner.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
      when (call.method) {
        "scanVideos" -> runScan(MediaStoreScanner.KIND_VIDEO, result)
        "scanAudio" -> runScan(MediaStoreScanner.KIND_AUDIO, result)
        "sdkInt" -> result.success(Build.VERSION.SDK_INT)
        "allFilesAccess" -> result.success(MediaStoreScanner.hasFullFileAccess(applicationContext))
        "requestAllFilesAccess" -> requestAllFilesAccess(result)
        "cancelScan" -> {
          MediaStoreScanner.cancel()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }

  /** Runs the MediaStore query off the UI thread and posts the result back. */
  private fun runScan(kind: String, result: MethodChannel.Result) {
    Thread {
      try {
        val items = MediaStoreScanner.scan(applicationContext, kind)
        Handler(Looper.getMainLooper()).post { result.success(items) }
      } catch (error: Exception) {
        Handler(Looper.getMainLooper())
          .post { result.error("MEDIA_SCAN_FAILED", error.message, null) }
      }
    }.start()
  }

  /**
   * Opens the system "All files access" screen (Android 11+) so the scanner can
   * reach SD-card / USB-OTG / other volumes that MediaStore may not index.
   */
  private fun requestAllFilesAccess(result: MethodChannel.Result) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
      result.success(false)
      return
    }
    runOnUiThread {
      try {
        val intent = Intent(
          Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
          Uri.parse("package:$packageName"),
        )
        startActivity(intent)
        result.success(true)
      } catch (error: Exception) {
        // Some OEMs hide the target intent; fall back to the app info page.
        try {
          startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
          result.success(true)
        } catch (fallback: Exception) {
          result.error("ALL_FILES_ACCESS_UNAVAILABLE", fallback.message, null)
        }
      }
    }
  }
}