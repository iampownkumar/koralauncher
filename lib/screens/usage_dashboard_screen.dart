import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../widgets/app_list_item.dart';
import '../services/storage_service.dart';
import '../services/native_service.dart';
import '../widgets/app_long_press_menu.dart';
import '../widgets/permission_gate_card.dart';
import 'interception_screen.dart';
import 'package:android_intent_plus/android_intent.dart';

class UsageDashboardScreen extends StatefulWidget {
  const UsageDashboardScreen({super.key});

  @override
  State<UsageDashboardScreen> createState() => _UsageDashboardScreenState();
}

class _UsageDashboardScreenState extends State<UsageDashboardScreen>
    with WidgetsBindingObserver {
  List<AppInfo> _sortedApps = [];
  bool _isLoading = true;
  bool _hasUsagePermission = true; // optimistic until first check

  int _roundedMinutesForApp(String packageName) {
    return (UsageService.getAppUsage(packageName).inMilliseconds + 30000) ~/ 60000;
  }

  Duration _computeTotal() {
    return UsageService.getVisibleTotalUsage(minRoundedMinutes: 1);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashBoardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when user returns from Usage Access settings
    if (state == AppLifecycleState.resumed) {
      _loadDashBoardData();
    }
  }

  Future<void> _loadDashBoardData() async {
    final hasPermission = await NativeService.hasUsagePermission();
    if (mounted && !hasPermission) {
      setState(() {
        _hasUsagePermission = false;
        _isLoading = false;
      });
      return;
    }
    await UsageService.refreshUsage();

    // Grab all launchable apps
    List<AppInfo> apps = List.from(LauncherService.cachedApps);

    // We only care about apps that actually have usage > 0, and not the launcher itself
    apps.removeWhere((app) => app.packageName.contains('koralauncher'));

    apps.sort((a, b) {
      final usageA = UsageService.getAppUsage(a.packageName);
      final usageB = UsageService.getAppUsage(b.packageName);
      // Sort descending (highest usage first)
      return usageB.compareTo(usageA);
    });

    if (mounted) {
      setState(() {
        _hasUsagePermission = true;
        _sortedApps = apps
            .where((app) => _roundedMinutesForApp(app.packageName) >= 1)
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep TOTAL SCREEN TIME consistent with what we display in the list:
    // same rounded-minute rule, same visible app set.
    final totalUsage = _computeTotal();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Usage Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white24),
              )
            : !_hasUsagePermission
                ? PermissionGateCard(
                    icon: Icons.bar_chart_outlined,
                    title: 'Enable Usage Access',
                    body:
                        'Usage Access is needed for screen time, app usage stats, and daily limits.',
                    buttonLabel: 'Open Usage Access',
                    onButton: () async {
                      await NativeService.openUsageSettings();
                    },
                  )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryHeader(totalUsage),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "APP USAGE",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 3,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _sortedApps.isEmpty
                        ? const Center(
                            child: Text(
                              "No significant app usage data recorded today.",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sortedApps.length + 1, // +1 for the settings card at the bottom
                            itemBuilder: (context, index) {
                              if (index == _sortedApps.length) {
                                return _buildLauncherSettingsCard();
                              }
                              final app = _sortedApps[index];
                              final isFlagged = StorageService.isAppFlagged(
                                app.packageName,
                              );
                              final usage = UsageService.getAppUsage(
                                app.packageName,
                              );

                              return AppListItem(
                                app: app,
                                usage: usage,
                                isFlagged: isFlagged,
                                onFlagTap: () async {
                                  await StorageService.toggleFlaggedApp(
                                    app.packageName,
                                  );
                                  if (mounted) setState(() {});
                                },
                                onLongPress: () {
                                  showAppLongPressMenu(
                                    context,
                                    app,
                                    onChanged: () {
                                      if (mounted) setState(() {});
                                    },
                                  );
                                },
                                onTap: () {
                                  if (isFlagged) {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => InterceptionScreen(app: app),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                      ),
                                    );
                                  } else {
                                    LauncherService.launchApp(app.packageName);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLauncherSettingsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "LAUNCHER SETTINGS",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Change Default Launcher",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Switch back to your system launcher or choose another one.",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => NativeService.openDefaultLauncherSettings(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Home Settings", style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    const AndroidIntent(
                      action: 'android.intent.action.SET_WALLPAPER',
                    ).launch();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Wallpaper", style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Duration total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL SCREEN TIME",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            UsageService.formatDuration(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w200,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }


}
