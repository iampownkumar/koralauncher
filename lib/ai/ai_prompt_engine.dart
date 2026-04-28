import 'package:flutter/foundation.dart';

import '../models/rising_tide_stage.dart';
import 'ai_context_builder.dart';
import 'ai_cache_service.dart';
import 'gemini_nano_bridge.dart';
import 'offline_ai_engine.dart';
import 'template_message_engine.dart';

/// The main AI service for the Rising Tide system.
///
/// Architecture:
/// ```
///  InterceptionScreen
///       │
///       ▼
///  AIPromptEngine.generateMessage()
///       │
///       ├─ Check cache  →  return if fresh
///       │
///       ├─ Build AIContext from user data
///       │
///       ├─ Try Gemini Nano (on-device AI)
///       │      │
///       │      └─ Not available? → fall through
///       │
///       └─ Template engine (always works)
/// ```
///
/// **Battery-aware:** Gemini Nano inference is skipped when AI is unavailable
/// — the template engine is zero-cost and always produces a humanised message.
///
/// **Portable:** This entire `ai/` folder can be extracted into any Flutter
/// project.  The only dependencies are [AIContext] data and the
/// platform channel in [GeminiNanoBridge].
class AIPromptEngine {
  /// Whether on-device AI (Gemini Nano) is available.
  ///
  /// Cached after first check — use [invalidateCache] to re-check.
  static bool _aiAvailable = false;
  static bool _initialized = false;

  /// Initialize the engine.  Call once during app startup.
  ///
  /// This is non-blocking and failure-safe — if Gemini Nano isn't
  /// available, the template engine is ready immediately.
  static Future<void> init() async {
    try {
      _aiAvailable = await GeminiNanoBridge.isSupported();
      if (_aiAvailable) {
        // Pre-warm the model in the background.  This is fire-and-forget
        // and won't block the UI thread.
        GeminiNanoBridge.warmUp();
        debugPrint('AIPromptEngine: Gemini Nano available — warming up');
      } else {
        debugPrint('AIPromptEngine: using template engine (no on-device AI)');
      }
    } catch (e) {
      debugPrint('AIPromptEngine: init error (safe): $e');
      _aiAvailable = false;
    }
    _initialized = true;
  }

  /// Whether on-device AI is available on this device.
  static bool get isAIAvailable => _aiAvailable;

  /// Whether the engine has been initialized.
  static bool get isInitialized => _initialized;

  /// Generate a humanised interception message for the Rising Tide gate.
  ///
  /// Returns an [AIMessage] containing the text and whether it was
  /// AI-generated or template-based.
  ///
  /// This method is designed to be **fast** — it checks cache first,
  /// then tries on-device AI, then falls back to templates.  The
  /// entire flow completes in <500ms even on slow devices.
  static Future<AIMessage> generateMessage({
    required String packageName,
    required String appName,
    required RisingTideStage stage,
  }) async {
    // Skip for Whisper stage — no interception needed.
    if (stage == RisingTideStage.whisper) {
      return const AIMessage(text: '', source: AIMessageSource.none);
    }

    final stageName = stage.name;

    // ── Step 1: Check cache ──────────────────────────────────────────
    final cached = AICacheService.getCachedMessage(
      packageName: packageName,
      stageName: stageName,
    );
    if (cached != null) {
      return AIMessage(text: cached, source: AIMessageSource.cached);
    }

    // ── Step 2: Build context ────────────────────────────────────────
    final ctx = await AIContextBuilder.build(
      packageName: packageName,
      appName: appName,
      stage: stage,
    );

    // ── Step 3: Try user-downloaded offline model (Gemma) ────────────
    final offlineEngine = OfflineAIEngine();
    if (offlineEngine.isModelReady) {
      try {
        final offlineResult = await offlineEngine.generateAnswer(
          ctx.toPromptMap(),
        );

        if (offlineResult != null && offlineResult.trim().isNotEmpty) {
          final cleaned = _cleanAIOutput(offlineResult);
          await AICacheService.cacheMessage(
            packageName: packageName,
            stageName: stageName,
            message: cleaned,
          );
          debugPrint('AIPromptEngine: Offline Gemma model generated message');
          return AIMessage(text: cleaned, source: AIMessageSource.ai);
        }
      } catch (e) {
        debugPrint('AIPromptEngine: Offline AI failed (falling back): $e');
      }
    }

    // ── Step 3b: Try Gemini Nano (AICore — Pixel-only) ───────────────
    if (_aiAvailable) {
      try {
        final prompt = _buildSystemPrompt(ctx);
        final aiResult = await GeminiNanoBridge.generateContent(prompt);

        if (aiResult != null && aiResult.trim().isNotEmpty) {
          final cleaned = _cleanAIOutput(aiResult);
          await AICacheService.cacheMessage(
            packageName: packageName,
            stageName: stageName,
            message: cleaned,
          );
          debugPrint('AIPromptEngine: Gemini Nano generated message');
          return AIMessage(text: cleaned, source: AIMessageSource.ai);
        }
      } catch (e) {
        debugPrint('AIPromptEngine: AI generation failed (falling back): $e');
      }
    }

    // ── Step 4: Template fallback ────────────────────────────────────
    final templateMsg = TemplateMessageEngine.generate(ctx);
    await AICacheService.cacheMessage(
      packageName: packageName,
      stageName: stageName,
      message: templateMsg,
    );
    return AIMessage(text: templateMsg, source: AIMessageSource.template);
  }

