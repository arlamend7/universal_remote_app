package br.net.devcom.universal_remote_app

import android.content.Context
import android.net.wifi.WifiManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var preferencesChannel: PreferencesChannel? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        preferencesChannel = PreferencesChannel(applicationContext, messenger)
        DriverChannel.register(applicationContext, messenger)
        MethodChannel(messenger, "br.net.devcom.universal_remote/display")
            .setMethodCallHandler { call, result ->
                val enabled = call.arguments as? Boolean
                if (call.method != "setScreenAwake" || enabled == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                if (enabled) window.addFlags(flag) else window.clearFlags(flag)
                result.success(null)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "br.net.devcom.universal_remote/network").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "acquireMulticast" -> {
                        if (multicastLock == null) {
                            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            multicastLock = wifi.createMulticastLock("universal_remote_ssdp").apply {
                                setReferenceCounted(false)
                                acquire()
                            }
                        }
                        result.success(null)
                    }
                    "releaseMulticast" -> { releaseMulticast(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) { result.error("network", "Multicast access unavailable", null) }
        }
    }
    private fun releaseMulticast() {
        multicastLock?.let { if (it.isHeld) it.release() }
        multicastLock = null
    }
    override fun onDestroy() { preferencesChannel?.close(); super.onDestroy() }
    override fun onStop() { releaseMulticast(); super.onStop() }
}
