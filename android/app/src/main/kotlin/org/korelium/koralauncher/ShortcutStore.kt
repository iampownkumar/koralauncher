package org.korelium.koralauncher

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

/**
 * Persistent store for pinned shortcuts (browser desktop shortcuts, etc.).
 *
 * Firefox "Add to Home Screen" and similar features don't install a new APK.
 * They broadcast INSTALL_SHORTCUT (legacy) or call ShortcutManager.requestPinShortcut()
 * (modern). As the default launcher, Kora must receive these, store them here,
 * and display them alongside regular apps in the drawer.
 *
 * Storage: SharedPreferences → JSON array under key "pinned_shortcuts".
 * Each entry: { id, name, intentUri, iconBase64? }
 */
object ShortcutStore {

    private const val PREFS_NAME = "kora_shortcuts"
    private const val KEY_SHORTCUTS = "pinned_shortcuts"

    // ─── Read ─────────────────────────────────────────────────────────────────

    fun getAll(context: Context): List<Map<String, Any?>> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_SHORTCUTS, null) ?: return emptyList()

        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                mapOf(
                    "id"            to obj.optString("id"),
                    "name"          to obj.optString("name"),
                    "intentUri"     to obj.optString("intentUri").takeIf { it.isNotBlank() },
                    "targetPackage" to obj.optString("targetPackage").takeIf { it.isNotBlank() },
                    "shortcutId"    to obj.optString("shortcutId").takeIf { it.isNotBlank() },
                    "iconBase64"    to obj.optString("iconBase64").takeIf { it.isNotBlank() },
                    "isShortcut"    to true,
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    // ─── Write ────────────────────────────────────────────────────────────────

    fun saveLegacy(context: Context, id: String, name: String, intentUri: String, iconBytes: ByteArray?) {
        val entry = JSONObject().apply {
            put("id",         id)
            put("name",       name)
            put("intentUri",  intentUri)
            put("iconBase64", iconBytes?.let { Base64.encodeToString(it, Base64.NO_WRAP) } ?: "")
        }
        internalSave(context, id, entry)
    }

    fun saveModern(context: Context, id: String, name: String, targetPackage: String, shortcutId: String, iconBytes: ByteArray?) {
        val entry = JSONObject().apply {
            put("id",            id)
            put("name",          name)
            put("targetPackage", targetPackage)
            put("shortcutId",    shortcutId)
            put("iconBase64",    iconBytes?.let { Base64.encodeToString(it, Base64.NO_WRAP) } ?: "")
        }
        internalSave(context, id, entry)
        
        // Android requires launchers to explicitly tell the system we pinned it
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N_MR1) {
            try {
                val la = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as android.content.pm.LauncherApps
                la.pinShortcuts(targetPackage, listOf(shortcutId), android.os.Process.myUserHandle())
            } catch (e: Exception) {
                // Ignore failure
            }
        }
    }

    private fun internalSave(context: Context, id: String, entry: JSONObject) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = try {
            JSONArray(prefs.getString(KEY_SHORTCUTS, null) ?: "[]")
        } catch (e: Exception) {
            JSONArray()
        }

        // Avoid duplicates
        val updated = JSONArray()
        for (i in 0 until existing.length()) {
            val obj = existing.getJSONObject(i)
            if (obj.optString("id") != id) updated.put(obj)
        }
        updated.put(entry)
        prefs.edit().putString(KEY_SHORTCUTS, updated.toString()).apply()
    }

    fun remove(context: Context, id: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = try {
            JSONArray(prefs.getString(KEY_SHORTCUTS, null) ?: "[]")
        } catch (e: Exception) {
            JSONArray()
        }

        val updated = JSONArray()
        for (i in 0 until existing.length()) {
            val obj = existing.getJSONObject(i)
            if (obj.optString("id") != id) updated.put(obj)
        }
        prefs.edit().putString(KEY_SHORTCUTS, updated.toString()).apply()
    }

    // ─── Icon helpers ─────────────────────────────────────────────────────────

    fun bitmapToBytes(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        // Scale down to 192×192 — same size as regular app icons
        val scaled = Bitmap.createScaledBitmap(bitmap, 192, 192, true)
        scaled.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    fun base64ToBytes(base64: String): ByteArray? {
        return try {
            Base64.decode(base64, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    /** Decodes a base64 icon stored in the shortcut entry back to raw bytes for Flutter. */
    fun iconBytesForShortcut(context: Context, id: String): ByteArray? {
        val all = getAll(context)
        val entry = all.firstOrNull { it["id"] == id } ?: return null
        val b64 = entry["iconBase64"] as? String ?: return null
        return base64ToBytes(b64)
    }

    fun drawableToBitmap(drawable: android.graphics.drawable.Drawable, size: Int): Bitmap {
        if (drawable is android.graphics.drawable.BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
