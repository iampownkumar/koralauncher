/// After the user completes the interception flow and we launch the target app, the accessibility
/// service will see a foreground event for that package; skip re-showing the gate briefly.
class ForegroundInterceptGuard {
  static String? _bypassPackage;
  static DateTime? _bypassUntil;

  static void recordPostLaunchBypass(String packageName,
      {Duration window = const Duration(seconds: 3)}) {
    _bypassPackage = packageName;
    _bypassUntil = DateTime.now().add(window);
  }

  static bool shouldSkipForPackage(String packageName) {
    final until = _bypassUntil;
    if (until == null || _bypassPackage != packageName) return false;
    if (DateTime.now().isAfter(until)) {
      _bypassPackage = null;
      _bypassUntil = null;
      return false;
    }
    return true;
  }
}