  /// Force re-check of AI availability (e.g. after system update).
  static void invalidateCache() {
    GeminiNanoBridge.invalidateCache();
    _aiAvailable = false;
    _initialized = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // System Prompt Construction
  // ─────────────────────────────────────────────────────────────────────────

  /// Build the complete prompt sent to Gemini Nano.
  ///
  /// The prompt is carefully crafted for:
  ///   - **Brevity:** Maximum 2 sentences — launcher must feel instant
  ///   - **Tone:** Calm inner voice, not lecturer
  ///   - **Data:** Uses actual user stats for authenticity
  ///   - **Battery:** Short prompt = faster inference = less battery
  static String _buildSystemPrompt(AIContext ctx) {
    final data = ctx.toPromptMap();
    final stageDesc = ctx.stage == RisingTideStage.dim
        ? 'halfway to their daily limit'
        : 'past their daily limit';

    return '''You are Kora, a calm inner voice inside someone's phone. You are not a lecturer, a parent, or a therapist. You are the user's own awareness, speaking gently.

Rules:
- Write EXACTLY 1-2 sentences. Be brief. Be human.
- Never say "I think you should" or "You need to". Never lecture.
- Use the user's actual data naturally (times, counts, intentions).
- Vary your tone: sometimes wry, sometimes warm, sometimes just factual.
- Reference their intention or task only if it creates a genuine contrast.
- Acknowledge that sometimes opening the app IS the right choice.
- Never guilt-trip. State facts. Ask a question. Let them decide.
- Do NOT use emojis, bullet points, or markdown.

Context for this moment:
- App: ${data['appName']}
- Stage: ${ctx.stage.name} ($stageDesc)
- Minutes used today: ${data['minutesToday']} of ${data['limitMinutes']} limit
- Opens today: ${data['opensToday']}
- Current time: ${data['currentTime']}
- Daily intention: ${data['dailyIntention']}
- Top pending task: ${data['topPendingTodo']}
- Pending tasks: ${data['pendingTodoCount']}, Completed: ${data['completedTodoCount']}
- Weekly resist rate: ${data['weeklyResistRate']}
- Avg session: ${data['avgSessionMinutes']} min
- Peak usage hour: ${data['peakOpenHour']}
- Is peak hour now: ${data['isPeakHour']}

Generate a single interception message.''';
  }

  /// Clean up AI output — strip quotes, extra newlines, etc.
  static String _cleanAIOutput(String raw) {
    var cleaned = raw.trim();

    // Remove surrounding quotes if present
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // Collapse multiple newlines into a single space
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), ' ');

    // Trim to max 200 chars (safety limit for UI)
    if (cleaned.length > 200) {
      cleaned = '${cleaned.substring(0, 197)}...';
    }

    return cleaned;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

/// Where the message came from.
enum AIMessageSource {
  /// On-device AI (Gemini Nano) generated this message.
  ai,

  /// Template engine generated this message.
  template,

  /// Message was retrieved from cache.
  cached,

  /// No message needed (Whisper stage).
  none,
}

/// A generated interception message with its source.
class AIMessage {
  final String text;
  final AIMessageSource source;

  const AIMessage({required this.text, required this.source});

  /// Whether this message was generated by on-device AI.
  bool get isAIGenerated => source == AIMessageSource.ai;

  /// Whether a message is available (non-empty).
  bool get hasMessage => text.isNotEmpty;
}
