import 'dart:typed_data';

/// Unified entry that represents either a real installed app or a pinned
/// shortcut (browser "Add to Home Screen", etc.).
///
/// The app drawer renders both the same way. Launching differs:
///   - isShortcut == false → InstalledApps.startApp(packageName)
///   - isShortcut == true  → NativeService.launchShortcut(intentUri!)
class AppEntry {
  final String name;
  final String packageName; // real package OR shortcut ID prefixed 'shortcut_'
  final Uint8List? icon;
  final bool isShortcut;
  final String? intentUri; // non-null for legacy broadcasts
  final String? targetPackage; // non-null for modern pin requests
  final String? shortcutId; // non-null when isShortcut == true

  const AppEntry({
    required this.name,
    required this.packageName,
    required this.icon,
    this.isShortcut = false,
    this.intentUri,
    this.targetPackage,
    this.shortcutId,
  });
}
