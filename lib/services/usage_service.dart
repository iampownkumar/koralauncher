import 'dart:io';
import 'package:flutter/foundation.dart';
import 'native_service.dart';
import 'launcher_service.dart';

class KoraUsageInfo {
  final String packageName;
  final Duration usage;
  KoraUsageInfo({required this.packageName, required this.usage});
}

class UsageService {
  static List<KoraUsageInfo> _usageInfos = [];
  
  static List<KoraUsageInfo> get usageInfos => _usageInfos;

  static Future<void> refreshUsage() async {
    if (!Platform.isAndroid) return;
    
    try {
      bool hasPermission = await NativeService.hasUsagePermission();
      if (!hasPermission) return; 

      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      Map<String, int> rawStats = await NativeService.getRawUsageStats(
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      );
      
      List<KoraUsageInfo> infoList = [];
      rawStats.forEach((package, millis) {
        infoList.add(KoraUsageInfo(packageName: package, usage: Duration(milliseconds: millis)));
      });
      _usageInfos = infoList;
    } catch (exception, stackTrace) {
      debugPrint("UsageService Exception: $exception\n$stackTrace");
    }
  }

  static Duration getAppUsage(String packageName) {
    for (var info in _usageInfos) {
      if (info.packageName == packageName) {
        return info.usage;
      }
    }
    return Duration.zero;
  }

  static int _roundedMinutes(Duration duration) {
    // Round half-up to match typical "screen time" rounding in dashboards.
    // Digital Wellbeing usually rounds to the nearest minute (not floor).
    return (duration.inMilliseconds + 30000) ~/ 60000;
  }

  static const Set<String> _ignoredPackages = {
    'com.miui.home',
    'com.google.android.apps.nexuslauncher',
    'com.sec.android.app.launcher',
    'com.oppo.launcher',
    'com.huawei.android.launcher',
    'com.vivo.launcher',
    'com.transsion.XOSLauncher',
    'com.transsion.hilauncher',
    'com.google.android.apps.wellbeing', 
    'com.miui.securitycenter',
    'com.android.systemui',
    'com.google.android.googlequicksearchbox',
    'com.google.android.gms',
    'com.android.providers.media.module',
  };

  static bool shouldCountPackage(String packageName) {
    if (packageName.contains('koralauncher')) return false;
    return !_ignoredPackages.contains(packageName);
  }

  static Duration getVisibleTotalUsage({int minRoundedMinutes = 1}) {
    int totalMinutes = 0;
    for (final app in LauncherService.cachedApps) {
      if (!shouldCountPackage(app.packageName)) continue;

      final usageMs = getAppUsage(app.packageName).inMilliseconds;
      final roundedMinutes = (usageMs + 30000) ~/ 60000; // round half-up
      if (roundedMinutes >= minRoundedMinutes) {
        totalMinutes += roundedMinutes;
      }
    }
    return Duration(minutes: totalMinutes);
  }

  static Duration getTotalUsage() {
    Duration total = Duration.zero;
    final cachedPackages = LauncherService.cachedApps.map((a) => a.packageName).toSet();
    final Map<String, Duration> uniqueUsage = {};

    for (var info in _usageInfos) {
      if (cachedPackages.contains(info.packageName) && 
          !info.packageName.contains('koralauncher') &&
          !_ignoredPackages.contains(info.packageName)) {
        
        // Handle overlapping daily buckets bug in app_usage by taking the maximum payload
        if (!uniqueUsage.containsKey(info.packageName) || info.usage > uniqueUsage[info.packageName]!) {
            uniqueUsage[info.packageName] = info.usage;
        }
      }
    }
    
    uniqueUsage.forEach((_, duration) {
       total += duration;
    });

    return total;
  }

  static String formatDuration(Duration duration) {
    final totalMinutes = _roundedMinutes(duration);
    if (totalMinutes <= 0) return "0m";

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}
