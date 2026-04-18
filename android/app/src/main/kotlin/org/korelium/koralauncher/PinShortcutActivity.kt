package org.korelium.koralauncher

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.widget.Toast

class PinShortcutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            val request: android.content.pm.LauncherApps.PinItemRequest? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(
                        android.content.pm.LauncherApps.EXTRA_PIN_ITEM_REQUEST,
                        android.content.pm.LauncherApps.PinItemRequest::class.java
                    )
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(android.content.pm.LauncherApps.EXTRA_PIN_ITEM_REQUEST)
                }

            if (request != null && request.requestType == android.content.pm.LauncherApps.PinItemRequest.REQUEST_TYPE_SHORTCUT) {
                val info = request.shortcutInfo
                if (info != null) {
                    val name = info.shortLabel?.toString() ?: info.longLabel?.toString() ?: "Shortcut"
                    @Suppress("DEPRECATION")
                    val targetPackage = info.`package` ?: info.activity?.packageName
                    val shortcutId = info.id

                    if (targetPackage != null && shortcutId != null) {
                        val iconBytes: ByteArray? = try {
                            val la = getSystemService(Context.LAUNCHER_APPS_SERVICE) as android.content.pm.LauncherApps
                            val drawable = la.getShortcutIconDrawable(info, resources.displayMetrics.densityDpi)
                            drawable?.let {
                                val bmp = ShortcutStore.drawableToBitmap(it, 192)
                                ShortcutStore.bitmapToBytes(bmp)
                            }
                        } catch (e: Exception) {
                            null
                        }

                        ShortcutStore.saveModern(applicationContext, info.id, name, targetPackage, shortcutId, iconBytes)
                        request.accept()
                        Toast.makeText(applicationContext, "Added shortcut '$name'", Toast.LENGTH_SHORT).show()
                        
                        try {
                            MainActivity.methodChannel?.invokeMethod("onPackageChanged", null)
                        } catch (e: Exception) {
                            // Ignored if flutter is not active
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("KoraShortcut", "PinShortcutActivity failed: ${e.message}")
        }
        
        finish()
    }
}
