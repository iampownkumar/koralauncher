import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import '../widgets/app_list_item.dart';
import '../widgets/app_long_press_menu.dart';
import 'interception_screen.dart';
import 'dart:ui';

class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasUsagePermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoad();
    _searchController.addListener(_filterApps);
    // Request focus for search bar when drawer opens
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLoad() async {
    final hasUsage = await NativeService.hasUsagePermission();
    setState(() {
      _hasUsagePermission = hasUsage;
      _apps = LauncherService.cachedApps
          .where((app) => !app.packageName.contains('koralauncher'))
          .toList();
      _filteredApps = _apps;
    });
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _apps.where((app) {
        return app.name.toLowerCase().contains(query);
      }).toList();
    });

    // Auto-launch if there's exactly one result and query is not empty
    if (_filteredApps.length == 1 && query.isNotEmpty) {
      final app = _filteredApps.first;
      final isFlagged = StorageService.isAppFlagged(app.packageName);

      if (isFlagged) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                InterceptionScreen(app: app),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ).then((_) {
          _searchController.clear();
          if (mounted) Navigator.pop(context);
        });
      } else {
        LauncherService.launchApp(app.packageName).then((_) {
          _searchController.clear();
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await LauncherService.refreshApps();
    await UsageService.refreshUsage();
    if (mounted) {
      setState(() {
        _apps = LauncherService.cachedApps
            .where((app) => !app.packageName.contains('koralauncher'))
            .toList();
        _filterApps();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          _searchFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _searchFocusNode.unfocus(),
        onVerticalDragEnd: (details) {
          // Swipe down to go back to home screen
          if (details.primaryVelocity! > 0) {
            _searchFocusNode.unfocus();
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false, // Prevent layout jumps
          backgroundColor:
              Colors.black, // Solid dark background to fix recents glitch
          body: Stack(
            children: [
              // Dark Blur Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.85),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchField(),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          // Detect when user is at the top AND pulls down (overscroll)
                          if (notification is ScrollUpdateNotification) {
                            if (notification.metrics.pixels <= -60) {
                              _searchFocusNode.unfocus();
                              Navigator.maybePop(context);
                              return true;
                            }
                          }
                          return false;
                        },
                        child: _buildAppList(),
                      ),
                    ),
                    // Space for keyboard when resizeToAvoidBottomInset is false
                    Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: Theme.of(context).textTheme.bodyLarge,
        onSubmitted: (_) {
          if (_filteredApps.isNotEmpty) {
            final app = _filteredApps.first;
            LauncherService.launchApp(app.packageName).then((_) {
              _searchController.clear();
              if (mounted) Navigator.pop(context);
            });
          }
        },
        decoration: InputDecoration(
          hintText: 'Search apps...',
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAppList() {
    if (_apps.isEmpty) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ), // Ensure we can overscroll
      itemCount: _filteredApps.length,
      padding: const EdgeInsets.only(bottom: 32),
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        final isFlagged = StorageService.isAppFlagged(app.packageName);
        final usage = _hasUsagePermission
            ? UsageService.getAppUsage(app.packageName)
            : Duration.zero;
        return AppListItem(
          app: app,
          isFlagged: isFlagged,
          usage: usage,
          onFlagTap: () async {
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
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              ).then((_) {
                _searchController.clear();
                if (mounted) Navigator.pop(context);
              });
            } else {
              LauncherService.launchApp(app.packageName).then((_) {
                _searchController.clear();
                if (mounted) Navigator.pop(context);
              });
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
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import '../services/todo_service.dart';
import 'app_drawer_screen.dart';
import '../widgets/goal_setter.dart';
import '../widgets/todo_list_card.dart';
import 'todo_screen.dart';
import 'usage_dashboard_screen.dart';
import 'tide_pool_screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:upgrader/upgrader.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showGoalSetter = false;
  bool _isDefaultLauncher = true;
  bool _hasUsagePermission = true;
  bool _hasAccessibilityPermission = true;
  bool _pulseIntention = false;
  String? _goal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _refreshHomeState();
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      _refreshHomeState();
    }
  }

  Future<void> _refreshHomeState() async {
    final isDefault = await NativeService.isDefaultLauncher();
    final hasUsage = await NativeService.hasUsagePermission();
    final hasAccessibility = await NativeService.hasAccessibilityPermission();
    await UsageService.refreshUsage();
    await TodoService.refreshTodos();
    final newGoal = StorageService.getDailyIntention();
    
    if (!mounted) return;
    
    if (_isDefaultLauncher != isDefault || 
        _hasUsagePermission != hasUsage || 
        _hasAccessibilityPermission != hasAccessibility ||
        _goal != newGoal) {
      setState(() {
        _isDefaultLauncher = isDefault;
        _hasUsagePermission = hasUsage;
        _hasAccessibilityPermission = hasAccessibility;
        _goal = newGoal;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _loadInitialData() async {
    await LauncherService.refreshApps();
    await TodoService.init();
    await _refreshHomeState();
    
    if (!StorageService.hasCompletedOnboarding()) {
      if (mounted) {
        setState(() {
          _showGoalSetter = true;
        });
      }
    } else {
      _checkMorningGoalTrigger();
    }
  }

  void _checkMorningGoalTrigger() {
    final now = DateTime.now();
    if (now.hour >= 5 && now.hour < 10) {
      if (_goal == null || _goal!.isEmpty) {
        setState(() {
          _pulseIntention = true;
        });
      }
    }
  }

  void _openAppDrawer() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AppDrawerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      _refreshHomeState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -300) {
                  _openAppDrawer();
                }
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity;
                if (velocity != null) {
                  if (velocity > 300) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const UsageDashboardScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                      ),
                    );
                  } else if (velocity < -300) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const TidePoolScreen(),
                        transitionDuration: const Duration(milliseconds: 340),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                      ),
                    ).then((_) => setState(() {}));
                  }
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                      child: Column(
                        children: [
                          if (!_isDefaultLauncher)
                            _buildDefaultLauncherBanner(),
                          if (!_hasAccessibilityPermission)
                            _buildAccessibilityPermissionBanner(),
                          if (_hasAccessibilityPermission && !_hasUsagePermission)
                            _buildUsagePermissionBanner(),
                          _buildTopInfoBar(),

                          // _buildGoalHeader() replaced by chip in top bar
                          const SizedBox(height: 16),

                          if (!_showGoalSetter) ...[
                            TodoListCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => const TodoScreen(),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            ),
                          ],

                          const Spacer(),

                          _buildTimeAndDate(),
                          const SizedBox(height: 24),

                          _buildQuickAccessDock(),
                          const SizedBox(height: 16),

                          _buildSwipeHint(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_showGoalSetter)
              GoalSetter(
                initialGoal: _goal,
                onDismiss: () {
                  setState(() {
                    _showGoalSetter = false;
                  });
                },
                onGoalSet: () {
                  setState(() {
                    _showGoalSetter = false;
                    _goal = StorageService.getDailyIntention();
                  });
                },
              ),
            UpgradeAlert(
              showIgnore: false,
              showLater: true,
              dialogStyle: UpgradeDialogStyle.material,
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndDate() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        return Column(
          children: [
            Text(
              DateFormat('HH:mm:ss').format(now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w200,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(now).toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipeHint() {
    return GestureDetector(
      onTap: _openAppDrawer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_arrow_up, color: Colors.white60, size: 28),
        ],
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSetGoalPill(),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCenterIntentionText(),
          ),
          const SizedBox(width: 12),
          if (_hasUsagePermission) _buildUsageStats(),
        ],
      ),
    );
  }

  Widget _buildSetGoalPill() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showGoalSetter = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            const Text(
              "Set Goal",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterIntentionText() {
    final hasGoal = _goal != null && _goal!.isNotEmpty;
    
    Widget textWidget = Text(
      hasGoal ? _goal! : "No intention set",
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: hasGoal ? Colors.white : Colors.white.withValues(alpha: 0.4),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );

    if (_pulseIntention && !hasGoal) {
      // Soft single pulse on morning unlock if no goal
      textWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOutSine,
        builder: (context, val, child) {
          return Opacity(opacity: val, child: child);
        },
        onEnd: () {
          if (mounted) {
            setState(() {
              _pulseIntention = false;
            });
          }
        },
        child: textWidget,
      );
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _pulseIntention = false;
          _showGoalSetter = true;
        });
      },
      child: textWidget,
    );
  }

  Widget _buildUsageStats() {
    // Keep home "overall usage" consistent with the dashboard list filtering.
    final totalUsage = UsageService.getVisibleTotalUsage(minRoundedMinutes: 1);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const UsageDashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              UsageService.formatDuration(totalUsage),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLauncherBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.black.withValues(alpha: 0.6),
      child: Row(
        children: [
          Icon(Icons.home, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Kora is not default launcher",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              NativeService.openDefaultLauncherSettings();
            },
            child: Text(
              "SET DEFAULT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityPermissionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, size: 24, color: Colors.white),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Enable Rising Tide protection",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Accessibility Requirement",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Kora uses Accessibility Services to detect when you open habit-forming apps.\n\n"
                    "This allows us to show you the intentional delay screens and help you stay focused on your goals.\n\n"
                    "We do NOT use this to collect any private data, keystrokes, or passwords. It is strictly used for app interception.",
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await NativeService.openAccessibilitySettings();
                      },
                      child: const Text("I Understand"),
                    ),
                  ],
                ),
              );
            },
            child: const Text("ENABLE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsagePermissionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.show_chart, size: 24, color: Colors.white),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Enable usage stats for insights",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              // foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Usage Access Required",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Kora Launcher requires 'Usage Access' permission to monitor which apps you open and for how long.\n\n"
                    "This allows the Rising Tide system to intercept habit-building apps, measure your screen time accurately, and help you reduce distractions.\n\n"
                    "Your usage data strictly stays on your device and is never sent to any servers.",
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await NativeService.openUsageSettings();
                      },
                      child: const Text(
                        "I Understand",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              "ENABLE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessDock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildShortcutIcon(
            icon: Icons.phone,
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.DIAL',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.message,
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.APP_MESSAGING',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.language, // Browser
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.APP_BROWSER',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.camera_alt,
            onTap: () => const AndroidIntent(
              action: 'android.media.action.STILL_IMAGE_CAMERA',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.image_outlined,
            onTap: () => const AndroidIntent(
              action: 'android.intent.action.MAIN',
              category: 'android.intent.category.APP_GALLERY',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            ).launch(),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../services/rising_tide_service.dart';
import '../models/rising_tide_stage.dart';
import '../services/rising_tide_logger.dart';
import '../services/usage_service.dart';
import '../widgets/gate_settings_sheet.dart';
import '../database/database_provider.dart';
import '../services/storage_service.dart';
import '../services/app_lock_manager.dart';
import '../services/foreground_intercept_guard.dart';
import '../utils/limit_time_format.dart';

class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  late RisingTideStage _stage;
  bool _isLoading = true;
  // Stats for Stage 2–4
  int _opensToday = 0;
  int _minutesToday = 0;
  String? _dailyIntention;

  // Flow control
  String? _selectedMood;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _canProceed = false;

  // Tasks state
  bool _showTasks = false;
  List<String> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initStage();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initStage() async {
    await UsageService.refreshUsage();
    final stage = RisingTideService.getStage(widget.app.packageName);

    if (stage == RisingTideStage.whisper) {
      await StorageService.incrementTodayOpenCount(widget.app.packageName);
      await _launchApp();
      return;
    }

    await StorageService.incrementTodayOpenCount(widget.app.packageName);

    final stats = await RisingTideService.getStats(widget.app.packageName);
    _dailyIntention = RisingTideService.getDailyIntention();

    if (mounted) {
      setState(() {
        _stage = stage;
        _opensToday = stats['opens'] ?? 0;
        _minutesToday = stats['minutes'] ?? 0;
        _isLoading = false;

        // Stage 4 / Silence has no countdown and is always blocked
        if (_stage == RisingTideStage.silence) {
          _tasks = StorageService.getTodayTasks();
        } else {
          _startInitialCountdown();
        }
      });
      RisingTideLogger.logAppOpen(widget.app.packageName, _stage);
    }
  }

  void _startInitialCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 5;
    _canProceed = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            _canProceed = true;
            _countdownTimer?.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _launchApp({bool afterInterceptionFlow = false}) async {
    // Log the session start in the database to increment the open count
    await db.startSession(widget.app.packageName, widget.app.name);
    if (afterInterceptionFlow) {
      ForegroundInterceptGuard.recordPostLaunchBypass(widget.app.packageName);
    }
    InstalledApps.startApp(widget.app.packageName);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background - Semi-transparent app icon or just slate
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),

          // Glassmorphic Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _getSigma(),
                sigmaY: _getSigma(),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E293B).withValues(
                        alpha: _getOverlayOpacity() * 0.7,
                      ),
                      const Color(0xFF0F172A).withValues(alpha: _getOverlayOpacity()),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAppHeader(),
                  const Spacer(),
                  _buildStageContent(),
                  const Spacer(),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getSigma() {
    switch (_stage) {
      case RisingTideStage.whisper:
        return 5;
      case RisingTideStage.dim:
        return 15;
      case RisingTideStage.mirror:
        return 30;
      case RisingTideStage.silence:
        return 50;
    }
  }

  double _getOverlayOpacity() {
    switch (_stage) {
      case RisingTideStage.whisper:
        return 0.2;
      case RisingTideStage.dim:
        return 0.4;
      case RisingTideStage.mirror:
        return 0.6;
      case RisingTideStage.silence:
        return 0.8;
    }
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        Hero(
          tag: widget.app.packageName,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.app.icon != null
                ? Image.memory(widget.app.icon!, width: 64, height: 64)
                : const Icon(Icons.apps, size: 64, color: Colors.white24),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.app.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case RisingTideStage.dim:
        return _buildDimContent();
      case RisingTideStage.mirror:
        return _buildMirrorContent();
      case RisingTideStage.silence:
        return _buildSilenceContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDimContent() {
    return Column(
      children: [
        const Text(
          "Pause for a second.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "You've used ${widget.app.name} for $_minutesToday mins today.\nWhat's the vibe?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Opens today: $_opensToday · Limit ${LimitTimeFormat.dualLabel(RisingTideService.getAppDailyLimit(widget.app.packageName).inMinutes)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          textAlign: TextAlign.center,
        ),
        _buildGateSettingsLink(),
        const SizedBox(height: 24),
        _buildMoodSelector(),
      ],
    );
  }

  Widget _buildMirrorContent() {
    return Column(
      children: [
        const Text(
          "Limit Reached",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        if (_dailyIntention != null) ...[
          Text(
            "\"$_dailyIntention\"",
            style: const TextStyle(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Does opening this help with your intention?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Text(
            "No note for today (optional).",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          TextButton(
            onPressed: _showGateSettings,
            child: const Text(
              "Set daily limit",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildStatsRow(),
        if (_dailyIntention != null) _buildGateSettingsLink(),
      ],
    );
  }

  void _showGateSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GateSettingsSheet(
        packageName: widget.app.packageName,
        appLabel: widget.app.name,
        initialLimitMinutes: StorageService.getAppDailyLimitMinutes(
          widget.app.packageName,
        ),
        initialIntention: _dailyIntention,
        onApply: (limit, intentionText) async {
          await StorageService.setAppDailyLimitMinutes(
            widget.app.packageName,
            limit,
          );
          if (intentionText != null && intentionText.isNotEmpty) {
            await StorageService.setDailyIntention(intentionText);
            await db.saveIntention(intentionText);
          }
          RisingTideService.invalidateIntentionCache();
          await RisingTideService.syncInterceptionState();
          await UsageService.refreshUsage();
          final newStage = RisingTideService.getStage(widget.app.packageName);
          if (!mounted) return;
          if (newStage == RisingTideStage.whisper) {
            await _launchApp();
            return;
          }
          final stats = await RisingTideService.getStats(
            widget.app.packageName,
          );
          if (mounted) {
            setState(() {
              _stage = newStage;
              _opensToday = stats['opens'] ?? 0;
              _minutesToday = stats['minutes'] ?? 0;
              _dailyIntention = RisingTideService.getDailyIntention();
            });
          }
        },
      ),
    );
  }

  Widget _buildGateSettingsLink() {
    return TextButton.icon(
      onPressed: _showGateSettings,
      icon: Icon(
        Icons.tune,
        size: 18,
        color: Colors.white.withValues(alpha: 0.4),
      ),
      label: Text(
        'Edit limit & optional note',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final limit = RisingTideService.getAppDailyLimit(
      widget.app.packageName,
    ).inMinutes;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem("Opens Today", "$_opensToday"),
        const SizedBox(width: 40),
        _buildStatItem(
          "Time vs limit",
          "${LimitTimeFormat.compact(_minutesToday)} / ${LimitTimeFormat.compact(limit)}",
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildSilenceContent() {
    if (_showTasks) {
      return Column(
        children: [
          const Text(
            "Complete a task to unlock 5m",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          if (_tasks.isEmpty)
            const Text(
              "No tasks remaining today.",
              style: TextStyle(color: Colors.white38),
            )
          else
            ..._tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () async {
                    await StorageService.completeTask(task);
                    await AppLockManager.grantUnlock(
                      widget.app.packageName,
                      minutes: 5,
                    );
                    RisingTideLogger.logTideEvent(
                      packageName: widget.app.packageName,
                      eventType: 'stage4_task_unlock',
                      stage: RisingTideStage.silence,
                      detail: task,
                    );
                    await _launchApp(afterInterceptionFlow: true);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle_outlined,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            task,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() => _showTasks = false),
            child: const Text(
              "Go back",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text(
          "Silence",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "You've chosen to stop here today.",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_dailyIntention != null) ...[
          Text(
            "\"$_dailyIntention\"",
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Text(
            "No note for today",
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildStatsRow(),
        _buildGateSettingsLink(),
      ],
    );
  }

  Widget _buildMoodSelector() {
    final moods = [
      {'label': '😌 Relaxing', 'id': 'relaxing'},
      {'label': '😤 Procrastinating', 'id': 'procrastinating'},
      {'label': '🎯 Taking a break', 'id': 'break'},
      {'label': '😶 Just habit', 'id': 'habit'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: moods.map((m) {
        final isSelected = _selectedMood == m['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedMood = m['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white12,
                width: 1,
              ),
            ),
            child: Text(
              m['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    if (_stage == RisingTideStage.silence) {
      if (_showTasks) {
        return const SizedBox(); // Action buttons hidden in task view
      }

      final bool usedUnlock = AppLockManager.hasUsedUnlockToday(
        widget.app.packageName,
      );

      return Column(
        children: [
          _buildGlassButton(
            title: "Come back tomorrow",
            onTap: () => Navigator.pop(context),
            isPrimary: true,
          ),
          if (!usedUnlock) ...[
            const SizedBox(height: 16),
            _buildGlassButton(
              title: "Complete a task to unlock 5 minutes",
              onTap: () => setState(() => _showTasks = true),
              isPrimary: false,
            ),
          ],
        ],
      );
    }

    final bool moodRequired =
        _stage == RisingTideStage.dim && _selectedMood == null;
    final bool countdownActive = _countdownSeconds > 0;
    final bool disabled = moodRequired || countdownActive;

    return Column(
      children: [
        _buildGlassButton(
          title: "Never mind, go back",
          onTap: () async {
            await RisingTideService.clearReopenLock(widget.app.packageName);
            RisingTideLogger.logDecision(
              widget.app.packageName,
              "goback",
              _selectedMood ?? "none",
            );
            if (mounted) Navigator.pop(context);
          },
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildGlassButton(
          title: countdownActive
              ? "Wait ${_countdownSeconds}s"
              : "Continue anyway",
          onTap: disabled
              ? null
              : () async {
                  RisingTideLogger.logDecision(
                    widget.app.packageName,
                    "continue",
                    _selectedMood ?? "conscious",
                  );
                  await RisingTideService.recordOverride(
                    widget.app.packageName,
                  );
                  await RisingTideService.setReopenLock(widget.app.packageName);
                  await _launchApp(afterInterceptionFlow: true);
                  if (mounted) Navigator.pop(context);
                },
          isPrimary: false,
          isDisabled: disabled,
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required String title,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isDisabled = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDisabled ? 0.3 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.white
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/storage_service.dart';
import '../services/launcher_service.dart';
import '../utils/limit_time_format.dart';
import '../widgets/daily_limit_sheet.dart';
import '../widgets/app_long_press_menu.dart';

/// Swipe in from the right — calm “breathing room” + flagged apps at a glance.
class TidePoolScreen extends StatefulWidget {
  const TidePoolScreen({super.key});

  @override
  State<TidePoolScreen> createState() => _TidePoolScreenState();
}

class _TidePoolScreenState extends State<TidePoolScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flagged = StorageService.getFlaggedApps();
    final allApps = LauncherService.cachedApps
        .where((app) => !app.packageName.contains('koralauncher'))
        .toList();

    List<AppInfo> displayApps;
    if (_searchQuery.isEmpty) {
      displayApps = allApps.where((a) => flagged.contains(a.packageName)).toList();
    } else {
      displayApps = allApps
          .where((app) => app.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        floatingActionButton: _searchQuery.isEmpty ? FloatingActionButton.extended(
          onPressed: () {
            FocusScope.of(context).requestFocus(_searchFocusNode);
          },
          label: const Text('Add App to Flag', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.cyan.withValues(alpha: 0.8),
          foregroundColor: Colors.black,
        ) : null,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020617),
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
              stops: [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Tide pool',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Text(
                    'What you give attention to, grows.\n'
                    'Use this side when you want a pause before the scroll.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.5,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search any app to flag...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.waves, color: Colors.cyanAccent, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rising Tide',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                StorageService.isRisingTideMasterEnabled()
                                    ? 'Gates are active for flagged apps'
                                    : 'Gates are off — same as home switch',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: StorageService.isRisingTideMasterEnabled(),
                          activeThumbColor: Colors.cyanAccent,
                          activeTrackColor: Colors.cyan.withValues(alpha: 0.45),
                          onChanged: (v) async {
                            await StorageService.setRisingTideMasterEnabled(v);
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _searchQuery.isEmpty ? 'FLAGGED APPS' : 'SEARCH RESULTS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 3,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: displayApps.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No apps flagged yet.\nSearch above to find an app to flag,\nor long-press an app in the drawer.'
                                : 'No apps found matching "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              height: 1.45,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: displayApps.length,
                          itemBuilder: (context, i) {
                            final app = displayApps[i];
                            final pkg = app.packageName;
                            final isFlagged = StorageService.isAppFlagged(pkg);
                            final limit = StorageService.getAppDailyLimitMinutes(pkg);
                            return Card(
                              color: isFlagged 
                                  ? Colors.cyan.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isFlagged ? Colors.cyan.withValues(alpha: 0.3) : Colors.white10,
                                ),
                              ),
                              child: ListTile(
                                leading: isFlagged 
                                    ? const Icon(Icons.waves, color: Colors.cyanAccent, size: 20)
                                    : const Icon(Icons.waves, color: Colors.white24, size: 20),
                                title: Text(
                                  app.name,
                                  style: TextStyle(
                                    color: isFlagged ? Colors.white : Colors.white70,
                                    fontWeight: isFlagged ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                subtitle: isFlagged
                                    ? Text(
                                        'Limit ${LimitTimeFormat.dualLabel(limit)}',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                                      )
                                    : Text(
                                        'Not flagged',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                                      ),
                                trailing: isFlagged
                                    ? IconButton(
                                        icon: const Icon(Icons.tune, color: Colors.white54),
                                        onPressed: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => DailyLimitSheet(
                                              packageName: app.packageName,
                                              appLabel: app.name,
                                              initialLimitMinutes: limit,
                                            ),
                                          );
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.white38),
                                        onPressed: () async {
                                          await StorageService.toggleFlaggedApp(pkg);
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                onTap: () {
                                  showAppLongPressMenu(
                                    context,
                                    app,
                                    onChanged: () => setState(() {}),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Swipe right to return home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/todo_service.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _taskController = TextEditingController();

  void _addTodo() async {
    if (_taskController.text.trim().isNotEmpty) {
      await TodoService.addTodo(_taskController.text.trim());
      _taskController.clear();
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    TodoService.init().then((_) => setState(() {}));
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
          "To-Do List",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a task...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addTodo,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TodoService.todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text(
                          "Your list is clear.",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: TodoService.todos.length,
                    itemBuilder: (context, index) {
                      final todo = TodoService.todos[index];
                      return Dismissible(
                        key: Key(todo.id.toString()),
                        onDismissed: (_) async {
                          await TodoService.deleteTodo(todo.id);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                        child: Card(
                          color: todo.isCompleted ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: IconButton(
                              icon: Icon(
                                todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: todo.isCompleted ? Colors.blueAccent : Colors.white38,
                              ),
                              onPressed: () async {
                                await TodoService.toggleTodo(todo.id);
                                setState(() {});
                              },
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                color: todo.isCompleted ? Colors.white24 : Colors.white,
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            trailing: todo.isCompleted ? null : const Icon(Icons.drag_handle, color: Colors.white12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../widgets/app_list_item.dart';
import '../services/storage_service.dart';
import '../services/native_service.dart';
import '../widgets/app_long_press_menu.dart';
import 'interception_screen.dart';
import 'package:android_intent_plus/android_intent.dart';

class UsageDashboardScreen extends StatefulWidget {
  const UsageDashboardScreen({super.key});

  @override
  State<UsageDashboardScreen> createState() => _UsageDashboardScreenState();
}

class _UsageDashboardScreenState extends State<UsageDashboardScreen> {
  List<AppInfo> _sortedApps = [];
  bool _isLoading = true;
  bool _hasUsagePermission = true;

  int _roundedMinutesForApp(String packageName) {
    return (UsageService.getAppUsage(packageName).inMilliseconds + 30000) ~/ 60000;
  }

  Duration _computeTotal() {
    return UsageService.getVisibleTotalUsage(minRoundedMinutes: 1);
  }

  @override
  void initState() {
    super.initState();
    _loadDashBoardData();
  }

  Future<void> _loadDashBoardData() async {
    final hasPermission = await NativeService.hasUsagePermission();
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
        _sortedApps = apps
            .where((app) => _roundedMinutesForApp(app.packageName) >= 1)
            .toList();
        _hasUsagePermission = hasPermission;
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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white24),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_hasUsagePermission) _buildUsagePermissionBanner(),
                  _buildSummaryHeader(totalUsage),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "APP USAGE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
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
        color: Colors.white.withValues(alpha: 0.05),
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
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
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
        color: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildUsagePermissionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.show_chart, size: 24, color: Colors.white),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Enable usage stats for insights",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    "Usage Access Required",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Kora Launcher requires 'Usage Access' permission to monitor which apps you open and for how long.\n\n"
                    "This allows the Rising Tide system to intercept habit-building apps, measure your screen time accurately, and help you reduce distractions.\n\n"
                    "Your usage data strictly stays on your device and is never sent to any servers.",
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await NativeService.openUsageSettings();
                        _loadDashBoardData();
                      },
                      child: const Text(
                        "I Understand",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              "ENABLE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class LauncherService {
  static List<AppInfo> _cachedApps = [];
  static bool _isInitialized = false;


  static List<AppInfo> get cachedApps => _cachedApps;
  static bool get isInitialized => _isInitialized;

  static Future<void> init() async {
    await refreshApps();
    _isInitialized = true;
  }

  static Future<void> refreshApps() async {
    // Get all apps that have a launch intent
    final appsAll = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );

    final byPackage = <String, AppInfo>{};
    for (final app in appsAll) {
      // Exclude our own launcher
      if (app.packageName != 'org.korelium.koralauncher' && 
          app.packageName != 'com.koralauncher.app') {
        byPackage[app.packageName] = app;
      }
    }

    final merged = byPackage.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cachedApps = merged;
  }

  static Future<void> launchApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }
}
import 'package:shared_preferences/shared_preferences.dart';

class AppLockManager {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _localDayKey(DateTime now) {
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Grants a temporary unlock for a package
  static Future<void> grantUnlock(String packageName, {required int minutes}) async {
    final today = _localDayKey(DateTime.now());
    final key = 'task_unlock_${packageName}_$today';
    final unlockUntil = DateTime.now().add(Duration(minutes: minutes)).millisecondsSinceEpoch;
    
    await _prefs.setInt(key, unlockUntil);
    // Also mark that an unlock was used today so it can't be used again
    await _prefs.setBool('${key}_used', true);
  }

  /// Checks if a temporary unlock is currently active
  static bool hasActiveUnlock(String packageName) {
    final today = _localDayKey(DateTime.now());
    final key = 'task_unlock_${packageName}_$today';
    final unlockUntil = _prefs.getInt(key);
    
    if (unlockUntil != null && DateTime.now().millisecondsSinceEpoch < unlockUntil) {
      return true;
    }
    return false;
  }

  /// Checks if the user has already used their one unlock for today
  static bool hasUsedUnlockToday(String packageName) {
    final today = _localDayKey(DateTime.now());
    final key = 'task_unlock_${packageName}_$today';
    return _prefs.getBool('${key}_used') ?? false;
  }
}
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
import '../database/database_provider.dart';
import '../models/rising_tide_stage.dart';

class RisingTideLogger {
  /// Logs a Rising Tide event to the database.
  static Future<void> logTideEvent({
    String? packageName,
    required String eventType,
    String? detail,
    RisingTideStage? stage,
  }) async {
    await db.logTideEvent(
      packageName: packageName,
      eventType: eventType,
      detail: detail,
      stage: stage?.index,
    );
  }

  // Helper methods for common events

  static Future<void> logIntentionSet(String intention) async {
    await logTideEvent(
      eventType: 'intention_set',
      detail: intention,
    );
  }

  static Future<void> logAppOpen(String packageName, RisingTideStage stage) async {
    await logTideEvent(
      packageName: packageName,
      eventType: 'app_open_stage${stage.index + 1}',
      stage: stage,
    );
  }

  static Future<void> logDecision(String packageName, String decision, String mood) async {
    await logTideEvent(
      packageName: packageName,
      eventType: 'decision_$decision',
      detail: 'mood:$mood',
    );
  }
}
import '../models/rising_tide_stage.dart';
import 'usage_service.dart';
import 'storage_service.dart';
import 'native_service.dart';
import 'app_lock_manager.dart';

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

    final interceptedPackages = <String>[];
    // This is a placeholder for getting all apps - we should ideally check all launchable apps
    // for now we'll just check flagged ones.
    for (final packageName in StorageService.getFlaggedApps()) {
      if (getStage(packageName) != RisingTideStage.whisper) {
        interceptedPackages.add(packageName);
      }
    }
    await NativeService.sendBlockedApps(interceptedPackages);
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
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'native_service.dart';
import 'launcher_service.dart';

class KoraUsageInfo {
  final String packageName;
  final Duration usage;
  KoraUsageInfo({required this.packageName, required this.usage});
}

class UsageService {
  static List<KoraUsageInfo> _usageInfos = [];
  
  static List<KoraUsageInfo> get usageInfos => _usageInfos;

  static Future<void> refreshUsage() async {
    if (!Platform.isAndroid) return;
    
    try {
      bool hasPermission = await NativeService.hasUsagePermission();
      if (!hasPermission) return; 

      DateTime endDate = DateTime.now();
      DateTime startDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      Map<String, int> rawStats = await NativeService.getRawUsageStats(
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      );
      
      List<KoraUsageInfo> infoList = [];
      rawStats.forEach((package, millis) {
        infoList.add(KoraUsageInfo(packageName: package, usage: Duration(milliseconds: millis)));
      });
      _usageInfos = infoList;
    } catch (exception, stackTrace) {
      debugPrint("UsageService Exception: $exception\n$stackTrace");
    }
  }

  static Duration getAppUsage(String packageName) {
    for (var info in _usageInfos) {
      if (info.packageName == packageName) {
        return info.usage;
      }
    }
    return Duration.zero;
  }

  /// Rounded minutes today for [packageName] (matches Digital Wellbeing–style rounding).
  /// Use this for UI and Rising Tide so stats match [getStage].
  static int getRoundedMinutesToday(String packageName) {
    if (!shouldCountPackage(packageName)) return 0;
    return _roundedMinutes(getAppUsage(packageName));
  }

  static int _roundedMinutes(Duration duration) {
    // Round half-up to match typical "screen time" rounding in dashboards.
    // Digital Wellbeing usually rounds to the nearest minute (not floor).
    return (duration.inMilliseconds + 30000) ~/ 60000;
  }

  static bool shouldCountPackage(String packageName) {
    if (packageName.contains('koralauncher')) return false;
    return true;
  }

  static Duration getVisibleTotalUsage({int minRoundedMinutes = 1}) {
    int totalMinutes = 0;
    // We only count apps that are in our launcher (launchable by user)
    // and aren't explicitly ignored (like system processes).
    for (final app in LauncherService.cachedApps) {
      if (!shouldCountPackage(app.packageName)) continue;

      final usage = getAppUsage(app.packageName);
      final minutes = _roundedMinutes(usage);
      if (minutes >= minRoundedMinutes) {
        totalMinutes += minutes;
      }
    }
    return Duration(minutes: totalMinutes);
  }

  static Duration getTotalUsage() {
    Duration total = Duration.zero;
    final cachedPackages = LauncherService.cachedApps.map((a) => a.packageName).toSet();
    final Map<String, Duration> uniqueUsage = {};

    for (var info in _usageInfos) {
      if (cachedPackages.contains(info.packageName) && 
          !info.packageName.contains('koralauncher')) {
        
        // Handle overlapping daily buckets bug in app_usage by taking the maximum payload
        if (!uniqueUsage.containsKey(info.packageName) || info.usage > uniqueUsage[info.packageName]!) {
            uniqueUsage[info.packageName] = info.usage;
        }
      }
    }
    
    uniqueUsage.forEach((_, duration) {
       total += duration;
    });

    return total;
  }

  static String formatDuration(Duration duration) {
    final totalMinutes = _roundedMinutes(duration);
    if (totalMinutes <= 0) return "0m";

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';

import '../app_navigator.dart';
import '../models/rising_tide_stage.dart';
import '../screens/interception_screen.dart';
import 'foreground_intercept_guard.dart';
import 'launcher_service.dart';
import 'rising_tide_service.dart';
import 'storage_service.dart';
import 'usage_service.dart';

class NativeService {
  static const platform = MethodChannel('com.koralauncher.app/native');

  static const String _launcherPackage = 'org.korelium.koralauncher';

  /// Handles [MethodCall]s from Android (e.g. [AccessibilityWatcherService]).
  static void initMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onAppForeground') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final packageName = args?['package'] as String?;
        if (packageName != null) {
          await _onForegroundApp(packageName);
        }
      } else if (call.method == 'onPackageChanged') {
        await LauncherService.refreshApps();
      }
    });
  }

  static String? _lastInterceptPackage;
  static DateTime? _lastInterceptAt;

  static Future<void> _onForegroundApp(String packageName) async {
    if (packageName == _launcherPackage) return;
    if (!StorageService.isAppFlagged(packageName)) return;
    if (ForegroundInterceptGuard.shouldSkipForPackage(packageName)) return;

    await UsageService.refreshUsage();
    final stage = RisingTideService.getStage(packageName);
    if (stage == RisingTideStage.whisper) return;

    final now = DateTime.now();
    if (_lastInterceptPackage == packageName &&
        _lastInterceptAt != null &&
        now.difference(_lastInterceptAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInterceptPackage = packageName;
    _lastInterceptAt = now;

    final app = await _findAppInfo(packageName);
    if (app == null) return;

    // Let MainActivity come to front before pushing (started from accessibility).
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (!nav.mounted) return;

    await nav.push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InterceptionScreen(app: app),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  static Future<AppInfo?> _findAppInfo(String packageName) async {
    for (final a in LauncherService.cachedApps) {
      if (a.packageName == packageName) return a;
    }
    await LauncherService.refreshApps();
    for (final a in LauncherService.cachedApps) {
      if (a.packageName == packageName) return a;
    }
    return null;
  }

  static Future<bool> isDefaultLauncher() async {
    try {
      final bool result = await platform.invokeMethod<bool>('isDefaultLauncher') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod<bool>('hasUsagePermission') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasAccessibilityPermission() async {
    try {
      final bool result = await platform.invokeMethod<bool>('hasAccessibilityPermission') ?? false;
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await platform.invokeMethod('openUsageSettings');
    } catch (e) {
      print("Failed to open usage settings.");
    }
  }

  static Future<void> openDefaultLauncherSettings() async {
    try {
      await platform.invokeMethod('openDefaultLauncherSettings');
    } catch (e) {
      print("Failed: $e");
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print("Failed: $e");
    }
  }

  static Future<void> lockScreen() async {
    try {
      await platform.invokeMethod('lockScreen');
    } catch (e) {
      print("Failed to lock screen: $e");
    }
  }

  static Future<Map<String, int>> getRawUsageStats(int startTime, int endTime) async {
    try {
      final Map<dynamic, dynamic>? result = await platform.invokeMethod('getRawUsageStats', {
        'startTime': startTime,
        'endTime': endTime,
      });
      if (result == null) return {};
      return result.map((key, value) => MapEntry(key.toString(), int.parse(value.toString())));
    } catch (e) {
      return {};
    }
  }

  static Future<void> sendBlockedApps(List<String> packages) async {
    try {
      await platform.invokeMethod('sendBlockedApps', {'packages': packages});
    } catch (e) {
      print("NativeService Error: $e");
    }
  }
}
import 'package:shared_preferences/shared_preferences.dart';
import 'rising_tide_service.dart';

class StorageService {
  static const String _flaggedAppsKey = 'flagged_apps';
  static const String _risingTideMasterKey = 'rising_tide_master_enabled';
  static const int _defaultDailyLimitMinutes = 10;
  static const String _appLimitPrefix = 'rt_limit_minutes_';
  static const String _todayOpensPrefix = 'rt_opens_';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String _localDayKey(DateTime now) {
    // Digital Wellbeing uses device local time for day boundaries.
    // Avoid UTC date strings from `toIso8601String()`, which can shift the day.
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static List<String> getFlaggedApps() {
    return _prefs.getStringList(_flaggedAppsKey) ?? [];
  }

  static Future<void> toggleFlaggedApp(String packageName) async {
    final apps = getFlaggedApps().toList();
    if (apps.contains(packageName)) {
      apps.remove(packageName);
    } else {
      apps.add(packageName);
    }
    await _prefs.setStringList(_flaggedAppsKey, apps);
    
    // Sync state to native Accessibility service
    await RisingTideService.syncInterceptionState();
  }

  static bool isAppFlagged(String packageName) {
    return getFlaggedApps().contains(packageName);
  }

  /// Master switch: when false, Rising Tide gates are off for every app.
  static bool isRisingTideMasterEnabled() {
    return _prefs.getBool(_risingTideMasterKey) ?? true;
  }

  static Future<void> setRisingTideMasterEnabled(bool enabled) async {
    await _prefs.setBool(_risingTideMasterKey, enabled);
    await RisingTideService.syncInterceptionState();
  }

  // --- Per-app daily time limit (Rising Tide) ---

  static int getAppDailyLimitMinutes(String packageName) {
    return _prefs.getInt('$_appLimitPrefix$packageName') ?? _defaultDailyLimitMinutes;
  }

  static Future<void> setAppDailyLimitMinutes(String packageName, int minutes) async {
    final m = minutes.clamp(1, 24 * 60);
    await _prefs.setInt('$_appLimitPrefix$packageName', m);
  }

  // --- Opens today (gate visits + whisper launches) ---

  static String _todayOpensKey(String packageName) {
    return '$_todayOpensPrefix${_localDayKey(DateTime.now())}_$packageName';
  }

  static int getTodayOpenCount(String packageName) {
    return _prefs.getInt(_todayOpensKey(packageName)) ?? 0;
  }

  static Future<void> incrementTodayOpenCount(String packageName) async {
    final key = _todayOpensKey(packageName);
    final next = (_prefs.getInt(key) ?? 0) + 1;
    await _prefs.setInt(key, next);
  }

  static String? getDailyIntention() {
    final today = _localDayKey(DateTime.now());
    return _prefs.getString('intention_$today');
  }

  static Future<void> setDailyIntention(String intention) async {
    final today = _localDayKey(DateTime.now());
    await _prefs.setString('intention_$today', intention);
  }

  static bool hasSetIntentionToday() {
    return getDailyIntention() != null;
  }

  static bool isMinimalMode() {
    return _prefs.getBool('minimal_mode') ?? false;
  }

  static Future<void> setMinimalMode(bool value) async {
    await _prefs.setBool('minimal_mode', value);
  }

  static String? getString(String key) => _prefs.getString(key);
  
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // --- Onboarding ---
  static bool hasCompletedOnboarding() {
    return _prefs.getBool('has_completed_onboarding') ?? false;
  }

  static Future<void> completeOnboarding() async {
    await _prefs.setBool('has_completed_onboarding', true);
  }

  // --- Task Mock Methods ---
  static List<String> getTodayTasks() {
    // Simulated tasks for now. Later can be tied to a database or intentional to-do list.
    final tasks = _prefs.getStringList('mock_tasks');
    if (tasks == null) {
      final defaultTasks = [
        "Drink a glass of water",
        "Take 5 deep breaths",
        "Stretch for 2 minutes",
        "Jot down 1 thing you are grateful for"
      ];
      _prefs.setStringList('mock_tasks', defaultTasks);
      return defaultTasks;
    }
    return tasks;
  }

  static Future<void> completeTask(String task) async {
    final tasks = getTodayTasks();
    tasks.remove(task);
    await _prefs.setStringList('mock_tasks', tasks);
  }
}

import '../database/database_provider.dart';
import '../database/kora_database.dart';

class TodoService {
  static final List<Todo> _todos = [];
  
  static List<Todo> get todos => _todos;

  static Future<void> init() async {
    await refreshTodos();
  }

  static Future<void> refreshTodos() async {
    final list = await db.getTodos();
    final today = DateTime.now();
    
    // Nightly Reset Logic: purge tasks not from today
    for (var t in list) {
      if (t.createdAt.year != today.year || 
          t.createdAt.month != today.month || 
          t.createdAt.day != today.day) {
        await db.deleteTodo(t.id);
      }
    }
    
    // Refetch the purged list
    final finalList = await db.getTodos();
    _todos.clear();
    _todos.addAll(finalList);
  }

  static Future<void> addTodo(String title, {int priority = 0}) async {
    await db.addTodo(title, priority: priority);
    await refreshTodos();
  }

  static Future<void> toggleTodo(int id) async {
    await db.toggleTodo(id);
    await refreshTodos();
  }

  static Future<void> deleteTodo(int id) async {
    await db.deleteTodo(id);
    await refreshTodos();
  }

  static int get pendingCount => _todos.where((t) => !t.isCompleted).length;
  
  static bool hasPendingTodos() => pendingCount > 0;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF90CAF9); // Soft blue, anime sky
  static const Color backgroundColor = Color(0xFF0F172A); // Deep slate
  static const Color surfaceColor = Color(0xFF1E293B);
  static const Color textPrimaryColor = Color(0xFFF8FAFC);
  static const Color textSecondaryColor = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
        surface: const Color(0xFF0F172A),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimaryColor),
        bodyLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimaryColor),
        bodyMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textSecondaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
    );
  }
}
import 'dart:math';
import 'package:flutter/material.dart';

class MicroHabit {
  final String title;
  final String description;
  final IconData icon;

  MicroHabit({required this.title, required this.description, required this.icon});
}

class MicroHabitSuggestion extends StatefulWidget {
  final VoidCallback onDismiss;

  const MicroHabitSuggestion({super.key, required this.onDismiss});

  @override
  State<MicroHabitSuggestion> createState() => _MicroHabitSuggestionState();
}

class _MicroHabitSuggestionState extends State<MicroHabitSuggestion> {
  late final MicroHabit _selectedHabit;

  final List<MicroHabit> _habits = [
    MicroHabit(
      title: "Box Breathing",
      description: "Inhale for 4s, hold for 4s, exhale for 4s, hold for 4s. Repeat 3 times.",
      icon: Icons.air,
    ),
    MicroHabit(
      title: "Quick Stretch",
      description: "Reach for the sky for 10 seconds, then touch your toes. Shake it off.",
      icon: Icons.accessibility_new,
    ),
    MicroHabit(
      title: "Micro-Journal",
      description: "Think of one thing you are genuinely grateful for right now.",
      icon: Icons.edit_note,
    ),
    MicroHabit(
      title: "Hydrate",
      description: "Take a slow sip of water. Feel it cool your throat.",
      icon: Icons.local_drink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedHabit = _habits[Random().nextInt(_habits.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_selectedHabit.icon, size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            _selectedHabit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedHabit.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: widget.onDismiss,
            child: const Text("I'm done", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
import 'package:installed_apps/app_info.dart';
import 'package:flutter/material.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  /// Quick Rising Tide toggle — tap the wave icon (optional).
  final VoidCallback? onFlagTap;
  final bool isFlagged;
  final Duration usage;

  const AppListItem({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
    this.onFlagTap,
    this.isFlagged = false,
    this.usage = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isFlagged 
            ? Theme.of(context).primaryColor.withValues(alpha: 0.15) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isFlagged
            ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: app.packageName,
                    child: app.icon != null
                        ? Image.memory(app.icon!, fit: BoxFit.cover)
                        : const Icon(Icons.apps),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  app.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onFlagTap != null) ...[
                IconButton(
                  tooltip: isFlagged ? 'Rising Tide on — tap to turn off' : 'Mark for Rising Tide',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(
                    Icons.waves,
                    size: 24,
                    color: isFlagged
                        ? Theme.of(context).primaryColor
                        : Colors.white38,
                  ),
                  onPressed: onFlagTap,
                ),
              ],
              if (usage != Duration.zero) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    "${_formatUsage(usage)} today",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isFlagged && onFlagTap == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline, color: Theme.of(context).primaryColor, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "FLAGGED",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatUsage(Duration d) {
    final totalMinutes = (d.inMilliseconds + 30000) ~/ 60000; // round half-up
    if (totalMinutes <= 0) return "0m";

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../services/storage_service.dart';
import 'daily_limit_sheet.dart';

/// Shared long-press menu: app info, daily limit, Rising Tide switch.
void showAppLongPressMenu(
  BuildContext context,
  AppInfo app, {
  required VoidCallback onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final flagged = StorageService.isAppFlagged(app.packageName);
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      app.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.white70),
                    title: const Text('App info', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'System settings for this app',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await AndroidIntent(
                        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                        data: 'package:${app.packageName}',
                        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                      ).launch();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.white70),
                    title: const Text('Set daily limit', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Rising Tide budget for this app',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DailyLimitSheet(
                          packageName: app.packageName,
                          appLabel: app.name,
                          initialLimitMinutes: StorageService.getAppDailyLimitMinutes(
                            app.packageName,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: flagged
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: flagged
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.85)
                            : Colors.white24,
                        width: flagged ? 2 : 1,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Rising Tide on this app',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: flagged ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        flagged
                            ? 'Pause and ask before opening'
                            : 'Tap to pause before you open',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                      value: flagged,
                      activeThumbColor: Theme.of(context).primaryColor,
                      activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white12,
                      onChanged: (v) async {
                        if (StorageService.isAppFlagged(app.packageName) != v) {
                          await StorageService.toggleFlaggedApp(app.packageName);
                        }
                        setModalState(() {});
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
import 'package:flutter/material.dart';
import '../utils/limit_time_format.dart';

/// Returns true if user confirms a high daily limit.
Future<bool> showHighLimitConfirmDialog(
  BuildContext context,
  int limitMinutes,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'That is a large slice of your day',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You chose ${LimitTimeFormat.compact(limitMinutes)} ($limitMinutes min) for this app.',
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 16),
            const Text(
              'Long sessions here can quietly eat your focus, your evening, and your sleep. '
              'Before you save: is this limit really worth it for you today?',
              style: TextStyle(color: Colors.white60, height: 1.45, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Pick a smaller limit',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('I still want this limit'),
        ),
      ],
    ),
  );
  return result ?? false;
}
import 'dart:async';
import 'package:flutter/material.dart';

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Update every 50ms for smooth millisecond display rendering
    // High update rate is okay since this is a tiny widget and flutter handles dirty-checking well
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  String _formatTime() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");

    String h = twoDigits(_now.hour);
    String m = twoDigits(_now.minute);
    String s = twoDigits(_now.second);
    // Use first two digits of milliseconds for UI stability (00-99 instead of 000-999)
    String ms = threeDigits(_now.millisecond).substring(0, 2); 
    String tz = _now.timeZoneName;

    return "$h:$m:$s:$ms $tz";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
            height: 1.0,
            shadows: const [Shadow(blurRadius: 15, color: Colors.black87)],
          ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rising_tide_service.dart';
import '../utils/limit_time_format.dart';
import 'high_limit_confirm_dialog.dart';

/// Daily time limit for one app — shows hours + minutes, warns above 4h.
class DailyLimitSheet extends StatefulWidget {
  const DailyLimitSheet({
    super.key,
    required this.packageName,
    required this.appLabel,
    required this.initialLimitMinutes,
  });

  final String packageName;
  final String appLabel;
  final int initialLimitMinutes;

  @override
  State<DailyLimitSheet> createState() => _DailyLimitSheetState();
}

class _DailyLimitSheetState extends State<DailyLimitSheet> {
  late TextEditingController _limitController;
  int _currentLimit = 5;

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.initialLimitMinutes.clamp(1, 1440);
    _limitController = TextEditingController(text: _currentLimit.toString());
    
    _limitController.addListener(() {
      final val = int.tryParse(_limitController.text);
      if (val != null && val != _currentLimit) {
        setState(() {
          _currentLimit = val.clamp(1, 1440);
        });
      }
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final m = _currentLimit;
    if (LimitTimeFormat.needsHighLimitConfirm(m)) {
      final ok = await showHighLimitConfirmDialog(context, m);
      if (!ok || !mounted) return;
    }
    await StorageService.setAppDailyLimitMinutes(widget.packageName, m);
    await RisingTideService.syncInterceptionState();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final m = _currentLimit;
    final soft = LimitTimeFormat.showsSoftLimitWarning(m);
    final hard = LimitTimeFormat.needsHighLimitConfirm(m);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.appLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily time limit',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  LimitTimeFormat.dualLabel(m),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: hard
                        ? Colors.deepOrange.shade200
                        : soft
                            ? Colors.amber.shade200
                            : Colors.white,
                  ),
                ),
                if (soft) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hard
                          ? Colors.deepOrange.withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hard
                            ? Colors.deepOrange.withValues(alpha: 0.45)
                            : Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      hard
                          ? 'That is more than 4 hours in one app. Long blocks can quietly consume your whole day — you will be asked to confirm when you save.'
                          : '4 hours or more: a large share of your waking day. Make sure this limit matches what you really want.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                // Time Display Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: hard ? Colors.deepOrange.shade300 : soft ? Colors.amber.shade300 : Colors.white,
                          letterSpacing: -1,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Rising Tide uses 50% / 100% / 200% of this limit for stages.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: hard
                        ? Colors.deepOrange.shade700
                        : Colors.white,
                    foregroundColor: hard ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    hard ? 'Save (confirm if needed)' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../utils/limit_time_format.dart';
import 'high_limit_confirm_dialog.dart';

/// Bottom sheet: daily time limit and optional note for Rising Tide.
class GateSettingsSheet extends StatefulWidget {
  const GateSettingsSheet({
    super.key,
    required this.packageName,
    required this.appLabel,
    required this.initialLimitMinutes,
    this.initialIntention,
    required this.onApply,
  });

  final String packageName;
  final String appLabel;
  final int initialLimitMinutes;
  final String? initialIntention;
  final Future<void> Function(int limitMinutes, String? intentionText) onApply;

  @override
  State<GateSettingsSheet> createState() => _GateSettingsSheetState();
}

class _GateSettingsSheetState extends State<GateSettingsSheet> {
  late TextEditingController _limitController;
  late TextEditingController _intentionController;
  int _currentLimit = 5;

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.initialLimitMinutes.clamp(1, 1440);
    _limitController = TextEditingController(text: _currentLimit.toString());
    _intentionController = TextEditingController(text: widget.initialIntention ?? '');
    
    _limitController.addListener(() {
      final val = int.tryParse(_limitController.text);
      if (val != null && val != _currentLimit) {
        setState(() {
          _currentLimit = val.clamp(1, 1440);
        });
      }
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final m = _currentLimit;
    final soft = LimitTimeFormat.showsSoftLimitWarning(m);
    final hard = LimitTimeFormat.needsHighLimitConfirm(m);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.appLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your daily boundary',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Time Display Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: hard ? Colors.deepOrange.shade300 : soft ? Colors.amber.shade300 : Colors.white,
                          letterSpacing: -1,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  LimitTimeFormat.dualLabel(m),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                if (soft) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hard
                          ? Colors.deepOrange.withValues(alpha: 0.1)
                          : Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hard
                            ? Colors.deepOrange.withValues(alpha: 0.3)
                            : Colors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: hard ? Colors.deepOrange.shade300 : Colors.amber.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hard
                                ? 'Very high limit. You will need to confirm twice.'
                                : 'High usage detected. This is a large part of your day.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                Text(
                  'NOTATION (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _intentionController,
                  maxLines: 2,
                  maxLength: 120,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Why do you need this app today?',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    filled: true,
                    counterStyle: const TextStyle(color: Colors.white24),
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    final limit = _currentLimit;
                    if (LimitTimeFormat.needsHighLimitConfirm(limit)) {
                      final ok = await showHighLimitConfirmDialog(context, limit);
                      if (!ok || !context.mounted) return;
                    }
                    final text = _intentionController.text.trim();
                    await widget.onApply(
                      limit,
                      text.isEmpty ? null : text,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: hard ? Colors.deepOrange.shade700 : Colors.white,
                    foregroundColor: hard ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hard ? 'Confirm & Save' : 'Set Limit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rising_tide_service.dart';
import '../database/database_provider.dart';

class GoalSetter extends StatefulWidget {
  final VoidCallback onGoalSet;
  final VoidCallback? onDismiss;
  final String? initialGoal;

  const GoalSetter({super.key, required this.onGoalSet, this.onDismiss, this.initialGoal});

  @override
  State<GoalSetter> createState() => _GoalSetterState();
}

class _GoalSetterState extends State<GoalSetter> {
  late TextEditingController _controller;
  bool _canSkip = false;
  bool _isFirstRun = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal);
    _isFirstRun = !StorageService.hasCompletedOnboarding();
    
    if (widget.onDismiss != null) {
      if (_isFirstRun) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _canSkip = true;
            });
          }
        });
      } else {
        _canSkip = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_controller.text.trim().isNotEmpty) {
      if (_isFirstRun) await StorageService.completeOnboarding();
      // Keep internal storage for fast retrieval
      await StorageService.setDailyIntention(_controller.text.trim());
      // Save to Drift DB for pattern analysis
      await db.saveIntention(_controller.text.trim());
      RisingTideService.invalidateIntentionCache();
      widget.onGoalSet();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning.";
    } else if (hour < 17) {
      return "Good Afternoon.";
    } else {
      return "Good Evening.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "What is your primary goal for today?",
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "e.g. Finish my project",
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const Divider(color: Colors.white24, height: 32),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Set Goal", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                if (widget.onDismiss != null) ...[
                  const SizedBox(height: 12),
                  if (_canSkip)
                    TextButton(
                      onPressed: () async {
                        if (_isFirstRun) await StorageService.completeOnboarding();
                        widget.onDismiss!();
                      },
                      child: Text(
                        "Skip for now", 
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                      ),
                    )
                  else
                    const SizedBox(height: 36), // preserve same height
                ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/todo_service.dart';

class TodoListCard extends StatefulWidget {
  final VoidCallback onTap;

  const TodoListCard({super.key, required this.onTap});

  @override
  State<TodoListCard> createState() => _TodoListCardState();
}

class _TodoListCardState extends State<TodoListCard> {
  @override
  Widget build(BuildContext context) {
    final todos = TodoService.todos;
    final total = todos.length;
    final completed = todos.where((t) => t.isCompleted).length;
    final pending = total - completed;

    String motivationMessage = "No tasks yet. Tap to add.";
    if (total > 0) {
      if (completed == total) {
        motivationMessage = "All done! 🎉";
      } else if (completed > 0) {
        motivationMessage = "$completed/$total done. $pending remaining.";
      } else {
        motivationMessage = "$total tasks today. Let's start.";
      }
    }

    return GestureDetector(
      onTap: widget
          .onTap, // Still allow tap on the card header to open full screen
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "TO-DO LIST",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 2,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$pending pending",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtle Progress Bar
            if (total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),

            // Motivational Message
            Text(
              motivationMessage,
              style: TextStyle(
                color: completed == total && total > 0
                    ? Colors.greenAccent
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: completed == total && total > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable List of Tasks
            if (todos.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: todos.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          await TodoService.toggleTodo(todo.id);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: todo.isCompleted
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: todo.isCompleted
                                  ? Colors.transparent
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                todo.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: todo.isCompleted
                                    ? Colors.greenAccent
                                    : Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  todo.title,
                                  style: TextStyle(
                                    color: todo.isCompleted
                                        ? Colors.white38
                                        : Colors.white,
                                    fontSize: 15,
                                    decoration: todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'kora_database.dart';

// Fix — lazy singleton
KoraDatabase? _dbInstance;
KoraDatabase get db {
  _dbInstance ??= KoraDatabase();
  return _dbInstance!;
}import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'kora_database.g.dart';

// ─────────────────────────────────────────────
// TABLE 1: SESSIONS
// Every time user opens a flagged app.
// Powers: Rising Tide timer, open count, AI context
// ─────────────────────────────────────────────
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get openReason => text().nullable()(); // 'habit','quick_task','important'
  IntColumn get extensionCount => integer().withDefault(const Constant(0))();
  BoolColumn get didResist => boolean().withDefault(const Constant(false))();
  IntColumn get risingTideStageReached => integer().withDefault(const Constant(0))(); // 0-4
}

// ─────────────────────────────────────────────
// TABLE 2: MOODS
// Lightweight emoji check-in before/after sessions.
// Powers: emotion → usage correlation (the invisible trigger)
// ─────────────────────────────────────────────
class Moods extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  IntColumn get score => integer()(); // 1-5 (1=terrible, 5=great)
  TextColumn get label => text().nullable()(); // 'stressed','bored','lonely','fine'
  TextColumn get context => text().nullable()(); // 'before_session','morning','evening'
  IntColumn get sessionId => integer().nullable()(); // FK to sessions if linked
}

// ─────────────────────────────────────────────
// TABLE 3: DECISIONS
// Every interception gate outcome.
// Powers: resist rate tracking, AI prompt personalization
// ─────────────────────────────────────────────
class Decisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get decidedAt => dateTime()();
  TextColumn get packageName => text()();
  TextColumn get reason => text()(); // 'habit','quick_task','important'
  BoolColumn get opened => boolean()(); // true = opened anyway
  BoolColumn get resistedCompletely => boolean().withDefault(const Constant(false))();
  BoolColumn get tookAlternative => boolean().withDefault(const Constant(false))(); // took micro-habit
  TextColumn get extensionReason => text().nullable()(); // typed reason for Stage 3 extension
}

// ─────────────────────────────────────────────
// TABLE 4: INTENTIONS
// Daily intention + whether it was honoured.
// Powers: intention vs usage correlation, AI weekly insight
// ─────────────────────────────────────────────
class Intentions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get intentionText => text()();
  BoolColumn get wasHonoured => boolean().nullable()(); // set at end of day
  IntColumn get totalScreenMinutesThatDay => integer().nullable()(); // filled by end-of-day job
  TextColumn get morningMoodLabel => text().nullable()(); // from first mood log of day
}

// ─────────────────────────────────────────────
// TABLE 5: TIDE EVENTS
// Granular audit log for every Rising Tide event.
// Powers: 30-day insights, pattern detection
// ─────────────────────────────────────────────
class TideEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get packageName => text().nullable()();
  TextColumn get eventType => text()(); // 'intention_set', 'app_open_stage1', etc.
  TextColumn get detail => text().nullable()(); // 'mood:bored', 'decision:continue'
  IntColumn get stage => integer().nullable()(); // 0-4
}

// ─────────────────────────────────────────────
// TABLE 6: TODOS
// Powers: daily task list, linked to goals
// ─────────────────────────────────────────────
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))(); // 0=none, 1=low, 2=med, 3=high
}

// ─────────────────────────────────────────────
// DATABASE CLASS
// ─────────────────────────────────────────────
@DriftDatabase(tables: [Sessions, Moods, Decisions, Intentions, TideEvents, Todos])
class KoraDatabase extends _$KoraDatabase {
  KoraDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // ── SESSION QUERIES ──────────────────────

  Future<int> startSession(String packageName, String appName) =>
      into(sessions).insert(SessionsCompanion.insert(
        packageName: packageName,
        appName: appName,
        startedAt: DateTime.now(),
      ));

  Future<void> endSession(int id, int durationSeconds, {
    int risingTideStage = 0,
    bool didResist = false,
  }) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(
          endedAt: Value(DateTime.now()),
          durationSeconds: Value(durationSeconds),
          risingTideStageReached: Value(risingTideStage),
          didResist: Value(didResist),
        ),
      );

  Future<void> incrementExtension(int id) async {
    final session = await (select(sessions)..where((s) => s.id.equals(id))).getSingle();
    await (update(sessions)..where((s) => s.id.equals(id))).write(
      SessionsCompanion(extensionCount: Value(session.extensionCount + 1)),
    );
  }

  Future<int> getTodayOpenCount(String packageName) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final result = await (select(sessions)
          ..where((s) =>
              s.packageName.equals(packageName) &
              s.startedAt.isBiggerOrEqualValue(start)))
        .get();
    return result.length;
  }

  Future<int> getTodayTotalMinutes(String packageName) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final result = await (select(sessions)
          ..where((s) =>
              s.packageName.equals(packageName) &
              s.startedAt.isBiggerOrEqualValue(start) &
              s.durationSeconds.isNotNull()))
        .get();
    
    int totalSeconds = 0;
    for (var s in result) {
      totalSeconds += s.durationSeconds ?? 0;
    }
    return (totalSeconds / 60).round();
  }

  Future<List<Session>> getSessionsForAIContext(String packageName, {int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (select(sessions)
          ..where((s) =>
              s.packageName.equals(packageName) &
              s.startedAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  // ── DECISION QUERIES ─────────────────────

  Future<int> logDecision({
    required String packageName,
    required String reason,
    required bool opened,
    bool resistedCompletely = false,
    bool tookAlternative = false,
    String? extensionReason,
  }) =>
      into(decisions).insert(DecisionsCompanion.insert(
        decidedAt: DateTime.now(),
        packageName: packageName,
        reason: reason,
        opened: opened,
        resistedCompletely: Value(resistedCompletely),
        tookAlternative: Value(tookAlternative),
        extensionReason: Value(extensionReason),
      ));

  Future<double> getResistRate(String packageName, {int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final all = await (select(decisions)
          ..where((d) =>
              d.packageName.equals(packageName) &
              d.decidedAt.isBiggerOrEqualValue(cutoff)))
        .get();
    if (all.isEmpty) return 0.0;
    final resisted = all.where((d) => !d.opened).length;
    return resisted / all.length;
  }

  // ── MOOD QUERIES ─────────────────────────

  Future<int> logMood({
    required int score,
    String? label,
    String? context,
    int? sessionId,
  }) =>
      into(moods).insert(MoodsCompanion.insert(
        loggedAt: DateTime.now(),
        score: score,
        label: Value(label),
        context: Value(context),
        sessionId: Value(sessionId),
      ));

  // ── INTENTION QUERIES ────────────────────

  Future<int> saveIntention(String text) {
    final today = DateTime.now();
    return into(intentions).insertOnConflictUpdate(IntentionsCompanion.insert(
      date: DateTime(today.year, today.month, today.day),
      intentionText: text,
    ));
  }
  // ── TIDE EVENT QUERIES ───────────────────

  Future<int> logTideEvent({
    String? packageName,
    required String eventType,
    String? detail,
    int? stage,
  }) =>
      into(tideEvents).insert(TideEventsCompanion.insert(
        timestamp: DateTime.now(),
        packageName: Value(packageName),
        eventType: eventType,
        detail: Value(detail),
        stage: Value(stage),
      ));

  Future<List<TideEvent>> getRecentTideEvents({int limit = 100}) =>
      (select(tideEvents)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.createTable(todos);
          }
        },
      );

  // ── TODO QUERIES ─────────────────────────

  Future<List<Todo>> getTodos() =>
      (select(todos)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> addTodo(String title, {int priority = 0}) =>
      into(todos).insert(TodosCompanion.insert(
        title: title,
        createdAt: DateTime.now(),
        priority: Value(priority),
      ));

  Future<void> toggleTodo(int id) async {
    final todo = await (select(todos)..where((t) => t.id.equals(id))).getSingle();
    await (update(todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        isCompleted: Value(!todo.isCompleted),
        completedAt: Value(!todo.isCompleted ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<Intention?> getTodayIntention() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return (select(intentions)
          ..where((i) =>
              i.date.isBiggerOrEqualValue(start) &
              i.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  // ── AI CONTEXT BUILDER ───────────────────
  // Call this at month 1+ to feed Claude API
  Future<Map<String, dynamic>> buildAIContext(String packageName) async {
    final sessions30 = await getSessionsForAIContext(packageName, days: 30);
    final resistRate = await getResistRate(packageName, days: 7);
    final todayOpens = await getTodayOpenCount(packageName);
    final todayIntention = await getTodayIntention();

    return {
      'packageName': packageName,
      'todayOpens': todayOpens,
      'weeklyResistRate': resistRate,
      'avgSessionSeconds': sessions30.isEmpty
          ? 0
          : sessions30
                  .where((s) => s.durationSeconds != null)
                  .fold(0, (sum, s) => sum + s.durationSeconds!) /
              sessions30.length,
      'totalSessionsLast30Days': sessions30.length,
      'todayIntention': todayIntention?.intentionText ?? 'not set',
      'peakOpenHour': _getPeakHour(sessions30),
    };
  }

  int _getPeakHour(List<Session> sessions) {
    if (sessions.isEmpty) return -1;
    final hourCounts = <int, int>{};
    for (final s in sessions) {
      final h = s.startedAt.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    return hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kora.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kora_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openReasonMeta = const VerificationMeta(
    'openReason',
  );
  @override
  late final GeneratedColumn<String> openReason = GeneratedColumn<String>(
    'open_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extensionCountMeta = const VerificationMeta(
    'extensionCount',
  );
  @override
  late final GeneratedColumn<int> extensionCount = GeneratedColumn<int>(
    'extension_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _didResistMeta = const VerificationMeta(
    'didResist',
  );
  @override
  late final GeneratedColumn<bool> didResist = GeneratedColumn<bool>(
    'did_resist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("did_resist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _risingTideStageReachedMeta =
      const VerificationMeta('risingTideStageReached');
  @override
  late final GeneratedColumn<int> risingTideStageReached = GeneratedColumn<int>(
    'rising_tide_stage_reached',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    appName,
    startedAt,
    endedAt,
    durationSeconds,
    openReason,
    extensionCount,
    didResist,
    risingTideStageReached,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('open_reason')) {
      context.handle(
        _openReasonMeta,
        openReason.isAcceptableOrUnknown(data['open_reason']!, _openReasonMeta),
      );
    }
    if (data.containsKey('extension_count')) {
      context.handle(
        _extensionCountMeta,
        extensionCount.isAcceptableOrUnknown(
          data['extension_count']!,
          _extensionCountMeta,
        ),
      );
    }
    if (data.containsKey('did_resist')) {
      context.handle(
        _didResistMeta,
        didResist.isAcceptableOrUnknown(data['did_resist']!, _didResistMeta),
      );
    }
    if (data.containsKey('rising_tide_stage_reached')) {
      context.handle(
        _risingTideStageReachedMeta,
        risingTideStageReached.isAcceptableOrUnknown(
          data['rising_tide_stage_reached']!,
          _risingTideStageReachedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      openReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}open_reason'],
      ),
      extensionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extension_count'],
      )!,
      didResist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}did_resist'],
      )!,
      risingTideStageReached: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rising_tide_stage_reached'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String packageName;
  final String appName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? openReason;
  final int extensionCount;
  final bool didResist;
  final int risingTideStageReached;
  const Session({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.openReason,
    required this.extensionCount,
    required this.didResist,
    required this.risingTideStageReached,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || openReason != null) {
      map['open_reason'] = Variable<String>(openReason);
    }
    map['extension_count'] = Variable<int>(extensionCount);
    map['did_resist'] = Variable<bool>(didResist);
    map['rising_tide_stage_reached'] = Variable<int>(risingTideStageReached);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      appName: Value(appName),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      openReason: openReason == null && nullToAbsent
          ? const Value.absent()
          : Value(openReason),
      extensionCount: Value(extensionCount),
      didResist: Value(didResist),
      risingTideStageReached: Value(risingTideStageReached),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      openReason: serializer.fromJson<String?>(json['openReason']),
      extensionCount: serializer.fromJson<int>(json['extensionCount']),
      didResist: serializer.fromJson<bool>(json['didResist']),
      risingTideStageReached: serializer.fromJson<int>(
        json['risingTideStageReached'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'openReason': serializer.toJson<String?>(openReason),
      'extensionCount': serializer.toJson<int>(extensionCount),
      'didResist': serializer.toJson<bool>(didResist),
      'risingTideStageReached': serializer.toJson<int>(risingTideStageReached),
    };
  }

  Session copyWith({
    int? id,
    String? packageName,
    String? appName,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> openReason = const Value.absent(),
    int? extensionCount,
    bool? didResist,
    int? risingTideStageReached,
  }) => Session(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    openReason: openReason.present ? openReason.value : this.openReason,
    extensionCount: extensionCount ?? this.extensionCount,
    didResist: didResist ?? this.didResist,
    risingTideStageReached:
        risingTideStageReached ?? this.risingTideStageReached,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      openReason: data.openReason.present
          ? data.openReason.value
          : this.openReason,
      extensionCount: data.extensionCount.present
          ? data.extensionCount.value
          : this.extensionCount,
      didResist: data.didResist.present ? data.didResist.value : this.didResist,
      risingTideStageReached: data.risingTideStageReached.present
          ? data.risingTideStageReached.value
          : this.risingTideStageReached,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('openReason: $openReason, ')
          ..write('extensionCount: $extensionCount, ')
          ..write('didResist: $didResist, ')
          ..write('risingTideStageReached: $risingTideStageReached')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageName,
    appName,
    startedAt,
    endedAt,
    durationSeconds,
    openReason,
    extensionCount,
    didResist,
    risingTideStageReached,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.openReason == this.openReason &&
          other.extensionCount == this.extensionCount &&
          other.didResist == this.didResist &&
          other.risingTideStageReached == this.risingTideStageReached);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> durationSeconds;
  final Value<String?> openReason;
  final Value<int> extensionCount;
  final Value<bool> didResist;
  final Value<int> risingTideStageReached;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.openReason = const Value.absent(),
    this.extensionCount = const Value.absent(),
    this.didResist = const Value.absent(),
    this.risingTideStageReached = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String packageName,
    required String appName,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.openReason = const Value.absent(),
    this.extensionCount = const Value.absent(),
    this.didResist = const Value.absent(),
    this.risingTideStageReached = const Value.absent(),
  }) : packageName = Value(packageName),
       appName = Value(appName),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
    Expression<String>? openReason,
    Expression<int>? extensionCount,
    Expression<bool>? didResist,
    Expression<int>? risingTideStageReached,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (openReason != null) 'open_reason': openReason,
      if (extensionCount != null) 'extension_count': extensionCount,
      if (didResist != null) 'did_resist': didResist,
      if (risingTideStageReached != null)
        'rising_tide_stage_reached': risingTideStageReached,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? packageName,
    Value<String>? appName,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? durationSeconds,
    Value<String?>? openReason,
    Value<int>? extensionCount,
    Value<bool>? didResist,
    Value<int>? risingTideStageReached,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      openReason: openReason ?? this.openReason,
      extensionCount: extensionCount ?? this.extensionCount,
      didResist: didResist ?? this.didResist,
      risingTideStageReached:
          risingTideStageReached ?? this.risingTideStageReached,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (openReason.present) {
      map['open_reason'] = Variable<String>(openReason.value);
    }
    if (extensionCount.present) {
      map['extension_count'] = Variable<int>(extensionCount.value);
    }
    if (didResist.present) {
      map['did_resist'] = Variable<bool>(didResist.value);
    }
    if (risingTideStageReached.present) {
      map['rising_tide_stage_reached'] = Variable<int>(
        risingTideStageReached.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('openReason: $openReason, ')
          ..write('extensionCount: $extensionCount, ')
          ..write('didResist: $didResist, ')
          ..write('risingTideStageReached: $risingTideStageReached')
          ..write(')'))
        .toString();
  }
}

class $MoodsTable extends Moods with TableInfo<$MoodsTable, Mood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loggedAt,
    score,
    label,
    context,
    sessionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
    );
  }

  @override
  $MoodsTable createAlias(String alias) {
    return $MoodsTable(attachedDatabase, alias);
  }
}

class Mood extends DataClass implements Insertable<Mood> {
  final int id;
  final DateTime loggedAt;
  final int score;
  final String? label;
  final String? context;
  final int? sessionId;
  const Mood({
    required this.id,
    required this.loggedAt,
    required this.score,
    this.label,
    this.context,
    this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    return map;
  }

  MoodsCompanion toCompanion(bool nullToAbsent) {
    return MoodsCompanion(
      id: Value(id),
      loggedAt: Value(loggedAt),
      score: Value(score),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
    );
  }

  factory Mood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mood(
      id: serializer.fromJson<int>(json['id']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      score: serializer.fromJson<int>(json['score']),
      label: serializer.fromJson<String?>(json['label']),
      context: serializer.fromJson<String?>(json['context']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'score': serializer.toJson<int>(score),
      'label': serializer.toJson<String?>(label),
      'context': serializer.toJson<String?>(context),
      'sessionId': serializer.toJson<int?>(sessionId),
    };
  }

  Mood copyWith({
    int? id,
    DateTime? loggedAt,
    int? score,
    Value<String?> label = const Value.absent(),
    Value<String?> context = const Value.absent(),
    Value<int?> sessionId = const Value.absent(),
  }) => Mood(
    id: id ?? this.id,
    loggedAt: loggedAt ?? this.loggedAt,
    score: score ?? this.score,
    label: label.present ? label.value : this.label,
    context: context.present ? context.value : this.context,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
  );
  Mood copyWithCompanion(MoodsCompanion data) {
    return Mood(
      id: data.id.present ? data.id.value : this.id,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      score: data.score.present ? data.score.value : this.score,
      label: data.label.present ? data.label.value : this.label,
      context: data.context.present ? data.context.value : this.context,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mood(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('score: $score, ')
          ..write('label: $label, ')
          ..write('context: $context, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, loggedAt, score, label, context, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mood &&
          other.id == this.id &&
          other.loggedAt == this.loggedAt &&
          other.score == this.score &&
          other.label == this.label &&
          other.context == this.context &&
          other.sessionId == this.sessionId);
}

class MoodsCompanion extends UpdateCompanion<Mood> {
  final Value<int> id;
  final Value<DateTime> loggedAt;
  final Value<int> score;
  final Value<String?> label;
  final Value<String?> context;
  final Value<int?> sessionId;
  const MoodsCompanion({
    this.id = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.score = const Value.absent(),
    this.label = const Value.absent(),
    this.context = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  MoodsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime loggedAt,
    required int score,
    this.label = const Value.absent(),
    this.context = const Value.absent(),
    this.sessionId = const Value.absent(),
  }) : loggedAt = Value(loggedAt),
       score = Value(score);
  static Insertable<Mood> custom({
    Expression<int>? id,
    Expression<DateTime>? loggedAt,
    Expression<int>? score,
    Expression<String>? label,
    Expression<String>? context,
    Expression<int>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (score != null) 'score': score,
      if (label != null) 'label': label,
      if (context != null) 'context': context,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  MoodsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? loggedAt,
    Value<int>? score,
    Value<String?>? label,
    Value<String?>? context,
    Value<int?>? sessionId,
  }) {
    return MoodsCompanion(
      id: id ?? this.id,
      loggedAt: loggedAt ?? this.loggedAt,
      score: score ?? this.score,
      label: label ?? this.label,
      context: context ?? this.context,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodsCompanion(')
          ..write('id: $id, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('score: $score, ')
          ..write('label: $label, ')
          ..write('context: $context, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }
}

class $DecisionsTable extends Decisions
    with TableInfo<$DecisionsTable, Decision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedMeta = const VerificationMeta('opened');
  @override
  late final GeneratedColumn<bool> opened = GeneratedColumn<bool>(
    'opened',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("opened" IN (0, 1))',
    ),
  );
  static const VerificationMeta _resistedCompletelyMeta =
      const VerificationMeta('resistedCompletely');
  @override
  late final GeneratedColumn<bool> resistedCompletely = GeneratedColumn<bool>(
    'resisted_completely',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resisted_completely" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tookAlternativeMeta = const VerificationMeta(
    'tookAlternative',
  );
  @override
  late final GeneratedColumn<bool> tookAlternative = GeneratedColumn<bool>(
    'took_alternative',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("took_alternative" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extensionReasonMeta = const VerificationMeta(
    'extensionReason',
  );
  @override
  late final GeneratedColumn<String> extensionReason = GeneratedColumn<String>(
    'extension_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    decidedAt,
    packageName,
    reason,
    opened,
    resistedCompletely,
    tookAlternative,
    extensionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Decision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_decidedAtMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('opened')) {
      context.handle(
        _openedMeta,
        opened.isAcceptableOrUnknown(data['opened']!, _openedMeta),
      );
    } else if (isInserting) {
      context.missing(_openedMeta);
    }
    if (data.containsKey('resisted_completely')) {
      context.handle(
        _resistedCompletelyMeta,
        resistedCompletely.isAcceptableOrUnknown(
          data['resisted_completely']!,
          _resistedCompletelyMeta,
        ),
      );
    }
    if (data.containsKey('took_alternative')) {
      context.handle(
        _tookAlternativeMeta,
        tookAlternative.isAcceptableOrUnknown(
          data['took_alternative']!,
          _tookAlternativeMeta,
        ),
      );
    }
    if (data.containsKey('extension_reason')) {
      context.handle(
        _extensionReasonMeta,
        extensionReason.isAcceptableOrUnknown(
          data['extension_reason']!,
          _extensionReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Decision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Decision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      opened: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}opened'],
      )!,
      resistedCompletely: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resisted_completely'],
      )!,
      tookAlternative: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}took_alternative'],
      )!,
      extensionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension_reason'],
      ),
    );
  }

  @override
  $DecisionsTable createAlias(String alias) {
    return $DecisionsTable(attachedDatabase, alias);
  }
}

class Decision extends DataClass implements Insertable<Decision> {
  final int id;
  final DateTime decidedAt;
  final String packageName;
  final String reason;
  final bool opened;
  final bool resistedCompletely;
  final bool tookAlternative;
  final String? extensionReason;
  const Decision({
    required this.id,
    required this.decidedAt,
    required this.packageName,
    required this.reason,
    required this.opened,
    required this.resistedCompletely,
    required this.tookAlternative,
    this.extensionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['decided_at'] = Variable<DateTime>(decidedAt);
    map['package_name'] = Variable<String>(packageName);
    map['reason'] = Variable<String>(reason);
    map['opened'] = Variable<bool>(opened);
    map['resisted_completely'] = Variable<bool>(resistedCompletely);
    map['took_alternative'] = Variable<bool>(tookAlternative);
    if (!nullToAbsent || extensionReason != null) {
      map['extension_reason'] = Variable<String>(extensionReason);
    }
    return map;
  }

  DecisionsCompanion toCompanion(bool nullToAbsent) {
    return DecisionsCompanion(
      id: Value(id),
      decidedAt: Value(decidedAt),
      packageName: Value(packageName),
      reason: Value(reason),
      opened: Value(opened),
      resistedCompletely: Value(resistedCompletely),
      tookAlternative: Value(tookAlternative),
      extensionReason: extensionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(extensionReason),
    );
  }

  factory Decision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Decision(
      id: serializer.fromJson<int>(json['id']),
      decidedAt: serializer.fromJson<DateTime>(json['decidedAt']),
      packageName: serializer.fromJson<String>(json['packageName']),
      reason: serializer.fromJson<String>(json['reason']),
      opened: serializer.fromJson<bool>(json['opened']),
      resistedCompletely: serializer.fromJson<bool>(json['resistedCompletely']),
      tookAlternative: serializer.fromJson<bool>(json['tookAlternative']),
      extensionReason: serializer.fromJson<String?>(json['extensionReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'decidedAt': serializer.toJson<DateTime>(decidedAt),
      'packageName': serializer.toJson<String>(packageName),
      'reason': serializer.toJson<String>(reason),
      'opened': serializer.toJson<bool>(opened),
      'resistedCompletely': serializer.toJson<bool>(resistedCompletely),
      'tookAlternative': serializer.toJson<bool>(tookAlternative),
      'extensionReason': serializer.toJson<String?>(extensionReason),
    };
  }

  Decision copyWith({
    int? id,
    DateTime? decidedAt,
    String? packageName,
    String? reason,
    bool? opened,
    bool? resistedCompletely,
    bool? tookAlternative,
    Value<String?> extensionReason = const Value.absent(),
  }) => Decision(
    id: id ?? this.id,
    decidedAt: decidedAt ?? this.decidedAt,
    packageName: packageName ?? this.packageName,
    reason: reason ?? this.reason,
    opened: opened ?? this.opened,
    resistedCompletely: resistedCompletely ?? this.resistedCompletely,
    tookAlternative: tookAlternative ?? this.tookAlternative,
    extensionReason: extensionReason.present
        ? extensionReason.value
        : this.extensionReason,
  );
  Decision copyWithCompanion(DecisionsCompanion data) {
    return Decision(
      id: data.id.present ? data.id.value : this.id,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      reason: data.reason.present ? data.reason.value : this.reason,
      opened: data.opened.present ? data.opened.value : this.opened,
      resistedCompletely: data.resistedCompletely.present
          ? data.resistedCompletely.value
          : this.resistedCompletely,
      tookAlternative: data.tookAlternative.present
          ? data.tookAlternative.value
          : this.tookAlternative,
      extensionReason: data.extensionReason.present
          ? data.extensionReason.value
          : this.extensionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Decision(')
          ..write('id: $id, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('packageName: $packageName, ')
          ..write('reason: $reason, ')
          ..write('opened: $opened, ')
          ..write('resistedCompletely: $resistedCompletely, ')
          ..write('tookAlternative: $tookAlternative, ')
          ..write('extensionReason: $extensionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    decidedAt,
    packageName,
    reason,
    opened,
    resistedCompletely,
    tookAlternative,
    extensionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Decision &&
          other.id == this.id &&
          other.decidedAt == this.decidedAt &&
          other.packageName == this.packageName &&
          other.reason == this.reason &&
          other.opened == this.opened &&
          other.resistedCompletely == this.resistedCompletely &&
          other.tookAlternative == this.tookAlternative &&
          other.extensionReason == this.extensionReason);
}

class DecisionsCompanion extends UpdateCompanion<Decision> {
  final Value<int> id;
  final Value<DateTime> decidedAt;
  final Value<String> packageName;
  final Value<String> reason;
  final Value<bool> opened;
  final Value<bool> resistedCompletely;
  final Value<bool> tookAlternative;
  final Value<String?> extensionReason;
  const DecisionsCompanion({
    this.id = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.packageName = const Value.absent(),
    this.reason = const Value.absent(),
    this.opened = const Value.absent(),
    this.resistedCompletely = const Value.absent(),
    this.tookAlternative = const Value.absent(),
    this.extensionReason = const Value.absent(),
  });
  DecisionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime decidedAt,
    required String packageName,
    required String reason,
    required bool opened,
    this.resistedCompletely = const Value.absent(),
    this.tookAlternative = const Value.absent(),
    this.extensionReason = const Value.absent(),
  }) : decidedAt = Value(decidedAt),
       packageName = Value(packageName),
       reason = Value(reason),
       opened = Value(opened);
  static Insertable<Decision> custom({
    Expression<int>? id,
    Expression<DateTime>? decidedAt,
    Expression<String>? packageName,
    Expression<String>? reason,
    Expression<bool>? opened,
    Expression<bool>? resistedCompletely,
    Expression<bool>? tookAlternative,
    Expression<String>? extensionReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (packageName != null) 'package_name': packageName,
      if (reason != null) 'reason': reason,
      if (opened != null) 'opened': opened,
      if (resistedCompletely != null) 'resisted_completely': resistedCompletely,
      if (tookAlternative != null) 'took_alternative': tookAlternative,
      if (extensionReason != null) 'extension_reason': extensionReason,
    });
  }

  DecisionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? decidedAt,
    Value<String>? packageName,
    Value<String>? reason,
    Value<bool>? opened,
    Value<bool>? resistedCompletely,
    Value<bool>? tookAlternative,
    Value<String?>? extensionReason,
  }) {
    return DecisionsCompanion(
      id: id ?? this.id,
      decidedAt: decidedAt ?? this.decidedAt,
      packageName: packageName ?? this.packageName,
      reason: reason ?? this.reason,
      opened: opened ?? this.opened,
      resistedCompletely: resistedCompletely ?? this.resistedCompletely,
      tookAlternative: tookAlternative ?? this.tookAlternative,
      extensionReason: extensionReason ?? this.extensionReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (opened.present) {
      map['opened'] = Variable<bool>(opened.value);
    }
    if (resistedCompletely.present) {
      map['resisted_completely'] = Variable<bool>(resistedCompletely.value);
    }
    if (tookAlternative.present) {
      map['took_alternative'] = Variable<bool>(tookAlternative.value);
    }
    if (extensionReason.present) {
      map['extension_reason'] = Variable<String>(extensionReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecisionsCompanion(')
          ..write('id: $id, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('packageName: $packageName, ')
          ..write('reason: $reason, ')
          ..write('opened: $opened, ')
          ..write('resistedCompletely: $resistedCompletely, ')
          ..write('tookAlternative: $tookAlternative, ')
          ..write('extensionReason: $extensionReason')
          ..write(')'))
        .toString();
  }
}

class $IntentionsTable extends Intentions
    with TableInfo<$IntentionsTable, Intention> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntentionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intentionTextMeta = const VerificationMeta(
    'intentionText',
  );
  @override
  late final GeneratedColumn<String> intentionText = GeneratedColumn<String>(
    'intention_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasHonouredMeta = const VerificationMeta(
    'wasHonoured',
  );
  @override
  late final GeneratedColumn<bool> wasHonoured = GeneratedColumn<bool>(
    'was_honoured',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_honoured" IN (0, 1))',
    ),
  );
  static const VerificationMeta _totalScreenMinutesThatDayMeta =
      const VerificationMeta('totalScreenMinutesThatDay');
  @override
  late final GeneratedColumn<int> totalScreenMinutesThatDay =
      GeneratedColumn<int>(
        'total_screen_minutes_that_day',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _morningMoodLabelMeta = const VerificationMeta(
    'morningMoodLabel',
  );
  @override
  late final GeneratedColumn<String> morningMoodLabel = GeneratedColumn<String>(
    'morning_mood_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    intentionText,
    wasHonoured,
    totalScreenMinutesThatDay,
    morningMoodLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intentions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Intention> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('intention_text')) {
      context.handle(
        _intentionTextMeta,
        intentionText.isAcceptableOrUnknown(
          data['intention_text']!,
          _intentionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intentionTextMeta);
    }
    if (data.containsKey('was_honoured')) {
      context.handle(
        _wasHonouredMeta,
        wasHonoured.isAcceptableOrUnknown(
          data['was_honoured']!,
          _wasHonouredMeta,
        ),
      );
    }
    if (data.containsKey('total_screen_minutes_that_day')) {
      context.handle(
        _totalScreenMinutesThatDayMeta,
        totalScreenMinutesThatDay.isAcceptableOrUnknown(
          data['total_screen_minutes_that_day']!,
          _totalScreenMinutesThatDayMeta,
        ),
      );
    }
    if (data.containsKey('morning_mood_label')) {
      context.handle(
        _morningMoodLabelMeta,
        morningMoodLabel.isAcceptableOrUnknown(
          data['morning_mood_label']!,
          _morningMoodLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Intention map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Intention(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      intentionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intention_text'],
      )!,
      wasHonoured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_honoured'],
      ),
      totalScreenMinutesThatDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_screen_minutes_that_day'],
      ),
      morningMoodLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}morning_mood_label'],
      ),
    );
  }

  @override
  $IntentionsTable createAlias(String alias) {
    return $IntentionsTable(attachedDatabase, alias);
  }
}

class Intention extends DataClass implements Insertable<Intention> {
  final int id;
  final DateTime date;
  final String intentionText;
  final bool? wasHonoured;
  final int? totalScreenMinutesThatDay;
  final String? morningMoodLabel;
  const Intention({
    required this.id,
    required this.date,
    required this.intentionText,
    this.wasHonoured,
    this.totalScreenMinutesThatDay,
    this.morningMoodLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['intention_text'] = Variable<String>(intentionText);
    if (!nullToAbsent || wasHonoured != null) {
      map['was_honoured'] = Variable<bool>(wasHonoured);
    }
    if (!nullToAbsent || totalScreenMinutesThatDay != null) {
      map['total_screen_minutes_that_day'] = Variable<int>(
        totalScreenMinutesThatDay,
      );
    }
    if (!nullToAbsent || morningMoodLabel != null) {
      map['morning_mood_label'] = Variable<String>(morningMoodLabel);
    }
    return map;
  }

  IntentionsCompanion toCompanion(bool nullToAbsent) {
    return IntentionsCompanion(
      id: Value(id),
      date: Value(date),
      intentionText: Value(intentionText),
      wasHonoured: wasHonoured == null && nullToAbsent
          ? const Value.absent()
          : Value(wasHonoured),
      totalScreenMinutesThatDay:
          totalScreenMinutesThatDay == null && nullToAbsent
          ? const Value.absent()
          : Value(totalScreenMinutesThatDay),
      morningMoodLabel: morningMoodLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(morningMoodLabel),
    );
  }

  factory Intention.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Intention(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      intentionText: serializer.fromJson<String>(json['intentionText']),
      wasHonoured: serializer.fromJson<bool?>(json['wasHonoured']),
      totalScreenMinutesThatDay: serializer.fromJson<int?>(
        json['totalScreenMinutesThatDay'],
      ),
      morningMoodLabel: serializer.fromJson<String?>(json['morningMoodLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'intentionText': serializer.toJson<String>(intentionText),
      'wasHonoured': serializer.toJson<bool?>(wasHonoured),
      'totalScreenMinutesThatDay': serializer.toJson<int?>(
        totalScreenMinutesThatDay,
      ),
      'morningMoodLabel': serializer.toJson<String?>(morningMoodLabel),
    };
  }

  Intention copyWith({
    int? id,
    DateTime? date,
    String? intentionText,
    Value<bool?> wasHonoured = const Value.absent(),
    Value<int?> totalScreenMinutesThatDay = const Value.absent(),
    Value<String?> morningMoodLabel = const Value.absent(),
  }) => Intention(
    id: id ?? this.id,
    date: date ?? this.date,
    intentionText: intentionText ?? this.intentionText,
    wasHonoured: wasHonoured.present ? wasHonoured.value : this.wasHonoured,
    totalScreenMinutesThatDay: totalScreenMinutesThatDay.present
        ? totalScreenMinutesThatDay.value
        : this.totalScreenMinutesThatDay,
    morningMoodLabel: morningMoodLabel.present
        ? morningMoodLabel.value
        : this.morningMoodLabel,
  );
  Intention copyWithCompanion(IntentionsCompanion data) {
    return Intention(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      intentionText: data.intentionText.present
          ? data.intentionText.value
          : this.intentionText,
      wasHonoured: data.wasHonoured.present
          ? data.wasHonoured.value
          : this.wasHonoured,
      totalScreenMinutesThatDay: data.totalScreenMinutesThatDay.present
          ? data.totalScreenMinutesThatDay.value
          : this.totalScreenMinutesThatDay,
      morningMoodLabel: data.morningMoodLabel.present
          ? data.morningMoodLabel.value
          : this.morningMoodLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Intention(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('intentionText: $intentionText, ')
          ..write('wasHonoured: $wasHonoured, ')
          ..write('totalScreenMinutesThatDay: $totalScreenMinutesThatDay, ')
          ..write('morningMoodLabel: $morningMoodLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    intentionText,
    wasHonoured,
    totalScreenMinutesThatDay,
    morningMoodLabel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Intention &&
          other.id == this.id &&
          other.date == this.date &&
          other.intentionText == this.intentionText &&
          other.wasHonoured == this.wasHonoured &&
          other.totalScreenMinutesThatDay == this.totalScreenMinutesThatDay &&
          other.morningMoodLabel == this.morningMoodLabel);
}

class IntentionsCompanion extends UpdateCompanion<Intention> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> intentionText;
  final Value<bool?> wasHonoured;
  final Value<int?> totalScreenMinutesThatDay;
  final Value<String?> morningMoodLabel;
  const IntentionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.intentionText = const Value.absent(),
    this.wasHonoured = const Value.absent(),
    this.totalScreenMinutesThatDay = const Value.absent(),
    this.morningMoodLabel = const Value.absent(),
  });
  IntentionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String intentionText,
    this.wasHonoured = const Value.absent(),
    this.totalScreenMinutesThatDay = const Value.absent(),
    this.morningMoodLabel = const Value.absent(),
  }) : date = Value(date),
       intentionText = Value(intentionText);
  static Insertable<Intention> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? intentionText,
    Expression<bool>? wasHonoured,
    Expression<int>? totalScreenMinutesThatDay,
    Expression<String>? morningMoodLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (intentionText != null) 'intention_text': intentionText,
      if (wasHonoured != null) 'was_honoured': wasHonoured,
      if (totalScreenMinutesThatDay != null)
        'total_screen_minutes_that_day': totalScreenMinutesThatDay,
      if (morningMoodLabel != null) 'morning_mood_label': morningMoodLabel,
    });
  }

  IntentionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? intentionText,
    Value<bool?>? wasHonoured,
    Value<int?>? totalScreenMinutesThatDay,
    Value<String?>? morningMoodLabel,
  }) {
    return IntentionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      intentionText: intentionText ?? this.intentionText,
      wasHonoured: wasHonoured ?? this.wasHonoured,
      totalScreenMinutesThatDay:
          totalScreenMinutesThatDay ?? this.totalScreenMinutesThatDay,
      morningMoodLabel: morningMoodLabel ?? this.morningMoodLabel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (intentionText.present) {
      map['intention_text'] = Variable<String>(intentionText.value);
    }
    if (wasHonoured.present) {
      map['was_honoured'] = Variable<bool>(wasHonoured.value);
    }
    if (totalScreenMinutesThatDay.present) {
      map['total_screen_minutes_that_day'] = Variable<int>(
        totalScreenMinutesThatDay.value,
      );
    }
    if (morningMoodLabel.present) {
      map['morning_mood_label'] = Variable<String>(morningMoodLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntentionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('intentionText: $intentionText, ')
          ..write('wasHonoured: $wasHonoured, ')
          ..write('totalScreenMinutesThatDay: $totalScreenMinutesThatDay, ')
          ..write('morningMoodLabel: $morningMoodLabel')
          ..write(')'))
        .toString();
  }
}

class $TideEventsTable extends TideEvents
    with TableInfo<$TideEventsTable, TideEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TideEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    packageName,
    eventType,
    detail,
    stage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tide_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TideEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TideEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TideEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      ),
    );
  }

  @override
  $TideEventsTable createAlias(String alias) {
    return $TideEventsTable(attachedDatabase, alias);
  }
}

class TideEvent extends DataClass implements Insertable<TideEvent> {
  final int id;
  final DateTime timestamp;
  final String? packageName;
  final String eventType;
  final String? detail;
  final int? stage;
  const TideEvent({
    required this.id,
    required this.timestamp,
    this.packageName,
    required this.eventType,
    this.detail,
    this.stage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || packageName != null) {
      map['package_name'] = Variable<String>(packageName);
    }
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    if (!nullToAbsent || stage != null) {
      map['stage'] = Variable<int>(stage);
    }
    return map;
  }

  TideEventsCompanion toCompanion(bool nullToAbsent) {
    return TideEventsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      packageName: packageName == null && nullToAbsent
          ? const Value.absent()
          : Value(packageName),
      eventType: Value(eventType),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      stage: stage == null && nullToAbsent
          ? const Value.absent()
          : Value(stage),
    );
  }

  factory TideEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TideEvent(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      packageName: serializer.fromJson<String?>(json['packageName']),
      eventType: serializer.fromJson<String>(json['eventType']),
      detail: serializer.fromJson<String?>(json['detail']),
      stage: serializer.fromJson<int?>(json['stage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'packageName': serializer.toJson<String?>(packageName),
      'eventType': serializer.toJson<String>(eventType),
      'detail': serializer.toJson<String?>(detail),
      'stage': serializer.toJson<int?>(stage),
    };
  }

  TideEvent copyWith({
    int? id,
    DateTime? timestamp,
    Value<String?> packageName = const Value.absent(),
    String? eventType,
    Value<String?> detail = const Value.absent(),
    Value<int?> stage = const Value.absent(),
  }) => TideEvent(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    packageName: packageName.present ? packageName.value : this.packageName,
    eventType: eventType ?? this.eventType,
    detail: detail.present ? detail.value : this.detail,
    stage: stage.present ? stage.value : this.stage,
  );
  TideEvent copyWithCompanion(TideEventsCompanion data) {
    return TideEvent(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      detail: data.detail.present ? data.detail.value : this.detail,
      stage: data.stage.present ? data.stage.value : this.stage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TideEvent(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('packageName: $packageName, ')
          ..write('eventType: $eventType, ')
          ..write('detail: $detail, ')
          ..write('stage: $stage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, packageName, eventType, detail, stage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TideEvent &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.packageName == this.packageName &&
          other.eventType == this.eventType &&
          other.detail == this.detail &&
          other.stage == this.stage);
}

class TideEventsCompanion extends UpdateCompanion<TideEvent> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String?> packageName;
  final Value<String> eventType;
  final Value<String?> detail;
  final Value<int?> stage;
  const TideEventsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.packageName = const Value.absent(),
    this.eventType = const Value.absent(),
    this.detail = const Value.absent(),
    this.stage = const Value.absent(),
  });
  TideEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    this.packageName = const Value.absent(),
    required String eventType,
    this.detail = const Value.absent(),
    this.stage = const Value.absent(),
  }) : timestamp = Value(timestamp),
       eventType = Value(eventType);
  static Insertable<TideEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? packageName,
    Expression<String>? eventType,
    Expression<String>? detail,
    Expression<int>? stage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (packageName != null) 'package_name': packageName,
      if (eventType != null) 'event_type': eventType,
      if (detail != null) 'detail': detail,
      if (stage != null) 'stage': stage,
    });
  }

  TideEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String?>? packageName,
    Value<String>? eventType,
    Value<String?>? detail,
    Value<int?>? stage,
  }) {
    return TideEventsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      packageName: packageName ?? this.packageName,
      eventType: eventType ?? this.eventType,
      detail: detail ?? this.detail,
      stage: stage ?? this.stage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TideEventsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('packageName: $packageName, ')
          ..write('eventType: $eventType, ')
          ..write('detail: $detail, ')
          ..write('stage: $stage')
          ..write(')'))
        .toString();
  }
}

class $TodosTable extends Todos with TableInfo<$TodosTable, Todo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    isCompleted,
    createdAt,
    completedAt,
    priority,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Todo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Todo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class Todo extends DataClass implements Insertable<Todo> {
  final int id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int priority;
  const Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.priority,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['priority'] = Variable<int>(priority);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      priority: Value(priority),
    );
  }

  factory Todo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Todo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      priority: serializer.fromJson<int>(json['priority']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'priority': serializer.toJson<int>(priority),
    };
  }

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    int? priority,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    priority: priority ?? this.priority,
  );
  Todo copyWithCompanion(TodosCompanion data) {
    return Todo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      priority: data.priority.present ? data.priority.value : this.priority,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Todo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, isCompleted, createdAt, completedAt, priority);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Todo &&
          other.id == this.id &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.priority == this.priority);
}

class TodosCompanion extends UpdateCompanion<Todo> {
  final Value<int> id;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<int> priority;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.priority = const Value.absent(),
  });
  TodosCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.priority = const Value.absent(),
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Todo> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? priority,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (priority != null) 'priority': priority,
    });
  }

  TodosCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<int>? priority,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('priority: $priority')
          ..write(')'))
        .toString();
  }
}

abstract class _$KoraDatabase extends GeneratedDatabase {
  _$KoraDatabase(QueryExecutor e) : super(e);
  $KoraDatabaseManager get managers => $KoraDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MoodsTable moods = $MoodsTable(this);
  late final $DecisionsTable decisions = $DecisionsTable(this);
  late final $IntentionsTable intentions = $IntentionsTable(this);
  late final $TideEventsTable tideEvents = $TideEventsTable(this);
  late final $TodosTable todos = $TodosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    moods,
    decisions,
    intentions,
    tideEvents,
    todos,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String packageName,
      required String appName,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
      Value<String?> openReason,
      Value<int> extensionCount,
      Value<bool> didResist,
      Value<int> risingTideStageReached,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> packageName,
      Value<String> appName,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
      Value<String?> openReason,
      Value<int> extensionCount,
      Value<bool> didResist,
      Value<int> risingTideStageReached,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$KoraDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openReason => $composableBuilder(
    column: $table.openReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extensionCount => $composableBuilder(
    column: $table.extensionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get didResist => $composableBuilder(
    column: $table.didResist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get risingTideStageReached => $composableBuilder(
    column: $table.risingTideStageReached,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$KoraDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openReason => $composableBuilder(
    column: $table.openReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extensionCount => $composableBuilder(
    column: $table.extensionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get didResist => $composableBuilder(
    column: $table.didResist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get risingTideStageReached => $composableBuilder(
    column: $table.risingTideStageReached,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openReason => $composableBuilder(
    column: $table.openReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extensionCount => $composableBuilder(
    column: $table.extensionCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get didResist =>
      $composableBuilder(column: $table.didResist, builder: (column) => column);

  GeneratedColumn<int> get risingTideStageReached => $composableBuilder(
    column: $table.risingTideStageReached,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$KoraDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$KoraDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> openReason = const Value.absent(),
                Value<int> extensionCount = const Value.absent(),
                Value<bool> didResist = const Value.absent(),
                Value<int> risingTideStageReached = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                packageName: packageName,
                appName: appName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                openReason: openReason,
                extensionCount: extensionCount,
                didResist: didResist,
                risingTideStageReached: risingTideStageReached,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String packageName,
                required String appName,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> openReason = const Value.absent(),
                Value<int> extensionCount = const Value.absent(),
                Value<bool> didResist = const Value.absent(),
                Value<int> risingTideStageReached = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                packageName: packageName,
                appName: appName,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                openReason: openReason,
                extensionCount: extensionCount,
                didResist: didResist,
                risingTideStageReached: risingTideStageReached,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$KoraDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$MoodsTableCreateCompanionBuilder =
    MoodsCompanion Function({
      Value<int> id,
      required DateTime loggedAt,
      required int score,
      Value<String?> label,
      Value<String?> context,
      Value<int?> sessionId,
    });
typedef $$MoodsTableUpdateCompanionBuilder =
    MoodsCompanion Function({
      Value<int> id,
      Value<DateTime> loggedAt,
      Value<int> score,
      Value<String?> label,
      Value<String?> context,
      Value<int?> sessionId,
    });

class $$MoodsTableFilterComposer extends Composer<_$KoraDatabase, $MoodsTable> {
  $$MoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoodsTableOrderingComposer
    extends Composer<_$KoraDatabase, $MoodsTable> {
  $$MoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoodsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $MoodsTable> {
  $$MoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
}

class $$MoodsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $MoodsTable,
          Mood,
          $$MoodsTableFilterComposer,
          $$MoodsTableOrderingComposer,
          $$MoodsTableAnnotationComposer,
          $$MoodsTableCreateCompanionBuilder,
          $$MoodsTableUpdateCompanionBuilder,
          (Mood, BaseReferences<_$KoraDatabase, $MoodsTable, Mood>),
          Mood,
          PrefetchHooks Function()
        > {
  $$MoodsTableTableManager(_$KoraDatabase db, $MoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
              }) => MoodsCompanion(
                id: id,
                loggedAt: loggedAt,
                score: score,
                label: label,
                context: context,
                sessionId: sessionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime loggedAt,
                required int score,
                Value<String?> label = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
              }) => MoodsCompanion.insert(
                id: id,
                loggedAt: loggedAt,
                score: score,
                label: label,
                context: context,
                sessionId: sessionId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $MoodsTable,
      Mood,
      $$MoodsTableFilterComposer,
      $$MoodsTableOrderingComposer,
      $$MoodsTableAnnotationComposer,
      $$MoodsTableCreateCompanionBuilder,
      $$MoodsTableUpdateCompanionBuilder,
      (Mood, BaseReferences<_$KoraDatabase, $MoodsTable, Mood>),
      Mood,
      PrefetchHooks Function()
    >;
typedef $$DecisionsTableCreateCompanionBuilder =
    DecisionsCompanion Function({
      Value<int> id,
      required DateTime decidedAt,
      required String packageName,
      required String reason,
      required bool opened,
      Value<bool> resistedCompletely,
      Value<bool> tookAlternative,
      Value<String?> extensionReason,
    });
typedef $$DecisionsTableUpdateCompanionBuilder =
    DecisionsCompanion Function({
      Value<int> id,
      Value<DateTime> decidedAt,
      Value<String> packageName,
      Value<String> reason,
      Value<bool> opened,
      Value<bool> resistedCompletely,
      Value<bool> tookAlternative,
      Value<String?> extensionReason,
    });

class $$DecisionsTableFilterComposer
    extends Composer<_$KoraDatabase, $DecisionsTable> {
  $$DecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get opened => $composableBuilder(
    column: $table.opened,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resistedCompletely => $composableBuilder(
    column: $table.resistedCompletely,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tookAlternative => $composableBuilder(
    column: $table.tookAlternative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extensionReason => $composableBuilder(
    column: $table.extensionReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DecisionsTableOrderingComposer
    extends Composer<_$KoraDatabase, $DecisionsTable> {
  $$DecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get opened => $composableBuilder(
    column: $table.opened,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resistedCompletely => $composableBuilder(
    column: $table.resistedCompletely,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tookAlternative => $composableBuilder(
    column: $table.tookAlternative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extensionReason => $composableBuilder(
    column: $table.extensionReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecisionsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $DecisionsTable> {
  $$DecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get opened =>
      $composableBuilder(column: $table.opened, builder: (column) => column);

  GeneratedColumn<bool> get resistedCompletely => $composableBuilder(
    column: $table.resistedCompletely,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tookAlternative => $composableBuilder(
    column: $table.tookAlternative,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extensionReason => $composableBuilder(
    column: $table.extensionReason,
    builder: (column) => column,
  );
}

class $$DecisionsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $DecisionsTable,
          Decision,
          $$DecisionsTableFilterComposer,
          $$DecisionsTableOrderingComposer,
          $$DecisionsTableAnnotationComposer,
          $$DecisionsTableCreateCompanionBuilder,
          $$DecisionsTableUpdateCompanionBuilder,
          (Decision, BaseReferences<_$KoraDatabase, $DecisionsTable, Decision>),
          Decision,
          PrefetchHooks Function()
        > {
  $$DecisionsTableTableManager(_$KoraDatabase db, $DecisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> decidedAt = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<bool> opened = const Value.absent(),
                Value<bool> resistedCompletely = const Value.absent(),
                Value<bool> tookAlternative = const Value.absent(),
                Value<String?> extensionReason = const Value.absent(),
              }) => DecisionsCompanion(
                id: id,
                decidedAt: decidedAt,
                packageName: packageName,
                reason: reason,
                opened: opened,
                resistedCompletely: resistedCompletely,
                tookAlternative: tookAlternative,
                extensionReason: extensionReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime decidedAt,
                required String packageName,
                required String reason,
                required bool opened,
                Value<bool> resistedCompletely = const Value.absent(),
                Value<bool> tookAlternative = const Value.absent(),
                Value<String?> extensionReason = const Value.absent(),
              }) => DecisionsCompanion.insert(
                id: id,
                decidedAt: decidedAt,
                packageName: packageName,
                reason: reason,
                opened: opened,
                resistedCompletely: resistedCompletely,
                tookAlternative: tookAlternative,
                extensionReason: extensionReason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $DecisionsTable,
      Decision,
      $$DecisionsTableFilterComposer,
      $$DecisionsTableOrderingComposer,
      $$DecisionsTableAnnotationComposer,
      $$DecisionsTableCreateCompanionBuilder,
      $$DecisionsTableUpdateCompanionBuilder,
      (Decision, BaseReferences<_$KoraDatabase, $DecisionsTable, Decision>),
      Decision,
      PrefetchHooks Function()
    >;
typedef $$IntentionsTableCreateCompanionBuilder =
    IntentionsCompanion Function({
      Value<int> id,
      required DateTime date,
      required String intentionText,
      Value<bool?> wasHonoured,
      Value<int?> totalScreenMinutesThatDay,
      Value<String?> morningMoodLabel,
    });
typedef $$IntentionsTableUpdateCompanionBuilder =
    IntentionsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> intentionText,
      Value<bool?> wasHonoured,
      Value<int?> totalScreenMinutesThatDay,
      Value<String?> morningMoodLabel,
    });

class $$IntentionsTableFilterComposer
    extends Composer<_$KoraDatabase, $IntentionsTable> {
  $$IntentionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intentionText => $composableBuilder(
    column: $table.intentionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasHonoured => $composableBuilder(
    column: $table.wasHonoured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScreenMinutesThatDay => $composableBuilder(
    column: $table.totalScreenMinutesThatDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get morningMoodLabel => $composableBuilder(
    column: $table.morningMoodLabel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntentionsTableOrderingComposer
    extends Composer<_$KoraDatabase, $IntentionsTable> {
  $$IntentionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intentionText => $composableBuilder(
    column: $table.intentionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasHonoured => $composableBuilder(
    column: $table.wasHonoured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScreenMinutesThatDay => $composableBuilder(
    column: $table.totalScreenMinutesThatDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get morningMoodLabel => $composableBuilder(
    column: $table.morningMoodLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntentionsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $IntentionsTable> {
  $$IntentionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get intentionText => $composableBuilder(
    column: $table.intentionText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasHonoured => $composableBuilder(
    column: $table.wasHonoured,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalScreenMinutesThatDay => $composableBuilder(
    column: $table.totalScreenMinutesThatDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get morningMoodLabel => $composableBuilder(
    column: $table.morningMoodLabel,
    builder: (column) => column,
  );
}

class $$IntentionsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $IntentionsTable,
          Intention,
          $$IntentionsTableFilterComposer,
          $$IntentionsTableOrderingComposer,
          $$IntentionsTableAnnotationComposer,
          $$IntentionsTableCreateCompanionBuilder,
          $$IntentionsTableUpdateCompanionBuilder,
          (
            Intention,
            BaseReferences<_$KoraDatabase, $IntentionsTable, Intention>,
          ),
          Intention,
          PrefetchHooks Function()
        > {
  $$IntentionsTableTableManager(_$KoraDatabase db, $IntentionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntentionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntentionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntentionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> intentionText = const Value.absent(),
                Value<bool?> wasHonoured = const Value.absent(),
                Value<int?> totalScreenMinutesThatDay = const Value.absent(),
                Value<String?> morningMoodLabel = const Value.absent(),
              }) => IntentionsCompanion(
                id: id,
                date: date,
                intentionText: intentionText,
                wasHonoured: wasHonoured,
                totalScreenMinutesThatDay: totalScreenMinutesThatDay,
                morningMoodLabel: morningMoodLabel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String intentionText,
                Value<bool?> wasHonoured = const Value.absent(),
                Value<int?> totalScreenMinutesThatDay = const Value.absent(),
                Value<String?> morningMoodLabel = const Value.absent(),
              }) => IntentionsCompanion.insert(
                id: id,
                date: date,
                intentionText: intentionText,
                wasHonoured: wasHonoured,
                totalScreenMinutesThatDay: totalScreenMinutesThatDay,
                morningMoodLabel: morningMoodLabel,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntentionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $IntentionsTable,
      Intention,
      $$IntentionsTableFilterComposer,
      $$IntentionsTableOrderingComposer,
      $$IntentionsTableAnnotationComposer,
      $$IntentionsTableCreateCompanionBuilder,
      $$IntentionsTableUpdateCompanionBuilder,
      (Intention, BaseReferences<_$KoraDatabase, $IntentionsTable, Intention>),
      Intention,
      PrefetchHooks Function()
    >;
typedef $$TideEventsTableCreateCompanionBuilder =
    TideEventsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      Value<String?> packageName,
      required String eventType,
      Value<String?> detail,
      Value<int?> stage,
    });
typedef $$TideEventsTableUpdateCompanionBuilder =
    TideEventsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String?> packageName,
      Value<String> eventType,
      Value<String?> detail,
      Value<int?> stage,
    });

class $$TideEventsTableFilterComposer
    extends Composer<_$KoraDatabase, $TideEventsTable> {
  $$TideEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TideEventsTableOrderingComposer
    extends Composer<_$KoraDatabase, $TideEventsTable> {
  $$TideEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TideEventsTableAnnotationComposer
    extends Composer<_$KoraDatabase, $TideEventsTable> {
  $$TideEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);
}

class $$TideEventsTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $TideEventsTable,
          TideEvent,
          $$TideEventsTableFilterComposer,
          $$TideEventsTableOrderingComposer,
          $$TideEventsTableAnnotationComposer,
          $$TideEventsTableCreateCompanionBuilder,
          $$TideEventsTableUpdateCompanionBuilder,
          (
            TideEvent,
            BaseReferences<_$KoraDatabase, $TideEventsTable, TideEvent>,
          ),
          TideEvent,
          PrefetchHooks Function()
        > {
  $$TideEventsTableTableManager(_$KoraDatabase db, $TideEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TideEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TideEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TideEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> packageName = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int?> stage = const Value.absent(),
              }) => TideEventsCompanion(
                id: id,
                timestamp: timestamp,
                packageName: packageName,
                eventType: eventType,
                detail: detail,
                stage: stage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                Value<String?> packageName = const Value.absent(),
                required String eventType,
                Value<String?> detail = const Value.absent(),
                Value<int?> stage = const Value.absent(),
              }) => TideEventsCompanion.insert(
                id: id,
                timestamp: timestamp,
                packageName: packageName,
                eventType: eventType,
                detail: detail,
                stage: stage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TideEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $TideEventsTable,
      TideEvent,
      $$TideEventsTableFilterComposer,
      $$TideEventsTableOrderingComposer,
      $$TideEventsTableAnnotationComposer,
      $$TideEventsTableCreateCompanionBuilder,
      $$TideEventsTableUpdateCompanionBuilder,
      (TideEvent, BaseReferences<_$KoraDatabase, $TideEventsTable, TideEvent>),
      TideEvent,
      PrefetchHooks Function()
    >;
typedef $$TodosTableCreateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      required String title,
      Value<bool> isCompleted,
      required DateTime createdAt,
      Value<DateTime?> completedAt,
      Value<int> priority,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<bool> isCompleted,
      Value<DateTime> createdAt,
      Value<DateTime?> completedAt,
      Value<int> priority,
    });

class $$TodosTableFilterComposer extends Composer<_$KoraDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends Composer<_$KoraDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends Composer<_$KoraDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$KoraDatabase,
          $TodosTable,
          Todo,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (Todo, BaseReferences<_$KoraDatabase, $TodosTable, Todo>),
          Todo,
          PrefetchHooks Function()
        > {
  $$TodosTableTableManager(_$KoraDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                title: title,
                isCompleted: isCompleted,
                createdAt: createdAt,
                completedAt: completedAt,
                priority: priority,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> priority = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                title: title,
                isCompleted: isCompleted,
                createdAt: createdAt,
                completedAt: completedAt,
                priority: priority,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$KoraDatabase,
      $TodosTable,
      Todo,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (Todo, BaseReferences<_$KoraDatabase, $TodosTable, Todo>),
      Todo,
      PrefetchHooks Function()
    >;

class $KoraDatabaseManager {
  final _$KoraDatabase _db;
  $KoraDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MoodsTableTableManager get moods =>
      $$MoodsTableTableManager(_db, _db.moods);
  $$DecisionsTableTableManager get decisions =>
      $$DecisionsTableTableManager(_db, _db.decisions);
  $$IntentionsTableTableManager get intentions =>
      $$IntentionsTableTableManager(_db, _db.intentions);
  $$TideEventsTableTableManager get tideEvents =>
      $$TideEventsTableTableManager(_db, _db.tideEvents);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
}
import 'package:flutter/material.dart';

/// Global navigator key so native-driven routes (e.g. accessibility) avoid importing [main.dart].
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
enum RisingTideStage {
  whisper, // 0 - 49%
  dim,     // 50 - 99%
  mirror,  // 100 - 199% OR 2 overrides
  silence, // 200%+ OR 3 overrides
}
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
import 'package:flutter/material.dart';
import 'app_navigator.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/launcher_service.dart';
import 'services/usage_service.dart';
import 'services/rising_tide_service.dart';
import 'services/app_lock_manager.dart';
import 'services/native_service.dart';
import 'services/todo_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    debugPrint("FlutterError: ${details.exceptionAsString()}");
  };

  debugPrint("KoraLauncher: Starting minimal shell...");
  runApp(const KoraStartupShell());
}

class KoraStartupShell extends StatefulWidget {
  const KoraStartupShell({super.key});

  @override
  State<KoraStartupShell> createState() => _KoraStartupShellState();
}

class _KoraStartupShellState extends State<KoraStartupShell> {
  bool _initialized = false;
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _hydrateData();
  }

  Future<void> _hydrateData() async {
    try {
      debugPrint("KoraLauncher: Hydrating data...");
      await StorageService.init();
      await AppLockManager.init();
      await LauncherService.init();
      await UsageService.refreshUsage();
      await TodoService.init();
      
      await RisingTideService.syncInterceptionState();
      
      NativeService.initMethodCallHandler();

      debugPrint("KoraLauncher: Hydration complete. Launching main app.");
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint("KoraLauncher Initialization Error: $e\n$stack");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "Startup Error: $_errorMessage\n\nTap refresh to retry.",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                _hasError = false;
              });
              _hydrateData();
            },
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      );
    }
    
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(), // Pure black minimal shell
        ),
      );
    }

    return const KoraLauncher();
  }
}

class KoraLauncher extends StatelessWidget {
  const KoraLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kora Launcher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}
