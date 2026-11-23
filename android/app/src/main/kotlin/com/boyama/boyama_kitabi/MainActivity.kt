package com.boyama.boyama_kitabi

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Çocuk kilidi için Android'in "ekran sabitleme" (lock task) özelliğini Flutter'a açar.
 * Sabitlenmişken ana ekran, son uygulamalar ve bildirim çubuğu çalışmaz; uygulamadan
 * sadece ebeveyn şifresiyle (uygulama içinden) çıkılır.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "boyama/kiosk")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            if (!isLocked()) startLockTask()
                            result.success(true)
                        }
                        "stop" -> {
                            if (isLocked()) stopLockTask()
                            result.success(true)
                        }
                        "isLocked" -> result.success(isLocked())
                        "exit" -> {
                            if (isLocked()) stopLockTask()
                            finishAndRemoveTask()
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("kiosk", e.message, null)
                }
            }
    }

    private fun isLocked(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            @Suppress("DEPRECATION")
            am.isInLockTaskMode
        }
    }
}
