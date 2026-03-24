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
}
