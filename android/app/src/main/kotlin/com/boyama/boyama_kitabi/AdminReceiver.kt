package com.boyama.boyama_kitabi

import android.app.admin.DeviceAdminReceiver

/**
 * "Tam kilit" için cihaz yöneticisi. Ebeveyn bir kez bilgisayardan
 * `adb shell dpm set-device-owner com.boyama.boyama_kitabi/.AdminReceiver`
 * komutunu çalıştırırsa uygulama uyarısız, tam kiosk modunda sabitlenebilir.
 */
class AdminReceiver : DeviceAdminReceiver()
