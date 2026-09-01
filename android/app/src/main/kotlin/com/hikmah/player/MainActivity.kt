package com.hikmah.player

import android.os.Handler
import android.os.Looper
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
        "sdkInt" -> result.success(android.os.Build.VERSION.SDK_INT)
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
}