import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class LauncherService {
  static List<AppInfo> _cachedApps = [];
  static bool _isInitialized = false;

  // We want some system apps to remain visible (e.g. Settings) but we don't want
  // *all* system packages included in usage totals, since Digital Wellbeing
  // typically focuses on user apps.
  static const Set<String> _alwaysIncludeSystemPackages = {
    'com.android.settings',
    // Let the user search/launch Digital Wellbeing if they want,
    // but we exclude it from usage summaries via `UsageService._ignoredPackages`.
    'com.google.android.apps.wellbeing',
  };

  static List<AppInfo> get cachedApps => _cachedApps;
  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    await refreshApps();
    _isInitialized = true;
  }

  static Future<void> refreshApps() async {
    // Base list (matches Digital Wellbeing closer): no system apps.
    final appsUserOnly = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      withIcon: true,
    );

    // Grab system apps too so we can selectively include a few.
    final appsAll = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );

    final byPackage = <String, AppInfo>{};
    for (final app in appsUserOnly) {
      byPackage[app.packageName] = app;
    }

    for (final sysPkg in _alwaysIncludeSystemPackages) {
      final match = appsAll.where((a) => a.packageName == sysPkg).toList();
      if (match.isNotEmpty) {
        byPackage[sysPkg] = match.first;
      }
    }

    final merged = byPackage.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cachedApps = merged;
  }

  static Future<void> launchApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }
}
