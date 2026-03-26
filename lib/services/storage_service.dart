import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _flaggedAppsKey = 'flagged_apps';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _localDayKey(DateTime now) {
    // Digital Wellbeing uses device local time for day boundaries.
    // Avoid UTC date strings from `toIso8601String()`, which can shift the day.
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  static String? getDailyIntention() {
    final today = _localDayKey(DateTime.now());
    return _prefs.getString('intention_$today');
  }

  static Future<void> setDailyIntention(String intention) async {
    final today = _localDayKey(DateTime.now());
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

  static List<String> getTodos() {
    final today = _localDayKey(DateTime.now());
    return _prefs.getStringList('todo_list_$today') ?? ['', '', '', ''];
  }

  static Future<void> setTodos(List<String> todos) async {
    final today = _localDayKey(DateTime.now());
    await _prefs.setStringList('todo_list_$today', todos);
  }

  static List<String> getTodoStates() {
    final today = _localDayKey(DateTime.now());
    return _prefs.getStringList('todo_states_$today') ?? ['false', 'false', 'false', 'false'];
  }

  static Future<void> setTodoStates(List<String> states) async {
    final today = _localDayKey(DateTime.now());
    await _prefs.setStringList('todo_states_$today', states);
  }
}

