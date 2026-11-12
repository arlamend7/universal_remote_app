package br.net.devcom.universal_remote_app

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class LocalNetworkChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "br.net.devcom.universal_remote/local_network")
    private var pendingPermission: MethodChannel.Result? = null
    private var requestedNamePermission = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "snapshot" -> result.success(snapshot(call.arguments != false))
                "requestNamePermission" -> requestNamePermission(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun snapshot(includeName: Boolean): Map<String, Any> {
        val connectivity = activity.getSystemService(ConnectivityManager::class.java)
        val network = connectivity?.getNetworkCapabilities(connectivity.activeNetwork)
        return when {
            network?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true ->
                if (includeName) wifiSnapshot() else mapOf("transport" to "wifi")
            network?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true ->
                mapOf("transport" to "ethernet")
            else -> mapOf("transport" to "offline")
        }
    }

    @Suppress("DEPRECATION")
    private fun wifiSnapshot(): Map<String, Any> {
        val allowed = hasNamePermission()
        val result = mutableMapOf<String, Any>(
            "transport" to "wifi",
            "canRequestName" to (!allowed && !requestedNamePermission),
        )
        if (!allowed) return result
        val wifi = activity.applicationContext.getSystemService(WifiManager::class.java)
        val ssid = try {
            wifi?.connectionInfo?.ssid
        } catch (_: SecurityException) {
            null
        }
        if (!ssid.isNullOrBlank() && ssid != WifiManager.UNKNOWN_SSID) {
            result["name"] = ssid.removeSurrounding("\"")
        }
        return result
    }

    private fun hasNamePermission(): Boolean =
        activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestNamePermission(result: MethodChannel.Result) {
        if (hasNamePermission() || requestedNamePermission) {
            result.success(null)
            return
        }
        pendingPermission = result
        requestedNamePermission = true
        activity.requestPermissions(
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            namePermissionRequest,
        )
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != namePermissionRequest) return
        pendingPermission?.success(null)
        pendingPermission = null
    }

    fun close() {
        pendingPermission?.success(null)
        pendingPermission = null
        channel.setMethodCallHandler(null)
    }

    private companion object {
        const val namePermissionRequest = 732
    }
}
