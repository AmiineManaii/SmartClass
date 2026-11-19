package com.smartclass.smartclass

import android.media.AudioManager
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smartclass.smartclass/alert"
    private val SECURE_CHANNEL = "com.smartclass.smartclass/secure_window"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "playAlertChime") {
                try {
                    val notificationUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    val ringtone = RingtoneManager.getRingtone(applicationContext, notificationUri)
                    ringtone?.play()
                } catch (e: Exception) {
                    try {
                        val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
                        toneGen.startTone(ToneGenerator.TONE_PROP_BEEP2, 200)
                    } catch (_: Exception) {}
                }
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    // Real OS-level blocking: screenshots and screen recording
                    // of this window are refused, and the recents preview is
                    // masked by the system.
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(
                        mapOf(
                            "platform" to "android",
                            "screenshotBlocked" to true,
                            "captureDetection" to false,
                        )
                    )
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

