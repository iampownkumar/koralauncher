import '../database/database_provider.dart';
import '../models/rising_tide_stage.dart';

class RisingTideLogger {
  /// Logs a Rising Tide event to the database.
  static Future<void> logTideEvent({
    String? packageName,
    required String eventType,
    String? detail,
    RisingTideStage? stage,
  }) async {
    await db.logTideEvent(
      packageName: packageName,
      eventType: eventType,
      detail: detail,
      stage: stage?.index,
    );
  }

  // Helper methods for common events

  static Future<void> logIntentionSet(String intention) async {
    await logTideEvent(
      eventType: 'intention_set',
      detail: intention,
    );
  }

  static Future<void> logAppOpen(String packageName, RisingTideStage stage) async {
    await logTideEvent(
      packageName: packageName,
      eventType: 'app_open_stage${stage.index + 1}',
      stage: stage,
    );
  }

  static Future<void> logDecision(String packageName, String decision, String mood) async {
    await logTideEvent(
      packageName: packageName,
      eventType: 'decision_$decision',
      detail: 'mood:$mood',
    );
  }
}
