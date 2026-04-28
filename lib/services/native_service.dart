import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';

import '../app_navigator.dart';
import '../models/rising_tide_stage.dart';
import '../screens/interception_screen.dart';
import 'foreground_intercept_guard.dart';
import 'launcher_service.dart';
import 'rising_tide_service.dart';
import 'storage_service.dart';
import 'usage_service.dart';

class NativeService {
  static const platform = MethodChannel('com.koralauncher.app/native');

  static const String _launcherPackage = 'org.korelium.koralauncher';

  /// Handles [MethodCall]s from Android (e.g. [AccessibilityWatcherService]).
  static void initMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onAppForeground') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final packageName = args?['package'] as String?;
        if (packageName != null) {
          await _onForegroundApp(packageName);
        }
      } else if (call.method == 'onPackageChanged') {
        await LauncherService.refreshApps();
      } else if (call.method == 'onHomePressed') {
        final nav = navigatorKey.currentState;
        if (nav != null) {
          // Close any open drawers/screens and go back to home
          nav.popUntil((route) => route.isFirst);
        }
      }
    });
  }

  static String? _lastInterceptPackage;
  static DateTime? _lastInterceptAt;

  static Future<void> _onForegroundApp(String packageName) async {
    if (packageName == _launcherPackage) return;
    if (!StorageService.isAppFlagged(packageName)) return;
    if (ForegroundInterceptGuard.shouldSkipForPackage(packageName)) return;

    await UsageService.refreshUsage();

    // Compute real-time usage percentage and force the controller
    // into the correct stage.  The 30-second poll stream may not
    // have fired yet, so we do a synchronous check here.
    final used = UsageService.getRoundedMinutesToday(packageName);
    final limit = StorageService.getAppDailyLimitMinutes(packageName);
    final percent = limit <= 0 ? 0.0 : used / limit;

    final controller = RisingTideService().controllerFor(packageName);
    if (percent >= 1.0 && controller.currentStage.index < RisingTideStage.mirror.index) {
      await controller.advanceToStage(RisingTideStage.mirror);
    } else if (percent >= 0.5 && controller.currentStage == RisingTideStage.whisper) {
      await controller.advanceToStage(RisingTideStage.dim);
    }

    final stage = controller.currentStage;
    debugPrint('RisingTide: $packageName  used=${used}m  limit=${limit}m  pct=${(percent * 100).toStringAsFixed(0)}%  stage=${stage.name}');
    if (stage == RisingTideStage.whisper) return;

    final now = DateTime.now();
    if (_lastInterceptPackage == packageName &&
        _lastInterceptAt != null &&
        now.difference(_lastInterceptAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInterceptPackage = packageName;
    _lastInterceptAt = now;

    final app = await _findAppInfo(packageName);
    if (app == null) return;

    // Let MainActivity come to front before pushing (started from accessibility).
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (!nav.mounted) return;

    await nav.push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InterceptionScreen(app: app),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  static Future<AppInfo?> _findAppInfo(String packageName) async {
    for (final a in LauncherService.cachedApps) {
      if (a.packageName == packageName) return a;
    }
    await LauncherService.refreshApps();
    for (final a in LauncherService.cachedApps) {
      if (a.packageName == packageName) return a;
    }
    return null;
  }

  static Future<bool> isDefaultLauncher() async {
    try {
      final bool result = await platform.invokeMethod<bool>('isDefaultLauncher') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod<bool>('hasUsagePermission') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasAccessibilityPermission() async {
    try {
      final bool result = await platform.invokeMethod<bool>('hasAccessibilityPermission') ?? false;
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

  static Future<void> openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print("Failed: $e");
    }
  }

  static Future<void> lockScreen() async {
    try {
      await platform.invokeMethod('lockScreen');
    } catch (e) {
      print("Failed to lock screen: $e");
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

  /// Queries all launchable apps via [PackageManager.queryIntentActivities]
  /// (ACTION_MAIN + CATEGORY_LAUNCHER). This is identical to how AOSP
  /// launchers enumerate apps and correctly includes WebAPKs / browser
  /// desktop shortcuts that the [installed_apps] plugin misses.
  ///
  /// Returns a list of maps with keys: `packageName`, `name`, `icon` (Uint8List?).
  static Future<List<Map<String, dynamic>>> queryLauncherApps() async {
    try {
      final raw = await platform.invokeMethod<List<dynamic>>('queryLauncherApps');
      if (raw == null) return [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('NativeService.queryLauncherApps error: $e');
      return [];
    }
  }

  static Future<void> sendBlockedApps(List<String> packages) async {
    try {
      await platform.invokeMethod('sendBlockedApps', {'packages': packages});
    } catch (e) {
      print("NativeService Error: $e");
    }
  }

  /// Returns all pinned shortcuts stored by [ShortcutReceiver] / pin request handler.
  /// Each map has: id, name, intentUri, icon (Uint8List?), isShortcut (true).
  static Future<List<Map<String, dynamic>>> getStoredShortcuts() async {
    try {
      final raw = await platform.invokeMethod<List<dynamic>>('getStoredShortcuts');
      if (raw == null) return [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('NativeService.getStoredShortcuts error: $e');
      return [];
    }
  }

  /// Launches a pinned shortcut via its stored intent URI or modern shortcut ID.
  static Future<void> launchShortcut({String? intentUri, String? targetPackage, String? shortcutId}) async {
    try {
      // Intentional launch from Launcher UI always bypasses the 5-min grace period
      if (targetPackage != null) {
        await RisingTideService.clearReopenLock(targetPackage);
      }
      
      await platform.invokeMethod('launchShortcut', {
        'intentUri': intentUri,
        'targetPackage': targetPackage,
        'shortcutId': shortcutId,
      });
    } catch (e) {
      debugPrint('NativeService.launchShortcut error: $e');
    }
  }

  /// Removes a pinned shortcut from the store by its ID.
  static Future<void> removeShortcut(String id) async {
    try {
      await platform.invokeMethod('removeShortcut', {'id': id});
    } catch (e) {
      debugPrint('NativeService.removeShortcut error: $e');
    }
  }

  static Future<bool> setSystemWallpaper(Uint8List bytes) async {
    try {
      final success = await platform.invokeMethod<bool>('setSystemWallpaper', {'bytes': bytes});
      return success ?? false;
    } catch (e) {
      debugPrint("Failed to set system wallpaper: $e");
      return false;
    }
  }
}
