import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import 'app_drawer_screen.dart';
import '../widgets/intention_setter.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _showIntentionSetter = false;
  bool _isDefaultLauncher = true; 
  bool _hasUsagePermission = true;
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
    if (state == AppLifecycleState.resumed) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
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
    if (!StorageService.hasSetIntentionToday()) {
      setState(() {
        _showIntentionSetter = true;
      });
    } else {
      setState(() {
        _intention = StorageService.getDailyIntention();
      });
    }
  }

  void _openAppDrawer() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppDrawerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from exiting the launcher
      child: Scaffold(
        backgroundColor: Colors.transparent, // True launcher transparency!
        body: Stack(
          children: [
          // Gesture Layer that spans the whole screen
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                // Strong Swipe UP
                _openAppDrawer();
              }
            },
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  children: [
                    if (!_isDefaultLauncher) _buildDefaultLauncherBanner(),
                    if (!_hasUsagePermission) _buildUsagePermissionBanner(),
                    _buildTopInfoBar(),
                    if (_intention != null && !_showIntentionSetter) _buildIntentionHeader(),
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
                          const Icon(Icons.keyboard_arrow_up, color: Colors.white60, size: 28),
                          Text(
                            "Swipe up or tap to search",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlays
          if (_showIntentionSetter)
            IntentionSetter(
              onIntentionSet: () {
                setState(() {
                  _showIntentionSetter = false;
                  _intention = StorageService.getDailyIntention();
                });
              },
            ),
        ],
      ),
    ));
  }

  Widget _buildTopInfoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_hasUsagePermission) _buildUsageStats(),
        ],
      ),
    );
  }

  Widget _buildIntentionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
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
            _intention!,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  height: 1.2,
                  fontWeight: FontWeight.w300,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    final totalUsage = UsageService.getTotalUsage();
    return Container(
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
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              const AndroidIntent intent = AndroidIntent(
                action: 'android.settings.HOME_SETTINGS',
                flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
              );
              intent.launch();
            },
              child: Text( "SET DEFAULT",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              // foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await NativeService.openUsageSettings();
            },
            child: const Text("ENABLE", style: TextStyle(fontWeight: FontWeight.bold)),
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
            onTap: () => const AndroidIntent(action: 'android.intent.action.DIAL').launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.message,
            onTap: () => const AndroidIntent(action: 'android.intent.action.MAIN', category: 'android.intent.category.APP_MESSAGING').launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.language, // Browser
            onTap: () => const AndroidIntent(action: 'android.intent.action.MAIN', category: 'android.intent.category.APP_BROWSER').launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.camera_alt,
            onTap: () => const AndroidIntent(action: 'android.media.action.STILL_IMAGE_CAMERA').launch(),
          ),
          _buildShortcutIcon(
            icon: Icons.image_outlined,
            onTap: () => const AndroidIntent(action: 'android.intent.action.MAIN', category: 'android.intent.category.APP_GALLERY').launch(),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutIcon({required IconData icon, required VoidCallback onTap}) {
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
