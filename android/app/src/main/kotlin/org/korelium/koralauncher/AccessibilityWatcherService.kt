package org.korelium.koralauncher

import android.accessibilityservice.AccessibilityService
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class AccessibilityWatcherService : AccessibilityService() {

    companion object {
        private var blockedApps = mutableSetOf<String>()

        fun updateBlockedApps(packages: List<String>) {
            blockedApps.clear()
            blockedApps.addAll(packages)
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var currentForegroundPackage: String? = null
    private var usageCheckRunnable: Runnable? = null

    // Track the last stage we triggered so we don't re-fire the same stage
    // within a single foreground session.
    private var lastTriggeredStageIndex: Int = -1

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // If the user switched away from the flagged app, stop monitoring
        if (packageName != currentForegroundPackage) {
            stopUsageMonitoring()
        }

        if (packageName == applicationContext.packageName) return
        if (!blockedApps.contains(packageName)) return

        // FIX: Detect if device is locked. 
        // If locked, we MUST NOT bring our activity to front or invoke interception,
        // because it would bypass the secure lock screen when a user interacts with a notification.
        val km = getSystemService(android.content.Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
        if (km.isKeyguardLocked) return

        // Bring Kora to foreground so Flutter can show [InterceptionScreen].
        bringKoraToForeground(packageName)

        // Start periodic usage monitoring for real-time stage transitions
        // while the user is using this flagged app
        startUsageMonitoring(packageName)
    }

    private fun bringKoraToForeground(packageName: String) {
        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(launch)

        Handler(Looper.getMainLooper()).post {
            try {
                MainActivity.methodChannel?.invokeMethod(
                    "onAppForeground",
                    mapOf("package" to packageName),
                )
            } catch (_: Exception) {
            }
        }
    }

    /**
     * Start a periodic usage check every 15 seconds while the user is in a flagged app.
     * When usage crosses a stage threshold (50% -> Dim, 100% -> Mirror), we bring Kora
     * to the foreground and trigger the interception screen.
     */
    private fun startUsageMonitoring(packageName: String) {
        stopUsageMonitoring()
        currentForegroundPackage = packageName
        lastTriggeredStageIndex = -1

        usageCheckRunnable = object : Runnable {
            override fun run() {
                if (currentForegroundPackage != packageName) return
                if (!blockedApps.contains(packageName)) {
                    stopUsageMonitoring()
                    return
                }

                // Check if device is locked
                val km = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                if (km.isKeyguardLocked) {
                    handler.postDelayed(this, 15_000L)
                    return
                }

                // Calculate current usage percentage
                val usedMinutes = getUsedMinutesToday(packageName)
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val limitKey = "flutter.rt_limit_minutes_$packageName"
                val limitMinutes = prefs.getInt(limitKey, 15)

                if (limitMinutes <= 0) {
                    handler.postDelayed(this, 15_000L)
                    return
                }

                val percent = usedMinutes.toDouble() / limitMinutes.toDouble()

                // Determine what stage this maps to:
                // 0 = whisper (0-49%), 1 = dim (50-99%), 2 = mirror (100%+)
                val stageIndex = when {
                    percent >= 1.0 -> 2  // mirror
                    percent >= 0.5 -> 1  // dim
                    else -> 0            // whisper
                }

                // Only trigger if we crossed INTO a new higher stage
                if (stageIndex > 0 && stageIndex > lastTriggeredStageIndex) {
                    lastTriggeredStageIndex = stageIndex
                    android.util.Log.d("KoraRisingTide",
                        "Real-time trigger: $packageName used=${usedMinutes}m limit=${limitMinutes}m " +
                        "pct=${(percent * 100).toInt()}% -> stage=$stageIndex")
                    bringKoraToForeground(packageName)
                }

                // Continue monitoring
                handler.postDelayed(this, 15_000L)
            }
        }

        // Start after initial delay (give the first interception time to show)
        handler.postDelayed(usageCheckRunnable!!, 15_000L)
    }

    private fun stopUsageMonitoring() {
        usageCheckRunnable?.let { handler.removeCallbacks(it) }
        usageCheckRunnable = null
        currentForegroundPackage = null
        lastTriggeredStageIndex = -1
    }

    /**
     * Calculate usage minutes today for a given package using UsageEvents
     * (same method as the Flutter-side UsageService for consistency).
     */
    private fun getUsedMinutesToday(packageName: String): Int {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val cal = java.util.Calendar.getInstance()
            cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
            cal.set(java.util.Calendar.MINUTE, 0)
            cal.set(java.util.Calendar.SECOND, 0)
            cal.set(java.util.Calendar.MILLISECOND, 0)
            val startOfDay = cal.timeInMillis

            val events = usm.queryEvents(startOfDay, now)
            val event = UsageEvents.Event()
            var totalMs = 0L
            var lastForegroundMs = 0L

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.packageName != packageName) continue

                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        lastForegroundMs = event.timeStamp
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        if (lastForegroundMs > 0) {
                            totalMs += event.timeStamp - lastForegroundMs
                            lastForegroundMs = 0L
                        }
                    }
                }
            }

            // If still in foreground, count up to now
            if (lastForegroundMs > 0) {
                totalMs += now - lastForegroundMs
            }

            // Round to nearest minute (same as Flutter UsageService)
            ((totalMs + 30_000L) / 60_000L).toInt()
        } catch (e: Exception) {
            android.util.Log.e("KoraRisingTide", "Usage check failed", e)
            0
        }
    }

    override fun onInterrupt() {
    }

    override fun onDestroy() {
        stopUsageMonitoring()
        super.onDestroy()
    }
}
