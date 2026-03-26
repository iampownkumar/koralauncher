import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class LauncherService {
  static List<AppInfo> _cachedApps = [];
  static bool _isInitialized = false;


  static List<AppInfo> get cachedApps => _cachedApps;
  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    await refreshApps();
    _isInitialized = true;
  }

  static Future<void> refreshApps() async {
    // Get all apps that have a launch intent
    final appsAll = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );

    final byPackage = <String, AppInfo>{};
    for (final app in appsAll) {
      // Exclude our own launcher
      if (app.packageName != 'org.korelium.koralauncher' && 
          app.packageName != 'com.koralauncher.app') {
        byPackage[app.packageName] = app;
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
