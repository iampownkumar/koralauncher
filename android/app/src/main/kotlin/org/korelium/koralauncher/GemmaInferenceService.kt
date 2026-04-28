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

                else -> result.notImplemented()
            }
        }
    }

    private fun loadModel(context: Context, modelPath: String) {
        // Unload any previously loaded model
        unloadModel()

        Log.d(TAG, "Loading model from: $modelPath")

        val options = LlmInference.LlmInferenceOptions.builder()
            .setModelPath(modelPath)
            .setMaxTokens(256)       // Short responses — we only need 1-2 sentences
            .setTopK(40)
            .setTemperature(0.8f)    // Slight creativity for varied questions
            .setRandomSeed(System.currentTimeMillis().toInt())
            .build()

        llmInference = LlmInference.createFromOptions(context, options)
        isLoaded = true
        Log.d(TAG, "Model loaded successfully")
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
