package br.net.devcom.universal_remote_app

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var preferencesChannel: PreferencesChannel? = null
    private var multicastLock: WifiManager.MulticastLock? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        preferencesChannel = PreferencesChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
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
