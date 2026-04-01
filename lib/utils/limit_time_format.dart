/// Human-readable daily limits for Rising Tide UI.
class LimitTimeFormat {
  LimitTimeFormat._();

  /// e.g. "2h 30m · 150 min" or "45m · 45 min"
  static String dualLabel(int totalMinutes) {
    if (totalMinutes <= 0) return '0m · 0 min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final time = h > 0 ? '${h}h ${m}m' : '${m}m';
    return '$time · $totalMinutes min';
  }

  /// Compact: "2h 30m"
  static String compact(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// From 4h upward — softer warning (amber UI).
  static bool showsSoftLimitWarning(int totalMinutes) => totalMinutes >= 240;

  /// Above 4h — stronger warning + confirm dialog on save.
  static bool needsHighLimitConfirm(int totalMinutes) => totalMinutes > 240;
}
