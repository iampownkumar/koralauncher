import 'package:flutter/foundation.dart';
import '../services/rising_tide_controller.dart';
import '../models/rising_tide_stage.dart';
import 'usage_service.dart';
import 'storage_service.dart';
import 'native_service.dart';
import 'rising_tide_logger.dart';

class RisingTideService {
  static final RisingTideService _instance = RisingTideService._internal();
  RisingTideService._internal();

  factory RisingTideService() => _instance;

  static String? _cachedIntention;
  static DateTime? _lastIntentionFetch;

  // Map of package -> controller
  final Map<String, RisingTideController> _controllers = {};

  RisingTideController controllerFor(String packageName) {
    return _controllers.putIfAbsent(packageName, () => RisingTideController(packageName));
  }

  /// Calculates the current Rising Tide stage for a given package.
  static RisingTideStage getStage(String packageName) {
    final controller = _instance.controllerFor(packageName);
    // Return the latest stage from the controller (fallback to whisper)
    return controller.currentStage;
  }

  /// Synchronizes the list of apps that need interception with the native Accessibility service.
  static Future<void> syncInterceptionState() async {
    if (!StorageService.isRisingTideMasterEnabled()) {
      await NativeService.sendBlockedApps([]);
      return;
    }

    // Ensure controllers are instantiated so they process the current usage
    // before we decide which apps need to be blocked.
    final allFlagged = StorageService.getFlaggedApps();
    for (final pkg in allFlagged) {
      RisingTideService._instance.controllerFor(pkg); // instantiate controller and start listening
    }
    // Give the usage stream a chance to emit the initial percentage.
    await Future.delayed(const Duration(milliseconds: 100));

    // Only send apps to the native watcher that are currently in a blocking stage (Dim, Mirror, Silence).
    // This prevents the native service from "stealing focus" (bringing Kora to front) for apps
    // that should be allowed to open directly in the Whisper stage.
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
    await syncInterceptionState();
  }

  /// Call ONLY when the user consciously taps "Open anyway" on the Dim gate.
  /// Sets a flag so the gate won't fire again today for this app.
  static Future<void> markUserDecision(String packageName) async {
    final today = _localDayKey(DateTime.now());
    await StorageService.setString(
      'rt_dim_decided_${today}_$packageName',
      'true',
    );
  }

  static bool _hasUserDecidedToday(String packageName) {
    final today = _localDayKey(DateTime.now());
    return StorageService.getString('rt_dim_decided_${today}_$packageName') ==
        'true';
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
    await StorageService.setString(
      _lockKeyPrefix + packageName,
      expiry.toIso8601String(),
    );
    await RisingTideLogger.logReopenLockApplied(packageName);
  }

  /// Manually clears the grace period lock for a package.
  /// Call this when the user launches an app from the Launcher UI
  /// to ensure they are always intercepted on "New Sessions".
  static Future<void> clearReopenLock(String packageName) async {
    await StorageService.remove(_lockKeyPrefix + packageName);
    debugPrint('RisingTide: Cleared grace period for $packageName');
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
