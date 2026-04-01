import 'package:shared_preferences/shared_preferences.dart';

class AppLockManager {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _localDayKey(DateTime now) {
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Grants a temporary unlock for a package
  static Future<void> grantUnlock(String packageName, {required int minutes}) async {
    final today = _localDayKey(DateTime.now());
    final key = 'task_unlock_${packageName}_$today';
    final unlockUntil = DateTime.now().add(Duration(minutes: minutes)).millisecondsSinceEpoch;
    
    await _prefs.setInt(key, unlockUntil);
    // Also mark that an unlock was used today so it can't be used again
    await _prefs.setBool('${key}_used', true);
  }

  /// Checks if a temporary unlock is currently active
  static bool hasActiveUnlock(String packageName) {
    final today = _localDayKey(DateTime.now());
    final key = 'task_unlock_${packageName}_$today';
    final unlockUntil = _prefs.getInt(key);
    
    if (unlockUntil != null && DateTime.now().millisecondsSinceEpoch < unlockUntil) {
      return true;
    }
    return false;
  }

  /// Checks if the user has already used their one unlock for today
  static bool hasUsedUnlockToday(String packageName) {
    final today = _localDayKey(DateTime.now());
    final key = 'task_unlock_${packageName}_$today';
    return _prefs.getBool('${key}_used') ?? false;
  }
}
