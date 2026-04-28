package org.korelium.koralauncher

import android.content.Context
import android.util.Log
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

/**
 * On-device LLM inference service using MediaPipe LLM Inference API.
 *
 * Loads a user-downloaded Gemma 2B model and runs inference entirely on-device.
 * No data ever leaves the phone — this is the core privacy promise of Kora.
 *
 * Architecture:
 *   Flutter (OfflineAIEngine) → MethodChannel → GemmaInferenceService → MediaPipe LLM
 */
object GemmaInferenceService {
    private const val TAG = "KoraGemma"
    private const val CHANNEL = "org.korelium.koralauncher/gemma"

    private var llmInference: LlmInference? = null
    private var isLoaded = false
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    fun register(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath == null) {
                        result.error("MISSING_ARG", "modelPath is required", null)
                        return@setMethodCallHandler
                    }

                    scope.launch {
                        try {
                            loadModel(context, modelPath)
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to load model", e)
                            withContext(Dispatchers.Main) {
                                result.error("LOAD_ERROR", e.message, null)
                            }
                        }
                    }
                }

                "generate" -> {
                    val prompt = call.argument<String>("prompt")
                    if (prompt == null) {
                        result.error("MISSING_ARG", "prompt is required", null)
                        return@setMethodCallHandler
                    }

                    if (!isLoaded || llmInference == null) {
                        result.error("NOT_LOADED", "Model not loaded yet", null)
                        return@setMethodCallHandler
                    }

                    scope.launch {
                        try {
                            val response = llmInference!!.generateResponse(prompt)
                            withContext(Dispatchers.Main) {
                                result.success(response)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Inference error", e)
                            withContext(Dispatchers.Main) {
                                result.error("INFERENCE_ERROR", e.message, null)
                            }
                        }
                    }
                }

                "isLoaded" -> {
                    result.success(isLoaded)
                }

                "unloadModel" -> {
                    unloadModel()
                    result.success(true)
                }

                "copyModelFromAdb" -> {
                    val adbPath = call.argument<String>("adbPath")
                    val targetPath = call.argument<String>("targetPath")
                    if (adbPath == null || targetPath == null) {
                        result.error("MISSING_ARG", "adbPath and targetPath required", null)
                        return@setMethodCallHandler
                    }
                    scope.launch {
                        try {
                            val src = java.io.File(adbPath)
                            if (!src.exists()) {
                                withContext(Dispatchers.Main) { result.success(false) }
                                return@launch
                            }
                            val dst = java.io.File(targetPath)
                            dst.parentFile?.mkdirs()
                            src.copyTo(dst, overwrite = true)
                            Log.d(TAG, "Copied model from $adbPath → $targetPath (${dst.length()} bytes)")
                            withContext(Dispatchers.Main) { result.success(true) }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to copy model from ADB path", e)
                            withContext(Dispatchers.Main) { result.success(false) }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun loadModel(context: Context, modelPath: String) {
        // Unload any previously loaded model
        unloadModel()

        Log.d(TAG, "Loading model from: $modelPath")

        // Try CPU first (most compatible), fall back to GPU
        try {
            val cpuOptions = LlmInference.LlmInferenceOptions.builder()
                .setModelPath(modelPath)
                .setMaxTokens(256)
                .setPreferredBackend(LlmInference.Backend.CPU)
                .build()
            llmInference = LlmInference.createFromOptions(context, cpuOptions)
            Log.d(TAG, "Model loaded on CPU successfully")
        } catch (cpuError: Exception) {
            Log.w(TAG, "CPU load failed, trying GPU: ${cpuError.message}")
            try {
                val gpuOptions = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(modelPath)
                    .setMaxTokens(256)
                    .setPreferredBackend(LlmInference.Backend.GPU)
                    .build()
                llmInference = LlmInference.createFromOptions(context, gpuOptions)
                Log.d(TAG, "Model loaded on GPU successfully")
            } catch (gpuError: Exception) {
                Log.e(TAG, "Both CPU and GPU failed", gpuError)
                throw gpuError
            }
        }

        isLoaded = true
    }

    private fun unloadModel() {
        try {
            llmInference?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing model: ${e.message}")
        }
        llmInference = null
        isLoaded = false
    }
}
