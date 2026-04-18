import '../database/database_provider.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../services/todo_service.dart';
import '../models/rising_tide_stage.dart';

/// Portable AI context builder.
///
/// Collects all behavioural data the AI model needs to craft a humanised
/// interception message.  This class owns *zero* AI logic — it only gathers
/// facts.  Any AI provider (Gemini Nano, llama.cpp, cloud, or template
/// engine) can consume the [AIContext] it produces.
class AIContextBuilder {
  /// Build a full snapshot of the user's current behavioural state for a
  /// given [packageName] at the current moment.
  static Future<AIContext> build({
    required String packageName,
    required String appName,
    required RisingTideStage stage,
  }) async {
    // ── Real-time stats ────────────────────────────────────────────
    final usageMinutes = UsageService.getRoundedMinutesToday(packageName);
    final limitMinutes = StorageService.getAppDailyLimitMinutes(packageName);
    final opensToday = StorageService.getTodayOpenCount(packageName);

    // ── Daily intention & todos ─────────────────────────────────────
    final intention = StorageService.getDailyIntention();
    final pendingTodos = TodoService.todos
        .where((t) => !t.isCompleted)
        .toList();
    final completedTodos = TodoService.todos
        .where((t) => t.isCompleted)
        .toList();
    final topTodo = pendingTodos.isNotEmpty ? pendingTodos.first.title : null;

    // ── Historical context (30-day window) ─────────────────────────
    Map<String, dynamic> aiContext = {};
    try {
      aiContext = await db.buildAIContext(packageName);
    } catch (_) {
      // If DB query fails, we proceed with real-time data only.
    }

    // ── Time of day awareness ──────────────────────────────────────
    final now = DateTime.now();
    final timeOfDay = _classifyTimeOfDay(now.hour);

    return AIContext(
      packageName: packageName,
      appName: appName,
      stage: stage,
      minutesToday: usageMinutes,
      limitMinutes: limitMinutes,
      opensToday: opensToday,
      dailyIntention: intention,
      topPendingTodo: topTodo,
      pendingTodoCount: pendingTodos.length,
      completedTodoCount: completedTodos.length,
      weeklyResistRate: (aiContext['weeklyResistRate'] as double?) ?? 0.0,
      avgSessionSeconds: (aiContext['avgSessionSeconds'] as num?)?.toInt() ?? 0,
      totalSessionsLast30Days:
          (aiContext['totalSessionsLast30Days'] as int?) ?? 0,
      peakOpenHour: (aiContext['peakOpenHour'] as int?) ?? -1,
      timeOfDay: timeOfDay,
      hour: now.hour,
      minute: now.minute,
    );
  }

  static TimeOfDay _classifyTimeOfDay(int hour) {
    if (hour < 6) return TimeOfDay.lateNight;
    if (hour < 12) return TimeOfDay.morning;
    if (hour < 17) return TimeOfDay.afternoon;
    if (hour < 21) return TimeOfDay.evening;
    return TimeOfDay.lateNight;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

/// Time-of-day classification for tone variation.
enum TimeOfDay { morning, afternoon, evening, lateNight }

/// Immutable snapshot of everything the AI needs to craft a message.
///
/// This class is intentionally serialisable and transport-friendly so it
/// can be passed to any AI provider — local, remote, or template-based.
class AIContext {
  final String packageName;
  final String appName;
  final RisingTideStage stage;

  // Real-time usage
  final int minutesToday;
  final int limitMinutes;
  final int opensToday;

  // Intention & tasks
  final String? dailyIntention;
  final String? topPendingTodo;
  final int pendingTodoCount;
  final int completedTodoCount;

  // Historical (30-day)
  final double weeklyResistRate;
  final int avgSessionSeconds;
  final int totalSessionsLast30Days;
  final int peakOpenHour;

  // Temporal
  final TimeOfDay timeOfDay;
  final int hour;
  final int minute;

  const AIContext({
    required this.packageName,
    required this.appName,
    required this.stage,
    required this.minutesToday,
    required this.limitMinutes,
    required this.opensToday,
    this.dailyIntention,
    this.topPendingTodo,
    required this.pendingTodoCount,
    required this.completedTodoCount,
    required this.weeklyResistRate,
    required this.avgSessionSeconds,
    required this.totalSessionsLast30Days,
    required this.peakOpenHour,
    required this.timeOfDay,
    required this.hour,
    required this.minute,
  });

  /// Percentage of daily limit consumed.
  double get usagePercent =>
      limitMinutes > 0 ? (minutesToday / limitMinutes) : 0.0;

  /// Remaining minutes until limit.
  int get remainingMinutes => (limitMinutes - minutesToday).clamp(0, limitMinutes);

  /// Whether the user has set an intention today.
  bool get hasIntention =>
      dailyIntention != null && dailyIntention!.trim().isNotEmpty;

  /// Whether the user has pending todos.
  bool get hasPendingTodos => pendingTodoCount > 0;

  /// Whether this is the user's peak usage hour (historically).
  bool get isPeakHour => peakOpenHour >= 0 && hour == peakOpenHour;

  /// Formatted time string (e.g. "2:14 PM").
  String get formattedTime {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final amPm = hour >= 12 ? 'PM' : 'AM';
    return '$h:${minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Converts to a Map suitable for passing to an AI prompt.
  Map<String, dynamic> toPromptMap() => {
        'appName': appName,
        'stage': stage.name,
        'minutesToday': minutesToday,
        'limitMinutes': limitMinutes,
        'opensToday': opensToday,
        'remainingMinutes': remainingMinutes,
        'usagePercent': '${(usagePercent * 100).round()}%',
        'dailyIntention': dailyIntention ?? 'not set',
        'topPendingTodo': topPendingTodo ?? 'none',
        'pendingTodoCount': pendingTodoCount,
        'completedTodoCount': completedTodoCount,
        'weeklyResistRate': '${(weeklyResistRate * 100).round()}%',
        'avgSessionMinutes': (avgSessionSeconds / 60).round(),
        'totalSessionsLast30Days': totalSessionsLast30Days,
        'peakOpenHour': peakOpenHour >= 0 ? _formatHour(peakOpenHour) : 'unknown',
        'isPeakHour': isPeakHour,
        'timeOfDay': timeOfDay.name,
        'currentTime': formattedTime,
      };

  static String _formatHour(int h) {
    final hr = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final amPm = h >= 12 ? 'PM' : 'AM';
    return '$hr $amPm';
  }
}
