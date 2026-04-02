import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import 'app_drawer_screen.dart';
import '../widgets/goal_setter.dart';
import '../widgets/todo_list_card.dart';
import 'todo_screen.dart';
import 'usage_dashboard_screen.dart';
import 'tide_pool_screen.dart';
import 'permissions_screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'package:upgrader/upgrader.dart';
import 'package:intl/intl.dart';
import '../state/home_controller.dart';
import '../widgets/home_banners.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      _controller.refreshHomeState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
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
                    ).then((_) => _controller.triggerRefresh());
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
                          HomeBanners(controller: _controller),
                          _buildTopInfoBar(),

                          // _buildGoalHeader() replaced by chip in top bar
                          const SizedBox(height: 16),

                          if (!_controller.showGoalSetter) ...[
                            TodoListCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => const TodoScreen(),
                                  ),
                                ).then((_) => _controller.triggerRefresh());
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

            if (_controller.showGoalSetter)
              GoalSetter(
                initialGoal: _controller.goal,
                onDismiss: _controller.dismissGoalSetter,
                onGoalSet: _controller.onGoalSet,
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
      },
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
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PermissionsAndPrivacyScreen()),
        ).then((_) => _controller.refreshHomeState());
      },
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
          Expanded(child: _buildCenterIntentionText()),
          const SizedBox(width: 12),
          if (_controller.hasUsagePermission) _buildUsageStats(),
        ],
      ),
    );
  }

  Widget _buildSetGoalPill() {
    return GestureDetector(
      onTap: () {
        _controller.showGoalSetterOverlay();
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
    final String? goalStr = _controller.goal;
    final hasGoal = goalStr != null && goalStr.isNotEmpty;

    Widget textWidget = Text(
      hasGoal ? goalStr : "No intention set",
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: hasGoal ? Colors.white : Colors.white.withValues(alpha: 0.4),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );

    if (_controller.pulseIntention && !hasGoal) {
      // Soft single pulse on morning unlock if no goal
      textWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOutSine,
        builder: (context, val, child) {
          return Opacity(opacity: val, child: child);
        },
        onEnd: () {
          _controller.stopPulse();
        },
        child: textWidget,
      );
    }

    return GestureDetector(
      onTap: () {
        _controller.stopPulse();
        _controller.showGoalSetterOverlay();
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
