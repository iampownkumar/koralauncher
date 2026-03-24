import 'package:app_usage/app_usage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'native_service.dart';
import 'launcher_service.dart';

class UsageService {
  static List<AppUsageInfo> _usageInfos = [];
  
  static List<AppUsageInfo> get usageInfos => _usageInfos;

  static Future<void> refreshUsage() async {
    if (!Platform.isAndroid) return;
    
    try {
      bool hasPermission = await NativeService.hasUsagePermission();
      if (!hasPermission) return; // Fail gracefully without triggering OS prompt

      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startDate, endDate);
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

  static Duration getTotalUsage() {
    Duration total = Duration.zero;
    final cachedPackages = LauncherService.cachedApps.map((a) => a.packageName).toSet();

    for (var info in _usageInfos) {
      // Exclude system apps not in launcher, and exclude the launcher itself
      if (cachedPackages.contains(info.packageName) && 
          !info.packageName.contains('koralauncher')) {
        total += info.usage;
      }
    }
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
