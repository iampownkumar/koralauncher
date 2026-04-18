package org.korelium.koralauncher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.util.Log
import java.util.UUID

/**
 * Receives the legacy INSTALL_SHORTCUT broadcast that Firefox (and many other
 * browsers/apps) send when the user taps "Add to Home Screen".
 *
 * Modern Android (API 26+) replaced this with ShortcutManager.requestPinShortcut(),
 * which is handled in MainActivity. This receiver covers the legacy path which
 * Firefox still uses as of 2024 for compatibility.
 *
 * Intent extras we care about:
 *   - Intent.EXTRA_SHORTCUT_NAME     → display label
 *   - Intent.EXTRA_SHORTCUT_INTENT   → the Intent to fire on launch
 *   - Intent.EXTRA_SHORTCUT_ICON     → Bitmap (optional)
 *   - Intent.EXTRA_SHORTCUT_ICON_RESOURCE → icon resource (optional fallback)
 */
class ShortcutReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "KoraShortcutReceiver"
        const val ACTION_INSTALL_SHORTCUT = "com.android.launcher.action.INSTALL_SHORTCUT"
        const val ACTION_UNINSTALL_SHORTCUT = "com.android.launcher.action.UNINSTALL_SHORTCUT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_INSTALL_SHORTCUT -> handleInstall(context, intent)
            ACTION_UNINSTALL_SHORTCUT -> handleUninstall(context, intent)
        }
    }

    private fun handleInstall(context: Context, intent: Intent) {
        val name = intent.getStringExtra(Intent.EXTRA_SHORTCUT_NAME) ?: return
        val launchIntent: Intent? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_SHORTCUT_INTENT, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_SHORTCUT_INTENT)
        }

        if (launchIntent == null) {
            Log.w(TAG, "INSTALL_SHORTCUT for '$name' had no launch intent — ignoring")
            return
        }

        val intentUri = launchIntent.toUri(Intent.URI_INTENT_SCHEME)
        val id = UUID.randomUUID().toString()

        // Try to get the icon — Firefox sends it as a raw Bitmap extra
        val iconBytes: ByteArray? = extractIconBytes(intent, context)

        ShortcutStore.saveLegacy(context, id, name, intentUri, iconBytes)
        Log.i(TAG, "Stored shortcut '$name' (id=$id)")

        // Tell Flutter to refresh the app list
        MainActivity.methodChannel?.invokeMethod("onPackageChanged", null)
    }

    private fun handleUninstall(context: Context, intent: Intent) {
        val name = intent.getStringExtra(Intent.EXTRA_SHORTCUT_NAME) ?: return
        // There's no reliable unique ID in the uninstall broadcast — match by name
        val all = ShortcutStore.getAll(context)
        val match = all.firstOrNull { it["name"] == name } ?: return
        ShortcutStore.remove(context, match["id"] as String)
        Log.i(TAG, "Removed shortcut '$name'")
        MainActivity.methodChannel?.invokeMethod("onPackageChanged", null)
    }

    private fun extractIconBytes(intent: Intent, context: Context): ByteArray? {
        // 1. Bitmap extra (most common — Firefox sends this)
        val bitmap: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_SHORTCUT_ICON, Bitmap::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_SHORTCUT_ICON)
        }
        if (bitmap != null) return ShortcutStore.bitmapToBytes(bitmap)

        // 2. IconResource fallback
        val iconResource: Intent.ShortcutIconResource? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, Intent.ShortcutIconResource::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE)
            }
        if (iconResource != null) {
            return try {
                val res = context.packageManager
                    .getResourcesForApplication(iconResource.packageName)
                val id = res.getIdentifier(iconResource.resourceName, null, null)
                val drawable = res.getDrawable(id, null)
                val bmp = (drawable as? BitmapDrawable)?.bitmap
                bmp?.let { ShortcutStore.bitmapToBytes(it) }
            } catch (e: Exception) {
                null
            }
        }
        return null
    }
}
