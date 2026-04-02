import 'package:flutter/material.dart';
import '../services/native_service.dart';
import '../services/storage_service.dart';
import '../widgets/accessibility_disclosure_sheet.dart';
import '../widgets/permission_widgets.dart';

/// Full-page settings screen: Rising Tide master switch, permissions, privacy.
/// Accessible from home screen or any deep-link entry point.
class PermissionsAndPrivacyScreen extends StatefulWidget {
  const PermissionsAndPrivacyScreen({super.key});

  @override
  State<PermissionsAndPrivacyScreen> createState() =>
      _PermissionsAndPrivacyScreenState();
}

class _PermissionsAndPrivacyScreenState
    extends State<PermissionsAndPrivacyScreen>
    with WidgetsBindingObserver {
  bool _isDefault = false;
  bool _hasUsage = false;
  bool _hasAccessibility = false;
  bool _risingTideMaster = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _risingTideMaster = StorageService.isRisingTideMasterEnabled();
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when user returns from Android settings
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final d = await NativeService.isDefaultLauncher();
    final u = await NativeService.hasUsagePermission();
    final a = await NativeService.hasAccessibilityPermission();
    if (mounted) {
      setState(() {
        _isDefault = d;
        _hasUsage = u;
        _hasAccessibility = a;
      });
    }
  }

  Future<void> _toggleMaster(bool v) async {
    await StorageService.setRisingTideMasterEnabled(v);
    setState(() => _risingTideMaster = v);
  }

  Future<void> _accessibilityTapped() async {
    if (_hasAccessibility) {
      await NativeService.openAccessibilitySettings();
    } else {
      await AccessibilityDisclosureSheet.show(context);
      await _refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Permissions & Privacy',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Rising Tide ─────────────────────────────────────
          const SectionHeader('Rising Tide', topPad: 12),
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _risingTideMaster
                    ? Colors.cyanAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: const Text(
                'Rising Tide',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Pause before opening flagged apps.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13),
              ),
              value: _risingTideMaster,
              activeThumbColor: Colors.cyanAccent,
              activeTrackColor: Colors.cyan.withValues(alpha: 0.4),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
              onChanged: _toggleMaster,
            ),
          ),
          if (!_risingTideMaster)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Rising Tide is off. Flagged apps will open normally.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12),
              ),
            ),

          // ── Permissions ──────────────────────────────────────
          const SectionHeader('Permissions'),
          SettingsPermissionRow(
            title: 'Default launcher',
            subtitle: 'Lets Kora stay as your home screen.',
            isEnabled: _isDefault,
            buttonLabel: 'Open',
            onTap: () async {
              await NativeService.openDefaultLauncherSettings();
              await Future.delayed(const Duration(milliseconds: 600));
              _refreshPermissions();
            },
          ),
          SettingsPermissionRow(
            title: 'Usage access',
            subtitle: 'Used for usage dashboard and app limits.',
            isEnabled: _hasUsage,
            buttonLabel: 'Open',
            onTap: () async {
              await NativeService.openUsageSettings();
              await Future.delayed(const Duration(milliseconds: 600));
              _refreshPermissions();
            },
          ),
          SettingsPermissionRow(
            title: 'Accessibility',
            subtitle: 'Used only for Rising Tide interception on apps you flag.',
            isEnabled: _hasAccessibility,
            buttonLabel: _hasAccessibility ? 'Manage' : 'Enable',
            onTap: _accessibilityTapped,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Text(
              'These controls are optional. You can turn them on or off anytime in Android settings.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 12, height: 1.5),
            ),
          ),

          // ── Privacy ───────────────────────────────────────────
          const SectionHeader('Privacy'),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kora uses device permissions only for features you turn on, like screen-time insights and focus protection.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kora does not use Accessibility for advertising or marketing.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
