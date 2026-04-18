package org.korelium.koralauncher

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    companion object {
        const val CHANNEL = "com.koralauncher.app/native"
        var methodChannel: MethodChannel? = null
    }

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Removed expensive wallpaper setting that was causing cold-start lag.
        // The background is already handled by the Flutter UI and LaunchTheme.

        // Register the on-device AI bridge (Gemini Nano / AICore)
        GeminiNanoBridge.register(flutterEngine, applicationContext)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->

            when (call.method) {
                "sendBlockedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    AccessibilityWatcherService.updateBlockedApps(packages)
                    result.success(null)
                }
                "isDefaultLauncher" -> {
                    result.success(isDefaultLauncher())
                }
                "hasUsagePermission" -> {
                    result.success(hasUsagePermission())
                }
                "openUsageSettings" -> {
                    openUsageSettings()
                    result.success(null)
                }
                "openDefaultLauncherSettings" -> {
                    openDefaultLauncherSettings()
                    result.success(null)
                }
                "getRawUsageStats" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val stats = getRawUsageStats(startTime, endTime)
                    result.success(stats)
                }
                "lockScreen" -> {
                    lockScreen()
                    result.success(null)
                }
                "hasAccessibilityPermission" -> {
                    result.success(hasAccessibilityPermission())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "setSystemWallpaper" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        try {
                            val wallpaperManager = android.app.WallpaperManager.getInstance(applicationContext)
                            val bitmap = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)

                            // Get real screen dimensions to accurately center-crop for the device
                            val metrics = android.util.DisplayMetrics()
                            windowManager.defaultDisplay.getRealMetrics(metrics)
                            val screenRatio = metrics.widthPixels.toFloat() / metrics.heightPixels.toFloat()
                            val bitmapRatio = bitmap.width.toFloat() / bitmap.height.toFloat()

                            val finalBitmap = if (bitmapRatio > screenRatio) {
                                // Bitmap is wider than screen -> crop width equally from both sides (center horizontally)
                                val newWidth = (bitmap.height * screenRatio).toInt()
                                val startX = (bitmap.width - newWidth) / 2
                                android.graphics.Bitmap.createBitmap(bitmap, startX, 0, newWidth, bitmap.height)
                            } else {
                                // Bitmap is taller than screen -> crop height equally from top/bottom
                                val newHeight = (bitmap.width / screenRatio).toInt()
                                val startY = (bitmap.height - newHeight) / 2
                                android.graphics.Bitmap.createBitmap(bitmap, 0, startY, bitmap.width, newHeight)
                            }

                            wallpaperManager.setBitmap(finalBitmap, null, true, android.app.WallpaperManager.FLAG_SYSTEM or android.app.WallpaperManager.FLAG_LOCK)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "queryLauncherApps" -> {
                    try {
                        result.success(queryAllLauncherApps())
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                "getAppIcon" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg != null) {
                        try {
                            result.success(getAppIconBytes(pkg))
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                "getStoredShortcuts" -> {
                    val shortcuts = org.korelium.koralauncher.ShortcutStore.getAll(applicationContext).toMutableList()
                    
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N_MR1) {
                        try {
                            val la = getSystemService(android.content.Context.LAUNCHER_APPS_SERVICE) as android.content.pm.LauncherApps
                            val query = android.content.pm.LauncherApps.ShortcutQuery()
                            query.setQueryFlags(android.content.pm.LauncherApps.ShortcutQuery.FLAG_MATCH_PINNED)
                            
                            val userManager = getSystemService(android.content.Context.USER_SERVICE) as android.os.UserManager
                            for (user in userManager.userProfiles) {
                                val pinnedShortcuts = la.getShortcuts(query, user)
                                if (pinnedShortcuts != null) {
                                    for (info in pinnedShortcuts) {
                                        val name = info.shortLabel?.toString() ?: info.longLabel?.toString() ?: "Shortcut"
                                        val targetPackage = info.`package` ?: info.activity?.packageName
                                        val shortcutId = info.id
                                        
                                        if (targetPackage != null && shortcuts.none { it["shortcutId"] == shortcutId && it["targetPackage"] == targetPackage }) {
                                            val drawable = la.getShortcutIconDrawable(info, resources.displayMetrics.densityDpi)
                                            val iconBytes = drawable?.let { 
                                                val bmp = org.korelium.koralauncher.ShortcutStore.drawableToBitmap(it, 192)
                                                org.korelium.koralauncher.ShortcutStore.bitmapToBytes(bmp)
                                            }

                                            shortcuts.add(mapOf(
                                                "id" to info.id,
                                                "name" to name,
                                                "targetPackage" to targetPackage,
                                                "shortcutId" to shortcutId,
                                                "icon" to iconBytes,
                                                "isShortcut" to true
                                            ))
                                        }
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("KoraShortcut", "Failed to get system shortcuts", e)
                        }
                    }

                    val forFlutter = shortcuts.map { s ->
                        val b64 = s["iconBase64"] as? String
                        val iconBytes = s["icon"] as? ByteArray ?: if (!b64.isNullOrBlank()) org.korelium.koralauncher.ShortcutStore.base64ToBytes(b64) else null
                        mapOf(
                            "id"         to (s["id"] as? String ?: ""),
                            "name"       to (s["name"] as? String ?: ""),
                            "intentUri"  to (s["intentUri"] as? String),
                            "targetPackage" to (s["targetPackage"] as? String),
                            "shortcutId" to (s["shortcutId"] as? String),
                            "icon"       to iconBytes,
                            "isShortcut" to true,
                        )
                    }
                    result.success(forFlutter)
                }
                "launchShortcut" -> {
                    val uri = call.argument<String>("intentUri")
                    val targetPackage = call.argument<String>("targetPackage")
                    val shortcutId = call.argument<String>("shortcutId")

                    try {
                        if (!targetPackage.isNullOrBlank() && !shortcutId.isNullOrBlank() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
                            val la = getSystemService(Context.LAUNCHER_APPS_SERVICE) as android.content.pm.LauncherApps
                            la.startShortcut(targetPackage, shortcutId, null, null, android.os.Process.myUserHandle())
                            result.success(null)
                        } else if (!uri.isNullOrBlank()) {
                            val launchIntent = Intent.parseUri(uri, Intent.URI_INTENT_SCHEME)
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(null)
                        } else {
                            result.error("MISSING_ARG", "Either targetPackage+shortcutId or intentUri required", null)
                        }
                    } catch (e: Exception) {
                        result.error("LAUNCH_ERROR", e.message, null)
                    }
                }
                "removeShortcut" -> {
                    val id = call.argument<String>("id")
                    if (id != null) {
                        ShortcutStore.remove(applicationContext, id)
                        result.success(null)
                    } else {
                        result.error("MISSING_ARG", "id required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ─────────────────────────────────────────────
        // PACKAGE BROADCAST RECEIVER
        // Notifies Flutter when apps are installed/uninstalled.
        // ─────────────────────────────────────────────
        val packageFilter = android.content.IntentFilter().apply {
            addAction(android.content.Intent.ACTION_PACKAGE_ADDED)
            addAction(android.content.Intent.ACTION_PACKAGE_REMOVED)
            addAction(android.content.Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        registerReceiver(object : android.content.BroadcastReceiver() {
            override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
                methodChannel?.invokeMethod("onPackageChanged", null)
            }
        }, packageFilter)
    }

    private fun getRawUsageStats(startTime: Long, endTime: Long): Map<String, Long> {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager

        // Digital Wellbeing typically attributes time using UsageEvents.
        // queryAndAggregateUsageStats can drift (especially around day boundaries / activity transitions),
        // which can cause "Firefox today" to show time even when you didn't open it today.
        val usageMap = mutableMapOf<String, Long>()
        val startTimesMsByPackage = mutableMapOf<String, Long>()

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = android.app.usage.UsageEvents.Event()

        var lastForegroundPackage: String? = null
        var lastForegroundStartMs: Long = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue

            when (event.eventType) {
                android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    startTimesMsByPackage[pkg] = event.timeStamp
                    lastForegroundPackage = pkg
                    lastForegroundStartMs = event.timeStamp
                }
                android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val startMs = startTimesMsByPackage.remove(pkg) ?: continue
                    val deltaMs = event.timeStamp - startMs
                    if (deltaMs > 0) {
                        usageMap[pkg] = (usageMap[pkg] ?: 0L) + deltaMs
                    }
                }
            }
        }

        // If something stayed in foreground until the query end, count it up to endTime.
        lastForegroundPackage?.let { pkg ->
            val startMs = startTimesMsByPackage[pkg] ?: lastForegroundStartMs
            val deltaMs = endTime - startMs
            if (deltaMs > 0) {
                usageMap[pkg] = (usageMap[pkg] ?: 0L) + deltaMs
            }
        }

        return usageMap
    }

    private fun openDefaultLauncherSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val roleManager = getSystemService(Context.ROLE_SERVICE) as android.app.role.RoleManager
                if (roleManager.isRoleAvailable(android.app.role.RoleManager.ROLE_HOME)) {
                    val intent = roleManager.createRequestRoleIntent(android.app.role.RoleManager.ROLE_HOME)
                    startActivityForResult(intent, 101)
                    return
                }
            } catch (e: Exception) {
                // Ignore and fall back
            }
        }
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfo: ResolveInfo? = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        val currentHomePackage = resolveInfo?.activityInfo?.packageName
        return currentHomePackage == packageName
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.data = android.net.Uri.parse("package:$packageName")
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
            } catch (e2: Exception) {
                // Ignore
            }
        }
    }

    private fun lockScreen() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
        val compName = android.content.ComponentName(this, AdminReceiver::class.java)

        if (dpm.isAdminActive(compName)) {
            dpm.lockNow()
        } else {
            val intent = Intent(android.app.admin.DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
            intent.putExtra(android.app.admin.DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName)
            intent.putExtra(android.app.admin.DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Kora Launcher needs this permission to double-tap to lock the screen.")
            startActivity(intent)
        }
    }

    private fun hasAccessibilityPermission(): Boolean {
        val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        val serviceName = "$packageName/${AccessibilityWatcherService::class.java.canonicalName}"
        return enabledServices?.contains(serviceName) == true
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Home button pressed while already in launcher — close open drawers
        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME)) {
            methodChannel?.invokeMethod("onHomePressed", null)
            return
        }
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            val componentName = ComponentName(packageName, "$packageName.AccessibilityWatcherService").flattenToString()
            intent.putExtra(":settings:fragment_args_key", componentName)
            intent.putExtra(":settings:show_fragment_args", android.os.Bundle().apply { putString(":settings:fragment_args_key", componentName) })
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback
        }
    }

    // ─────────────────────────────────────────────
    // LAUNCHER APP QUERY
    // Uses ACTION_MAIN + CATEGORY_LAUNCHER — the same query AOSP launchers
    // use. This catches WebAPKs (Chrome PWAs / browser desktop shortcuts)
    // that InstalledApps.getInstalledApps() misses because they don't always
    // register through the standard ApplicationInfo flow.
    // ─────────────────────────────────────────────
    private fun queryAllLauncherApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PackageManager.MATCH_ALL
        } else {
            0
        }

        val resolveInfoList: List<ResolveInfo> = packageManager.queryIntentActivities(intent, flags)

        val result = mutableListOf<Map<String, Any?>>()
        val seenPackages = mutableSetOf<String>()

        for (info in resolveInfoList) {
            val pkg = info.activityInfo?.packageName ?: continue

            // Exclude our own launcher
            if (pkg == "org.korelium.koralauncher" || pkg == "com.koralauncher.app") continue

            // Deduplicate by package name — keep the first (primary) activity
            if (seenPackages.contains(pkg)) continue
            seenPackages.add(pkg)

            val appLabel = info.loadLabel(packageManager).toString()
            val iconBytes = try { getAppIconBytes(pkg) } catch (e: Exception) { null }

            result.add(
                mapOf(
                    "packageName" to pkg,
                    "name" to appLabel,
                    "icon" to iconBytes,
                )
            )
        }

        return result
    }

    private fun getAppIconBytes(packageName: String): ByteArray? {
        val drawable: Drawable = try {
            packageManager.getApplicationIcon(packageName)
        } catch (e: PackageManager.NameNotFoundException) {
            return null
        }
        val bitmap = drawableToBitmap(drawable)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }

        // AdaptiveIconDrawable needs to be rendered onto a canvas
        val size = 192 // px — same resolution installed_apps uses
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
