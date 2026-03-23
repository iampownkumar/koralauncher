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
    final apps = getFlaggedApps();
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
}

