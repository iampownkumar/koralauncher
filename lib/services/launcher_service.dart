import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/platform_type.dart';
import '../models/app_entry.dart';
import 'native_service.dart';
import 'rising_tide_service.dart';

class LauncherService {
  static List<AppInfo> _cachedApps = [];
  static List<AppEntry> _cachedEntries = [];
  static bool _isInitialized = false;

  static List<AppInfo> get cachedApps => _cachedApps;

  /// Merged list of real installed apps + pinned shortcuts (browser desktop
  /// shortcuts, etc.). Use this for the app drawer display.
  static List<AppEntry> get cachedEntries => _cachedEntries;

  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    await refreshApps();
    _isInitialized = true;
  }

  static Future<void> refreshApps() async {
    // ── 1. Real installed apps via native PackageManager query ──────────────
    // Uses ACTION_MAIN + CATEGORY_LAUNCHER — same as AOSP launchers.
    // Catches WebAPKs and anything with a launcher icon.
    final rawApps = await NativeService.queryLauncherApps();

    if (rawApps.isEmpty) {
      // Fallback to installed_apps plugin on very old APIs or errors
      debugPrint('LauncherService: native query empty, falling back to plugin');
      final fallback = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );
      _cachedApps = fallback
          .where((app) =>
              app.packageName != 'org.korelium.koralauncher' &&
              app.packageName != 'com.koralauncher.app')
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      _cachedApps = rawApps.map((raw) {
        final iconRaw = raw['icon'];
        final Uint8List? iconBytes = iconRaw != null
            ? Uint8List.fromList(List<int>.from(iconRaw as List))
            : null;
        return AppInfo(
          name: raw['name'] as String? ?? raw['packageName'] as String,
          packageName: raw['packageName'] as String,
          icon: iconBytes,
          versionName: '',
          versionCode: 0,
          platformType: PlatformType.nativeOrOthers,
          installedTimestamp: 0,
          isSystemApp: false,
          isLaunchableApp: true,
          category: AppCategory.undefined,
        );
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    // ── 2. Pinned shortcuts (browser "Add to Home Screen") ──────────────────
    // These are NOT installed apps — they're intents stored by ShortcutReceiver.
    final rawShortcuts = await NativeService.getStoredShortcuts();
    final shortcuts = rawShortcuts.map((raw) {
      final iconRaw = raw['icon'];
      final Uint8List? iconBytes = iconRaw != null
          ? Uint8List.fromList(List<int>.from(iconRaw as List))
          : null;
      final id = raw['id'] as String? ?? '';
      return AppEntry(
        name: raw['name'] as String? ?? 'Shortcut',
        packageName: 'shortcut_$id',
        icon: iconBytes,
        isShortcut: true,
        intentUri: raw['intentUri'] as String?,
        targetPackage: raw['targetPackage'] as String?,
        shortcutId: raw['shortcutId'] as String? ?? id,
      );
    }).toList();

    // ── 3. Merge: apps + shortcuts, sorted alphabetically ───────────────────
    final appEntries = _cachedApps.map((app) => AppEntry(
          name: app.name,
          packageName: app.packageName,
          icon: app.icon,
        ));

    _cachedEntries = [...appEntries, ...shortcuts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static Future<void> launchApp(String packageName) async {
    // Intentional launch from Launcher UI always bypasses the 5-min grace period
    await RisingTideService.clearReopenLock(packageName);
    await InstalledApps.startApp(packageName);
  }
}
