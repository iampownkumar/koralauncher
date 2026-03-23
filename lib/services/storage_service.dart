import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _flaggedAppsKey = 'flagged_apps';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static List<String> getFlaggedApps() {
    return _prefs.getStringList(_flaggedAppsKey) ?? [];
  }

  static Future<void> toggleFlaggedApp(String packageName) async {
    final apps = getFlaggedApps().toList();
    if (apps.contains(packageName)) {
      apps.remove(packageName);
    } else {
      apps.add(packageName);
    }
    await _prefs.setStringList(_flaggedAppsKey, apps);
  }

  static bool isAppFlagged(String packageName) {
    return getFlaggedApps().contains(packageName);
  }

  static Future<void> logDecision(String packageName, bool didOpen) async {
    final key = 'decision_$packageName';
    final currentLogs = _prefs.getStringList(key) ?? [];
    currentLogs.add('${DateTime.now().toIso8601String()}|$didOpen');
    await _prefs.setStringList(key, currentLogs);
  }

  static String? getDailyIntention() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _prefs.getString('intention_$today');
  }

  static Future<void> setDailyIntention(String intention) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _prefs.setString('intention_$today', intention);
  }

  static bool hasSetIntentionToday() {
    return getDailyIntention() != null;
  }

  static bool isMinimalMode() {
    return _prefs.getBool('minimal_mode') ?? false;
  }

  static Future<void> setMinimalMode(bool value) async {
    await _prefs.setBool('minimal_mode', value);
  }
}

