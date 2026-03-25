import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../widgets/app_list_item.dart';
import '../services/storage_service.dart';
import 'interception_screen.dart';

class UsageDashboardScreen extends StatefulWidget {
  const UsageDashboardScreen({super.key});

  @override
  State<UsageDashboardScreen> createState() => _UsageDashboardScreenState();
}

class _UsageDashboardScreenState extends State<UsageDashboardScreen> {
  List<AppInfo> _sortedApps = [];
  bool _isLoading = true;

  int _roundedMinutesForApp(String packageName) {
    final usageMs = UsageService.getAppUsage(packageName).inMilliseconds;
    // Keep rounding logic identical to the list filter above (rounded half-up).
    return (usageMs + 30000) ~/ 60000;
  }

  Duration _computeTotalFromVisibleApps() {
    final totalMinutes = _sortedApps.fold<int>(
      0,
      (sum, app) => sum + _roundedMinutesForApp(app.packageName),
    );
    return Duration(minutes: totalMinutes);
  }

  @override
  void initState() {
    super.initState();
    _loadDashBoardData();
  }

  Future<void> _loadDashBoardData() async {
    // Make sure we have the latest usage logic from UsageService
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
        // Match Digital Wellbeing behavior: show anything with at least 1 rounded minute.
        _sortedApps = apps.where((app) {
          if (!UsageService.shouldCountPackage(app.packageName)) return false;
          final usageMs = UsageService.getAppUsage(app.packageName).inMilliseconds;
          final roundedMinutes = (usageMs + 30000) ~/ 60000; // round half-up
          return roundedMinutes >= 1;
        }).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep TOTAL SCREEN TIME consistent with what we display in the list:
    // same rounded-minute rule, same visible app set.
    final totalUsage = _computeTotalFromVisibleApps();
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Dark minimalism
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
        ? const Center(child: CircularProgressIndicator(color: Colors.white24))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryHeader(totalUsage),
              const SizedBox(height: 16),
              Expanded(
                child: _sortedApps.isEmpty
                    ? const Center(child: Text("No significant app usage data recorded today.", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _sortedApps.length,
                        itemBuilder: (context, index) {
                          final app = _sortedApps[index];
                          final isFlagged = StorageService.isAppFlagged(app.packageName);
                          final usage = UsageService.getAppUsage(app.packageName);
                          
                          return AppListItem(
                            app: app, 
                            usage: usage, 
                            isFlagged: isFlagged,
                            onLongPress: () async {
                              await StorageService.toggleFlaggedApp(app.packageName);
                              if (mounted) setState(() {});
                            },
                            onTap: () {
                              if (isFlagged) {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => 
                                        InterceptionScreen(app: app),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
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
              )
            ],
          ),
      ),
    );
  }

  Widget _buildSummaryHeader(Duration total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL SCREEN TIME",
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            UsageService.formatDuration(total),
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w200, height: 1),
          ),
        ],
      ),
    );
  }
}
