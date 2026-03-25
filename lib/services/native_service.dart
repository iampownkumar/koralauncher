import 'package:flutter/services.dart';

class NativeService {
static const platform = MethodChannel('com.koralauncher.app/native');
  static Future<bool> isDefaultLauncher() async {
    try {
      final bool result = await platform.invokeMethod('isDefaultLauncher');
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod('hasUsagePermission');
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await platform.invokeMethod('openUsageSettings');
    } catch (e) {
      print("Failed to open usage settings.");
    }
  }

  static Future<void> openDefaultLauncherSettings() async {
    try {
      await platform.invokeMethod('openDefaultLauncherSettings');
    } catch (e) {
      print("Failed: $e");
    }
  }

  static Future<Map<String, int>> getRawUsageStats(int startTime, int endTime) async {
    try {
      final Map<dynamic, dynamic>? result = await platform.invokeMethod('getRawUsageStats', {
        'startTime': startTime,
        'endTime': endTime,
      });
      if (result == null) return {};
      return result.map((key, value) => MapEntry(key.toString(), int.parse(value.toString())));
    } catch (e) {
      return {};
    }
  }
}
