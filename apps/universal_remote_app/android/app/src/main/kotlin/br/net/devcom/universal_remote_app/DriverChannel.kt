package br.net.devcom.universal_remote_app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec

internal object DriverChannel {
    private const val channel = "br.net.devcom.universal_remote/drivers"
    private val p256Prefix = "3059301306072a8648ce3d020106082a8648ce3d030107034200"
        .chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "storageDirectory" -> result.success(File(context.noBackupFilesDir, "remote-drivers").path)
                "verify" -> result.success(verify(
                    call.argument<ByteArray>("key"),
                    call.argument<ByteArray>("payload"),
                    call.argument<ByteArray>("signature")
                ))
                else -> result.notImplemented()
            }
        }
    }

    private fun verify(key: ByteArray?, payload: ByteArray?, signature: ByteArray?): Boolean {
        if (key == null || key.size != 65 || key[0].toInt() != 4 ||
            payload == null || payload.size > 4 * 1024 * 1024 ||
            signature == null || signature.size > 256) return false
        return try {
            val publicKey = KeyFactory.getInstance("EC")
                .generatePublic(X509EncodedKeySpec(p256Prefix + key))
            Signature.getInstance("SHA256withECDSA").run {
                initVerify(publicKey)
                update(payload)
                verify(signature)
            }
        } catch (_: java.security.GeneralSecurityException) {
            false
        }
    }
}
