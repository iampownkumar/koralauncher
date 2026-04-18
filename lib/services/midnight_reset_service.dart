import 'storage_service.dart';
import 'rising_tide_service.dart';
import 'usage_service.dart';

class MidnightResetService {
  static Future<void> checkAndReset() async {
    final now = DateTime.now();
    final lastResetStr = StorageService.getString('last_midnight_reset');
    final today = _dayKey(now);

    if (lastResetStr != today) {
      await _performReset();
      await StorageService.setString('last_midnight_reset', today);
    }
  }

  static Future<void> _performReset() async {
    // 1. Clear daily intention
    await StorageService.setDailyIntention(null);
    RisingTideService.invalidateIntentionCache();

    // 2. Rising Tide stats for all apps will naturally reset because 
    // UsageService and StorageService use date-based keys.
    // But we should explicitly clear any active Stage 2 reopen locks.
    final allKeys = StorageService.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('rt_lock_')) {
        await StorageService.remove(key);
      }
    }
    
    await UsageService.refreshUsage();
    await RisingTideService.syncInterceptionState();
  }

  static String _dayKey(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
}
