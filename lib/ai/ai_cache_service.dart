import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// Manages caching of AI-generated interception messages.
///
/// Cache strategy:
///   - Key = `packageName + stage + date`
///   - TTL = 2 hours (messages rotate across the day for freshness)
///   - Invalidated on stage transition (Dim → Mirror gets a new message)
///
/// This prevents re-generating expensive AI prompts on every app open
/// while keeping messages feeling fresh across the day.
class AICacheService {
  static const String _cachePrefix = 'ai_msg_cache_';
  static const String _cacheTimePrefix = 'ai_msg_time_';

  /// Maximum age of a cached message before it should be regenerated.
  static const Duration cacheTTL = Duration(minutes: 5);

  /// Returns a cached message for the given key, or null if expired / missing.
  static String? getCachedMessage({
    required String packageName,
    required String stageName,
  }) {
    final key = _buildKey(packageName, stageName);
    final cached = StorageService.getString('$_cachePrefix$key');
    if (cached == null) return null;

    // Check TTL
    final timeStr = StorageService.getString('$_cacheTimePrefix$key');
    if (timeStr == null) return null;

    try {
      final cachedAt = DateTime.parse(timeStr);
      if (DateTime.now().difference(cachedAt) > cacheTTL) {
        // Expired — caller should regenerate
        debugPrint('AICache: expired for $key');
        return null;
      }
    } catch (_) {
      return null;
    }

    debugPrint('AICache: hit for $key');
    return cached;
  }

  /// Store a generated message in cache.
  static Future<void> cacheMessage({
    required String packageName,
    required String stageName,
    required String message,
  }) async {
    final key = _buildKey(packageName, stageName);
    await StorageService.setString(
      '$_cachePrefix$key',
      message,
    );
    await StorageService.setString(
      '$_cacheTimePrefix$key',
      DateTime.now().toIso8601String(),
    );
    debugPrint('AICache: stored for $key');
  }

  /// Invalidate cache for a specific package (e.g. on stage transition).
  static Future<void> invalidate(String packageName) async {
    // Clear all stages for this package today
    for (final stage in ['dim', 'mirror']) {
      final key = _buildKey(packageName, stage);
      await StorageService.remove('$_cachePrefix$key');
      await StorageService.remove('$_cacheTimePrefix$key');
    }
    debugPrint('AICache: invalidated for $packageName');
  }

  /// Build a unique cache key scoped to today.
  static String _buildKey(String packageName, String stageName) {
    final now = DateTime.now();
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '${dayKey}_${stageName}_$packageName';
  }
}
