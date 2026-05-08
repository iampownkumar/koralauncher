import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../services/storage_service.dart';
import '../services/native_service.dart';
import '../widgets/circular_usage_ring.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/glassmorphic_app_card.dart';
import '../widgets/daily_limit_sheet.dart';
import '../widgets/app_long_press_menu.dart';
import '../widgets/accessibility_disclosure_sheet.dart';
import '../widgets/permission_gate_card.dart';
import 'interception_screen.dart';
import 'kora_settings_page.dart';


/// Unified dashboard that merges Usage Dashboard + Tide Pool (Rising Tide)
/// into a single, premium screen.
class UnifiedDashboardScreen extends StatefulWidget {
  const UnifiedDashboardScreen({super.key});

  @override
  State<UnifiedDashboardScreen> createState() => _UnifiedDashboardScreenState();
}

class _UnifiedDashboardScreenState extends State<UnifiedDashboardScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  List<AppInfo> _sortedApps = [];
  List<DayUsage> _weeklyData = [];
  bool _isLoading = true;
  bool _hasUsagePermission = true;
  bool _hasAccessibility = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadAll();
  }

  Future<void> _loadAll() async {
    final hasUsage = await NativeService.hasUsagePermission();
    final hasAccess = await NativeService.hasAccessibilityPermission();

    if (mounted && !hasUsage) {
      setState(() {
        _hasUsagePermission = false;
        _hasAccessibility = hasAccess;
        _isLoading = false;
      });
      return;
    }

    // Refresh today's usage
    await UsageService.refreshUsage();

    // Load weekly data
    final weekly = await UsageService.getWeeklyUsage();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun

    final weeklyChartData = weekly.map((d) {
      final dayIndex = d.date.weekday - 1; // 0-indexed
      return DayUsage(
        label: dayNames[dayIndex],
        minutes: d.totalMinutes,
        isToday: d.date.weekday == today && d.date.day == DateTime.now().day,
      );
    }).toList();

    // Build sorted app list
    List<AppInfo> apps = List.from(LauncherService.cachedApps);
    apps.removeWhere((app) => app.packageName.contains('koralauncher'));
    apps.sort((a, b) {
      final usageA = UsageService.getAppUsage(a.packageName);
      final usageB = UsageService.getAppUsage(b.packageName);
      return usageB.compareTo(usageA);
    });

    if (mounted) {
      setState(() {
        _hasUsagePermission = true;
        _hasAccessibility = hasAccess;
        _weeklyData = weeklyChartData;
        _sortedApps = apps
            .where(
              (app) =>
                  (UsageService.getAppUsage(app.packageName).inMilliseconds +
                          30000) ~/
                      60000 >=
                  1,
            )
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1A), Color(0xFF050510), Color(0xFF080818)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                )
              : !_hasUsagePermission
              ? _buildPermissionGate()
              : _buildDashboard(),
        ),
      ),
    );
  }

  Widget _buildPermissionGate() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: PermissionGateCard(
            icon: Icons.bar_chart_outlined,
            title: 'Enable Usage Access',
            body:
                'Usage Access is needed for screen time, app usage stats, and daily limits.',
            buttonLabel: 'Open Usage Access',
            onButton: () async {
              await NativeService.openUsageSettings();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const KoraSettingsPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final totalUsage = UsageService.getVisibleTotalUsage(minRoundedMinutes: 1);

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 12),

        // Circular ring
        CircularUsageRing(totalUsage: totalUsage),
        const SizedBox(height: 20),

        // Weekly bar chart
        _buildWeeklySection(),
        const SizedBox(height: 16),

        // Rising Tide toggle
        _buildRisingTideToggle(),
        const SizedBox(height: 12),

        // Tab bar: All Apps / Flagged
        _buildTabBar(),
        const SizedBox(height: 8),

        // App list
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildAllAppsList(), _buildFlaggedAppsList()],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'THIS WEEK',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          WeeklyBarChart(days: _weeklyData, height: 130),
        ],
      ),
    );
  }

  Widget _buildRisingTideToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.waves,
            color:
                _hasAccessibility && StorageService.isRisingTideMasterEnabled()
                ? const Color(0xFF06B6D4)
                : Colors.white30,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rising Tide',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _hasAccessibility
                      ? (StorageService.isRisingTideMasterEnabled()
                            ? 'Active — flagged apps have gates'
                            : 'Off — tap to enable')
                      : 'Accessibility required',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value:
                _hasAccessibility && StorageService.isRisingTideMasterEnabled(),
            activeThumbColor: const Color(0xFF06B6D4),
            activeTrackColor: const Color(0xFF06B6D4).withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            onChanged: (v) async {
              if (!_hasAccessibility) {
                if (!context.mounted) return;
                await AccessibilityDisclosureSheet.show(context);
                await _loadAll();
                return;
              }
              await StorageService.setRisingTideMasterEnabled(v);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final flaggedCount = StorageService.getFlaggedApps().length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.35),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
        ),
        tabs: [
          const Tab(text: 'ALL APPS'),
          Tab(text: 'FLAGGED ($flaggedCount)'),
        ],
      ),
    );
  }

  Widget _buildAllAppsList() {
    if (_sortedApps.isEmpty) {
      return Center(
        child: Text(
          'No significant usage recorded today.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: _sortedApps.length,
      itemBuilder: (context, index) {

        final app = _sortedApps[index];
        final isFlagged = StorageService.isAppFlagged(app.packageName);
        final usage = UsageService.getAppUsage(app.packageName);
        final limit = StorageService.getAppDailyLimitMinutes(app.packageName);

        return GlassmorphicAppCard(
          app: app,
          usage: usage,
          isFlagged: isFlagged,
          limitMinutes: isFlagged ? limit : null,
          onTap: () {
            if (isFlagged) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (c, a, sa) => InterceptionScreen(app: app),
                  transitionsBuilder: (c, a, sa, child) =>
                      FadeTransition(opacity: a, child: child),
                ),
              );
            } else {
              LauncherService.launchApp(app.packageName);
            }
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
          onFlagTap: () async {
            await StorageService.toggleFlaggedApp(app.packageName);
            if (mounted) setState(() {});
          },
          onSettingsTap: isFlagged
              ? () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DailyLimitSheet(
                      packageName: app.packageName,
                      appLabel: app.name,
                      initialLimitMinutes: limit,
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                }
              : null,
        );
      },
    );
  }

  Widget _buildFlaggedAppsList() {
    final flaggedPackages = StorageService.getFlaggedApps();
    final allApps = LauncherService.cachedApps
        .where((app) => !app.packageName.contains('koralauncher'))
        .toList();
    final flaggedApps = allApps
        .where((a) => flaggedPackages.contains(a.packageName))
        .toList();

    if (!_hasAccessibility) {
      return PermissionGateCard(
        icon: Icons.security_outlined,
        title: 'Enable Accessibility',
        body: 'Accessibility is required for Rising Tide gates.',
        buttonLabel: 'Enable Accessibility',
        onButton: () async {
          await AccessibilityDisclosureSheet.show(context);
          await _loadAll();
        },
      );
    }

    if (flaggedApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waves,
              size: 48,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'No apps flagged yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the wave icon on any app to flag it',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: flaggedApps.length,
      itemBuilder: (context, i) {
        final app = flaggedApps[i];
        final usage = UsageService.getAppUsage(app.packageName);
        final limit = StorageService.getAppDailyLimitMinutes(app.packageName);

        return GlassmorphicAppCard(
          app: app,
          usage: usage,
          isFlagged: true,
          limitMinutes: limit,
          onTap: () {
            showAppLongPressMenu(
              context,
              app,
              onChanged: () => setState(() {}),
            );
          },
          onFlagTap: () async {
            await StorageService.toggleFlaggedApp(app.packageName);
            if (mounted) setState(() {});
          },
          onSettingsTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DailyLimitSheet(
                packageName: app.packageName,
                appLabel: app.name,
                initialLimitMinutes: limit,
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
        );
      },
    );
  }

}
