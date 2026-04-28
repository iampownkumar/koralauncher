# ── MediaPipe LLM Inference (tasks-genai) ────────────────────────
# Keep all MediaPipe genai classes — uses JNI + reflection
-keep class com.google.mediapipe.tasks.genai.** { *; }

# Suppress warnings for optional MediaPipe framework classes
# (vision/image classes are referenced but not used for text-only LLM inference)
-dontwarn com.google.mediapipe.**

# Keep protobuf classes used by MediaPipe internally
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Suppress R8 warnings for annotation processors (compile-time only)
-dontwarn javax.annotation.processing.**
-dontwarn javax.lang.model.**

# Keep Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
