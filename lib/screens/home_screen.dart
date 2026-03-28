import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import 'app_drawer_screen.dart';
import '../widgets/intention_setter.dart';
import 'usage_dashboard_screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showIntentionSetter = false;
  bool _isDefaultLauncher = true;
  bool _hasUsagePermission = true;
  bool _hasSkippedIntentionTodaySession = false;
  String? _intention;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNativeState();
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
      // Clear focus when screen is locked or app goes to background
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      _checkNativeState();
      UsageService.refreshUsage().then((_) {
        if (mounted) setState(() {});
      });
      _checkIntention();
    }
  }

  Future<void> _checkNativeState() async {
    final isDefault = await NativeService.isDefaultLauncher();
    final hasUsage = await NativeService.hasUsagePermission();
    if (mounted) {
      setState(() {
        _isDefaultLauncher = isDefault;
        _hasUsagePermission = hasUsage;
      });
    }
  }

  Future<void> _loadInitialData() async {
    await LauncherService.refreshApps();
    await UsageService.refreshUsage();
    _checkIntention();
    if (mounted) setState(() {});
  }

  void _checkIntention() {
    _intention = StorageService.getDailyIntention();
    if (_intention == null &&
        !StorageService.hasSetIntentionToday() &&
        !_hasSkippedIntentionTodaySession) {
      if (mounted) {
        setState(() {
          _showIntentionSetter = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _showIntentionSetter = false;
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
      // Refresh on return in case settings/usage changed
      _checkNativeState();
      UsageService.refreshUsage().then((_) {
        if (mounted) setState(() {});
      });
      _checkIntention();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from exiting the launcher
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor:
            Colors.black, // Solid black to fix recents wallpaper glitch
        body: Stack(
          children: [
            // Gesture Layer that spans the whole screen
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Save and close keyboard when tapping anywhere outside
                FocusManager.instance.primaryFocus?.unfocus();
              },
              // onDoubleTap: () {
              //   NativeService.lockScreen();
              // },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -300) {
                  // Strong Swipe UP
                  _openAppDrawer();
                }
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity;
                if (velocity != null) {
                  if (velocity > 300) {
                    // Horizontal Swipe Right -> Open Dashboard
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
                    // Horizontal Swipe Left -> Reserved for future feature!
                  }
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             MediaQuery.of(context).padding.bottom,
                      child: Column(
                        children: [
                          if (!_isDefaultLauncher) _buildDefaultLauncherBanner(),
                          if (!_hasUsagePermission) _buildUsagePermissionBanner(),
                          _buildTopInfoBar(),
    
                          // Live Precision Clock removed
                          if (!_showIntentionSetter) _buildIntentionHeader(),
    
                          const Spacer(),
    
                          // Essential Shortcuts Dock
                          _buildQuickAccessDock(),
                          const SizedBox(height: 16),
    
                          // Swipe up Hint
                          GestureDetector(
                            onTap: _openAppDrawer,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Colors.white60,
                                  size: 28,
                                ),
                                Text(
                                  "Swipe up or tap to search",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // const SizedBox(height: 24), // Tighter gap for better grounded layout
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Overlays
            if (_showIntentionSetter)
              IntentionSetter(
                initialIntention: _intention,
                onDismiss: () {
                  setState(() {
                    _showIntentionSetter = false;
                    _hasSkippedIntentionTodaySession = true;
                  });
                },
                onIntentionSet: () {
                  setState(() {
                    _showIntentionSetter = false;
                    _intention = StorageService.getDailyIntention();
                  });
                },
              ),
            // Update Alert overlay
            UpgradeAlert(
              showIgnore: false,
              showLater: true,
              dialogStyle: UpgradeDialogStyle.material,
              child: SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [if (_hasUsagePermission) _buildUsageStats()],
      ),
    );
  }

  Widget _buildIntentionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showIntentionSetter = true;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "TODAY'S INTENTION",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 2,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _intention ?? "Tap to set intention...",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: _intention != null ? 36 : 24,
                height: 1.2,
                color: _intention != null ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w300,
                shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
              ),
            ),
          ],
        ),
      ),
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
