package com.nguyendinhthienloc.questory

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORY_SHARE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "sharePng") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val title = call.argument<String>("title") ?: "Questory story"
            if (path.isNullOrBlank()) {
                result.error("missing_path", "The PNG path is required.", null)
                return@setMethodCallHandler
            }

            try {
                val file = File(path).canonicalFile
                val cacheRoot = cacheDir.canonicalFile
                val isInsideCache =
                    file.path.startsWith(cacheRoot.path + File.separator)
                if (!isInsideCache || !file.isFile) {
                    result.error(
                        "invalid_export",
                        "The exported PNG is missing or outside app cache.",
                        null,
                    )
                    return@setMethodCallHandler
                }

                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file,
                )
                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_SUBJECT, title)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(Intent.createChooser(shareIntent, "Share Questory story"))
                result.success(null)
            } catch (error: Exception) {
                result.error("share_failed", error.message, null)
            }
        }
    }

    companion object {
        private const val STORY_SHARE_CHANNEL = "questory/story_share"
    }
}
