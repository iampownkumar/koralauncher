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
