package br.net.devcom.universal_remote_app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PreferencesChannel(context: Context, messenger: BinaryMessenger) {
    private val preferences = context.getSharedPreferences("universal_remote_preferences", Context.MODE_PRIVATE)
    private val channel = MethodChannel(messenger, "br.net.devcom.universal_remote/preferences")
    private val allowedKeys = setOf("saved-devices.v1", "dashboards.v1", "settings.theme", "settings.diagnostics", "settings.accent", "settings.feedback")
    init { channel.setMethodCallHandler(::handle) }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key")
        if (key == null || key !in allowedKeys) {
            result.error("invalid_key", "Only non-secret preferences are supported.", null)
            return
        }
        when (call.method) {
            "read" -> result.success(preferences.getString(key, null))
            "write" -> write(call, key, result)
            "delete" -> { preferences.edit().remove(key).apply(); result.success(null) }
            else -> result.notImplemented()
        }
    }
    private fun write(call: MethodCall, key: String, result: MethodChannel.Result) {
        val value = call.argument<String>("value")
        if (value == null) { result.error("invalid_value", "A string value is required.", null); return }
        preferences.edit().putString(key, value).apply()
        result.success(null)
    }
    fun close() { channel.setMethodCallHandler(null) }
}
