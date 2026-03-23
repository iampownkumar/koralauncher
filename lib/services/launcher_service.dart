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
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );
    // Sort alphabetically
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cachedApps = apps;
  }

  static Future<void> launchApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }
}
