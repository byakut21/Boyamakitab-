package com.boyama.boyama_kitabi

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Çocuk kilidi için Android'in "ekran sabitleme" (lock task) özelliğini Flutter'a açar.
 *
 * Normalde Android sabitlemeden önce "Uygulama sabitlensin mi?" diye sorar ve
 * "Uygulama sabitlendi" uyarısı gösterir; bunu hiçbir uygulama kapatamaz. Uygulama
 * cihaz sahibi (device owner) yapıldıysa sabitleme soru sormadan, uyarısız ve
 * Geri+Son uygulamalar kısayoluyla bile açılamayacak şekilde ("tam kilit") yapılır.
 */
class MainActivity : FlutterActivity() {
    private val dpm by lazy {
        getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    }
    private val admin by lazy { ComponentName(this, AdminReceiver::class.java) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "boyama/kiosk")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start" -> {
                            if (!isLocked()) {
                                prepareFullLock()
                                startLockTask()
                            }
                            result.success(true)
                        }
                        "stop" -> {
                            if (isLocked()) stopLockTask()
                            result.success(true)
                        }
                        "isLocked" -> result.success(isLocked())
                        "isFullLock" -> result.success(isDeviceOwner())
                        "clearFullLock" -> {
                            if (isLocked()) stopLockTask()
                            if (isDeviceOwner()) {
                                @Suppress("DEPRECATION")
                                dpm.clearDeviceOwnerApp(packageName)
                            }
                            result.success(true)
                        }
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

    private fun isDeviceOwner() = dpm.isDeviceOwnerApp(packageName)

    /** Cihaz sahibiysek bu uygulamaya sorusuz sabitleme izni ver ve sistem tuşlarını kapat. */
    private fun prepareFullLock() {
        if (!isDeviceOwner()) return
        dpm.setLockTaskPackages(admin, arrayOf(packageName))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            dpm.setLockTaskFeatures(admin, DevicePolicyManager.LOCK_TASK_FEATURE_NONE)
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
