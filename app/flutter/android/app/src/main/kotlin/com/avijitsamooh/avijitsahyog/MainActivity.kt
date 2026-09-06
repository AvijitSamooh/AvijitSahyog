package com.avijitsamooh.avijitsahyog

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logAuthDiagnostics()
    }

    private fun logAuthDiagnostics() {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES,
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES,
                )
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.apkContentsSigners.orEmpty()
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures.orEmpty()
            }

            Log.i("AvijitAuthDiag", "packageName=" + packageName)
            signatures.forEachIndexed { index, signature ->
                val certificate = signature.toByteArray()
                Log.i(
                    "AvijitAuthDiag",
                    "signer[" + index + "].SHA1=" + digest(certificate, "SHA-1"),
                )
                Log.i(
                    "AvijitAuthDiag",
                    "signer[" + index + "].SHA256=" + digest(certificate, "SHA-256"),
                )
            }

            val resourceId = resources.getIdentifier(
                "default_web_client_id",
                "string",
                packageName,
            )
            val webClientId = if (resourceId != 0) {
                getString(resourceId)
            } else {
                "<missing>"
            }
            Log.i("AvijitAuthDiag", "default_web_client_id=" + webClientId)
        } catch (error: Exception) {
            Log.e("AvijitAuthDiag", "Unable to collect auth diagnostics", error)
        }
    }

    private fun digest(bytes: ByteArray, algorithm: String): String =
        MessageDigest.getInstance(algorithm)
            .digest(bytes)
            .joinToString(":") { "%02X".format(it) }
}
