package org.korelium.koralauncher

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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

        // The background is already handled by the Flutter UI and LaunchTheme.

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
}
