package org.korelium.koralauncher

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel bridge for on-device AI (Gemini Nano / AICore).
 *
 * This is a **future-ready stub** — it declares the correct channel and
 * method signatures so the Dart side doesn't crash, and provides battery-
 * aware gating.
 *
 * When AICore / ML Kit GenAI becomes available on your target device,
 * replace the stub implementations with real inference calls.
 *
 * Battery policy:
 *   • AI inference is SKIPPED when battery < 15%
 *   • Warm-up is SKIPPED when battery < 20%
 *   • This keeps Kora lightweight — a launcher must never drain battery
 */
object GeminiNanoBridge {
    private const val TAG = "KoraAI"
    private const val CHANNEL = "org.korelium.koralauncher/gemininano"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    // Check if this device supports on-device AI.
                    // For now, returns false (stub).  Replace with real
                    // AICore availability check when integrating:
                    //
                    //   val aiCoreAvailable = try {
                    //       context.packageManager.getPackageInfo("com.google.android.aicore", 0)
                    //       true
                    //   } catch (e: Exception) { false }
                    //
                    val supported = isAICoreAvailable(context)
                    Log.d(TAG, "isSupported: $supported")
                    result.success(supported)
                }

                "generateContent" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt == null) {
                        result.error("MISSING_ARG", "prompt is required", null)
                        return@setMethodCallHandler
                    }

                    // Battery gate: skip AI if battery is critically low
                    val batteryPercent = getBatteryPercent(context)
                    if (batteryPercent in 0..14) {
                        Log.d(TAG, "Skipping AI inference: battery at $batteryPercent%")
                        result.success(null)
                        return@setMethodCallHandler
                    }

                    // ── STUB: Replace with real Gemini Nano inference ──
                    //
                    // When AICore is available, this would look like:
                    //
                    //   val summarizer = Summarizer.create(context, options)
                    //   val aiResult = summarizer.summarize(prompt)
                    //   result.success(aiResult)
                    //
                    // Or for the AI Edge SDK:
                    //
                    //   val sdk = AiEdgeSdk()
                    //   val genResult = sdk.generateContent(prompt)
                    //   result.success(genResult.content)
                    //
                    // For now, return null so the Dart side falls back to templates.
                    Log.d(TAG, "generateContent: returning null (stub)")
                    result.success(null)
                }

                "warmUp" -> {
                    val batteryPercent = getBatteryPercent(context)
                    if (batteryPercent in 0..19) {
                        Log.d(TAG, "Skipping warm-up: battery at $batteryPercent%")
                        result.success(null)
                        return@setMethodCallHandler
                    }

                    // ── STUB: Pre-warm the on-device model ──
                    // When AICore is integrated, initialize the model here
                    // so the first real inference is faster.
                    Log.d(TAG, "warmUp: no-op (stub)")
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Check if AICore system service is available on this device.
     *
     * Returns true if the com.google.android.aicore package is installed.
     * This is the prerequisite for Gemini Nano on-device inference.
     */
    private fun isAICoreAvailable(context: Context): Boolean {
        return try {
            context.packageManager.getPackageInfo("com.google.android.aicore", 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Get current battery percentage (0–100).
     * Returns -1 if unable to determine.
     */
    private fun getBatteryPercent(context: Context): Int {
        return try {
            val batteryStatus = context.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            )
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level >= 0 && scale > 0) {
                (level * 100) / scale
            } else {
                -1
            }
        } catch (e: Exception) {
            -1
        }
    }
}
