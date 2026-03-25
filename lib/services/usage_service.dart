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
    if (duration == Duration.zero) return "0m";
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }
}
