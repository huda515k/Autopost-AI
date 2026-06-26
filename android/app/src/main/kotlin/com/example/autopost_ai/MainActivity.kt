package com.example.autopost_ai

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "instagram_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isInstagramInstalled" -> {
                    result.success(isInstagramInstalled())
                }

                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("invalid_package", "Package name is missing.", null)
                        return@setMethodCallHandler
                    }
                    result.success(isAppInstalled(packageName))
                }

                "shareToInstagram" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val caption = call.argument<String>("caption") ?: ""
                    val packageName = call.argument<String>("packageName") ?: "com.instagram.android"

                    if (imagePath.isNullOrBlank()) {
                        result.error("invalid_image", "Image path is missing.", null)
                        return@setMethodCallHandler
                    }

                    if (!isAppInstalled(packageName)) {
                        result.error("app_not_installed", "$packageName is not installed.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        shareImageToPlatform(imagePath, caption, packageName)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("share_failed", e.message, null)
                    }
                }

                "shareToPlatform" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val caption = call.argument<String>("caption") ?: ""
                    val packageName = call.argument<String>("packageName")

                    if (imagePath.isNullOrBlank()) {
                        result.error("invalid_image", "Image path is missing.", null)
                        return@setMethodCallHandler
                    }

                    if (packageName.isNullOrBlank()) {
                        result.error("invalid_package", "Package name is missing.", null)
                        return@setMethodCallHandler
                    }

                    if (!isAppInstalled(packageName)) {
                        result.error("app_not_installed", "$packageName is not installed.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        shareImageToPlatform(imagePath, caption, packageName)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("share_failed", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun isInstagramInstalled(): Boolean {
        return isAppInstalled("com.instagram.android")
    }

    private fun shareImageToPlatform(imagePath: String, caption: String, packageName: String) {
        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            throw IllegalArgumentException("Shared image file does not exist.")
        }

        val uri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            imageFile
        )

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/*"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, caption)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            setPackage(packageName)
        }

        if (intent.resolveActivity(packageManager) == null) {
            throw IllegalStateException("$packageName cannot handle the share intent.")
        }

        startActivity(intent)
    }
}
