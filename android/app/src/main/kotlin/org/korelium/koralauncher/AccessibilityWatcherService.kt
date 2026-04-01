package org.korelium.koralauncher

import android.accessibilityservice.AccessibilityService
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

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == applicationContext.packageName) return
        if (!blockedApps.contains(packageName)) return

        // Bring Kora to foreground so Flutter can show [InterceptionScreen].
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

    override fun onInterrupt() {
    }
}
