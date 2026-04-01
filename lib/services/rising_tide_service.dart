import '../models/rising_tide_stage.dart';
import 'usage_service.dart';
import 'storage_service.dart';
import 'native_service.dart';
import 'app_lock_manager.dart';
import 'rising_tide_logger.dart';

class RisingTideService {
  static String? _cachedIntention;
  static DateTime? _lastIntentionFetch;

  /// Calculates the current Rising Tide stage for a given package.
  static RisingTideStage getStage(String packageName) {
    if (!StorageService.isRisingTideMasterEnabled()) {
      return RisingTideStage.whisper;
    }

    // Check if the user has an active 5-minute task unlock
    if (AppLockManager.hasActiveUnlock(packageName)) {
      return RisingTideStage.whisper;
    }

    if (!StorageService.isAppFlagged(packageName)) {
      return RisingTideStage.whisper;
    }

    final usageMinutes = UsageService.getRoundedMinutesToday(packageName);
    final limit = _getAppDailyLimit(packageName);
    final limitMin = limit.inMinutes;
    if (limitMin <= 0) {
      return RisingTideStage.whisper;
    }
    final usagePercent = usageMinutes / limitMin;
    final overrides = _getTodayOverrideCount(packageName);

    RisingTideStage stage;
    if (usagePercent >= 2.0 || overrides >= 3) {
      stage = RisingTideStage.silence;
    } else if (usagePercent >= 1.0 || overrides >= 2) {
      stage = RisingTideStage.mirror;
    } else if (usagePercent >= 0.5) {
      stage = RisingTideStage.dim;
    } else {
      stage = RisingTideStage.whisper;
    }

    // Reopen lock (readme): force the same gate again (Stage 2 or 3), not an upgrade to mirror.
    if (isPackageLocked(packageName)) {
      if (stage == RisingTideStage.silence) {
        return RisingTideStage.silence;
      }
      if (stage == RisingTideStage.whisper) {
        return RisingTideStage.dim;
      }
      return stage;
    }

    return stage;
  }

  /// Synchronizes the list of apps that need interception with the native Accessibility service.
  static Future<void> syncInterceptionState() async {
    if (!StorageService.isRisingTideMasterEnabled()) {
      await NativeService.sendBlockedApps([]);
      return;
    }

    // Only send apps to the native watcher that are currently in a blocking stage (Dim, Mirror, Silence).
    // This prevents the native service from "stealing focus" (bringing Kora to front) for apps
    // that should be allowed to open directly in the Whisper stage.
    final allFlagged = StorageService.getFlaggedApps();
    final List<String> toBlock = [];

    for (final pkg in allFlagged) {
      if (getStage(pkg) != RisingTideStage.whisper) {
        toBlock.add(pkg);
      }
    }

    await NativeService.sendBlockedApps(toBlock);
  }

  /// Today's opens (gate visits + whisper launches) and minutes (usage stats, same source as [getStage]).
  static Future<Map<String, int>> getStats(String packageName) async {
    await UsageService.refreshUsage();
    return {
      'opens': StorageService.getTodayOpenCount(packageName),
      'minutes': UsageService.getRoundedMinutesToday(packageName),
    };
  }

  static Duration _getAppDailyLimit(String packageName) {
    final m = StorageService.getAppDailyLimitMinutes(packageName);
    return Duration(minutes: m);
  }

  /// Returns how many times the user has chosen to "Continue" today for this app.
  static int _getTodayOverrideCount(String packageName) {
    final today = _localDayKey(DateTime.now());
    final key = 'rt_overrides_${today}_$packageName';
    return int.tryParse(StorageService.getString(key) ?? '0') ?? 0;
  }

  static Duration getAppDailyLimit(String packageName) {
    return _getAppDailyLimit(packageName);
  }

  static void invalidateIntentionCache() {
    _cachedIntention = null;
    _lastIntentionFetch = null;
  }

  static Future<void> recordOverride(String packageName) async {
    final count = _getTodayOverrideCount(packageName);
    final today = _localDayKey(DateTime.now());
    final key = 'rt_overrides_${today}_$packageName';
    await StorageService.setString(key, (count + 1).toString());
    
    // Sync state immediately to native
    await syncInterceptionState();
  }

  static String _localDayKey(DateTime now) {
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // --- Reopen Lock Logic (Stage 2 Lock) ---

  static const String _lockKeyPrefix = 'rt_lock_';

  /// Sets a 5-minute lock for Stage 2/3 interceptions.
  /// If the user reopens the app within this window, they are forced back to the interception screen.
  static Future<void> setReopenLock(String packageName) async {
    final expiry = DateTime.now().add(const Duration(minutes: 5));
    await StorageService.setString(_lockKeyPrefix + packageName, expiry.toIso8601String());
    await RisingTideLogger.logReopenLockApplied(packageName);
  }

  /// Returns the remaining duration of the lock, or Duration.zero if not locked.
  static Duration getRemainingLockDuration(String packageName) {
    final lockStr = StorageService.getString(_lockKeyPrefix + packageName);
    if (lockStr == null) return Duration.zero;

    try {
      final expiry = DateTime.parse(lockStr);
      final remaining = expiry.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return Duration.zero;
    }
  }

  /// Checks if a package is currently under a reopen lock.
  static bool isPackageLocked(String packageName) {
    final lockStr = StorageService.getString(_lockKeyPrefix + packageName);
    if (lockStr == null) return false;

    try {
      final expiry = DateTime.parse(lockStr);
      if (DateTime.now().isBefore(expiry)) {
        return true;
      } else {
        // Lock expired, clean up
        StorageService.remove(_lockKeyPrefix + packageName);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Clears the lock when the user finishes a mindful flow.
  static Future<void> clearReopenLock(String packageName) async {
    await StorageService.remove(_lockKeyPrefix + packageName);
    await RisingTideLogger.logReopenLockCleared(packageName);
  }

  /// Gets the cached intention or fetches it from storage.
  static String? getDailyIntention() {
    final now = DateTime.now();
    if (_cachedIntention != null && 
        _lastIntentionFetch != null && 
        _lastIntentionFetch!.day == now.day) {
      return _cachedIntention;
    }
    _cachedIntention = StorageService.getDailyIntention();
    _lastIntentionFetch = now;
    return _cachedIntention;
  }
}
