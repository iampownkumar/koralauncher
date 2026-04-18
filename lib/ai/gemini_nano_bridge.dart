import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel bridge to Android's native AICore / Gemini Nano.
///
/// This is a **thin, portable bridge** — it only handles the platform channel
/// communication.  All prompt construction and fallback logic lives in
/// [AIPromptEngine].
///
/// The native side (Kotlin) is responsible for:
///   1. Checking if AICore + Gemini Nano are available on the device.
///   2. Initializing the model (lazy, on first use).
///   3. Generating content and returning the text result.
///   4. Respecting battery state — declining inference when battery is low.
///
/// If the native side is not implemented (or the device doesn't support it),
/// every method returns a safe default (null / false).
class GeminiNanoBridge {
  static const MethodChannel _channel = MethodChannel(
    'org.korelium.koralauncher/gemininano',
  );

  /// Cached support check — only queried once per app lifecycle.
  static bool? _supportedCache;

  /// Whether Gemini Nano / AICore is available on this device.
  ///
  /// Returns `false` on any error or if the native bridge hasn't been
  /// implemented yet.  This is intentionally safe — the caller can just
  /// fall back to templates without crashing.
  static Future<bool> isSupported() async {
    if (_supportedCache != null) return _supportedCache!;

    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      _supportedCache = result ?? false;
      debugPrint('GeminiNano: isSupported = $_supportedCache');
      return _supportedCache!;
    } on MissingPluginException {
      // Native bridge not yet implemented — this is expected during
      // initial development.  Template engine will handle generation.
      debugPrint('GeminiNano: native bridge not available (MissingPlugin)');
      _supportedCache = false;
      return false;
    } catch (e) {
      debugPrint('GeminiNano: isSupported check failed: $e');
      _supportedCache = false;
      return false;
    }
  }

  /// Request the native side to generate content using Gemini Nano.
  ///
  /// [prompt] is the full system+user prompt string.
  ///
  /// Returns `null` if:
  ///   - The device doesn't support Gemini Nano
  ///   - The model isn't ready / downloaded yet
  ///   - Battery is too low (native side gates this)
  ///   - Any error occurs
  ///
  /// The caller should always have a template fallback ready.
  static Future<String?> generateContent(String prompt) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'generateContent',
        {'prompt': prompt},
      );
      return result;
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('GeminiNano: generateContent failed: $e');
      return null;
    }
  }

  /// Pre-warm the model so the first real inference is faster.
  ///
  /// Call this during app startup (non-blocking).  If the device doesn't
  /// support Gemini Nano, this is a no-op.
  static Future<void> warmUp() async {
    try {
      await _channel.invokeMethod<void>('warmUp');
    } catch (_) {
      // Silently ignore — warm-up is best-effort.
    }
  }

  /// Invalidate the cached support check.
  ///
  /// Call this if the user installs AICore or updates their device.
  static void invalidateCache() {
    _supportedCache = null;
  }
}
