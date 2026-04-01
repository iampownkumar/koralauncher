import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rising_tide_service.dart';

class StorageService {
  static const String _flaggedAppsKey = 'flagged_apps';
  static const String _risingTideMasterKey = 'rising_tide_master_enabled';
  static const int _defaultDailyLimitMinutes = 10;
  static const String _appLimitPrefix = 'rt_limit_minutes_';
  static const String _todayOpensPrefix = 'rt_opens_';
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

    // Sync state to native Accessibility service
    await RisingTideService.syncInterceptionState();
  }

  static bool isAppFlagged(String packageName) {
    return getFlaggedApps().contains(packageName);
  }

  /// Master switch: when false, Rising Tide gates are off for every app.
  static bool isRisingTideMasterEnabled() {
    return _prefs.getBool(_risingTideMasterKey) ?? true;
  }

  static Future<void> setRisingTideMasterEnabled(bool enabled) async {
    await _prefs.setBool(_risingTideMasterKey, enabled);
    debugPrint("RisingTide: Master toggle set to $enabled");
    await RisingTideService.syncInterceptionState();
  }

  // --- Per-app daily time limit (Rising Tide) ---

  static int getAppDailyLimitMinutes(String packageName) {
    return _prefs.getInt('$_appLimitPrefix$packageName') ??
        _defaultDailyLimitMinutes;
  }

  static Future<void> setAppDailyLimitMinutes(
    String packageName,
    int minutes,
  ) async {
    final m = minutes.clamp(1, 24 * 60);
    await _prefs.setInt('$_appLimitPrefix$packageName', m);
  }

  // --- Opens today (gate visits + whisper launches) ---

  static String _todayOpensKey(String packageName) {
    return '$_todayOpensPrefix${_localDayKey(DateTime.now())}_$packageName';
  }

  static int getTodayOpenCount(String packageName) {
    return _prefs.getInt(_todayOpensKey(packageName)) ?? 0;
  }

  static Future<void> incrementTodayOpenCount(String packageName) async {
    final key = _todayOpensKey(packageName);
    final next = (_prefs.getInt(key) ?? 0) + 1;
    await _prefs.setInt(key, next);
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

  static String? getString(String key) => _prefs.getString(key);

  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // --- Onboarding ---
  static bool hasCompletedOnboarding() {
    return _prefs.getBool('has_completed_onboarding') ?? false;
  }

  static Future<void> completeOnboarding() async {
    await _prefs.setBool('has_completed_onboarding', true);
  }
}
