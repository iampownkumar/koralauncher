-----./screens/app_drawer_screen.dart-----
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import '../widgets/app_list_item.dart';
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
        });
      } else {
        LauncherService.launchApp(app.packageName).then((_) {
          _searchController.clear();
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
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe down to go back to home screen
        if (details.primaryVelocity! > 0) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor:
            Colors.black, // Solid dark background to fix recents glitch
        body: Stack(
          children: [
            // Dark Blur Background for premium feel over the list items as they scroll
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
                            Navigator.maybePop(context);
                            return true;
                          }
                        }
                        return false;
                      },
                      child: _buildAppList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              });
            } else {
              LauncherService.launchApp(app.packageName).then((_) {
                _searchController.clear();
              });
            }
          },
          onLongPress: () async {
            await StorageService.toggleFlaggedApp(app.packageName);
            if (mounted) setState(() {});
            final msg = StorageService.isAppFlagged(app.packageName)
                ? '${app.name} is now flagged.'
                : '${app.name} is no longer flagged.';
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
-----./screens/interception_screen.dart-----
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/material.dart';
import '../database/database_provider.dart';
import '../widgets/micro_habit_suggestion.dart';

class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  bool _reasonSelected = false;
  bool _showSuggestion = false;
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Immersive "Pause"
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Hero(
                  tag: widget.app.packageName,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.app.icon != null 
                        ? Image.memory(widget.app.icon!, width: 80, height: 80)
                        : const Icon(Icons.apps, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              if (!_showSuggestion) ...[
                Text(
                  _reasonSelected ? "You chose: $_selectedReason" : "Why are you opening ${widget.app.name}?",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 24, height: 1.4, color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (!_reasonSelected) ...[
                  _buildChoiceButton(
                    title: "Habit / Boredom",
                    isPrimary: false,
                    onTap: () => setState(() {
                      _reasonSelected = true;
                      _selectedReason = "Habit / Boredom";
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Quick Task",
                    isPrimary: false,
                    onTap: () => setState(() {
                      _reasonSelected = true;
                      _selectedReason = "Quick Task";
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Important Work",
                    isPrimary: false,
                    onTap: () => setState(() {
                      _reasonSelected = true;
                      _selectedReason = "Important Work";
                    }),
                  ),
                ] else ...[
                  // Once reason is selected, show final choices
                  _buildChoiceButton(
                    title: "Never mind, close",
                    isPrimary: true,
                    textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    onTap: () async {
                      if (_selectedReason == null) return;
                      try {
                        await db.logDecision(
                          packageName: widget.app.packageName,
                          reason: _selectedReason!,
                          opened: false,
                          resistedCompletely: true,
                        );
                      } catch (e) {
                        debugPrint('Database error: $e');
                      }
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Give me something else",
                    isPrimary: false,
                    onTap: () {
                      setState(() {
                        _showSuggestion = true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Open anyway",
                    isPrimary: false,
                    isDestructive: true,
                    onTap: () async {
                      if (_selectedReason == null) return;
                      try {
                        await db.logDecision(
                          packageName: widget.app.packageName,
                          reason: _selectedReason!,
                          opened: true,
                        );
                        await db.startSession(widget.app.packageName, widget.app.name);
                      } catch (e) {
                        debugPrint('Database error: $e');
                      }
                      InstalledApps.startApp(widget.app.packageName);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ] else ...[
                MicroHabitSuggestion(
                  onDismiss: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required bool isPrimary,
    bool isDestructive = false,
    TextStyle? textStyle,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        backgroundColor: isPrimary 
          ? Colors.white 
          : (isDestructive ? Colors.transparent : const Color(0xFF1E293B)),
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDestructive ? const BorderSide(color: Colors.white24) : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      onPressed: onTap,
      child: Text(
        title,
        style: textStyle ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
-----./screens/home_screen.dart-----
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
-----./screens/usage_dashboard_screen.dart-----
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/usage_service.dart';
import '../widgets/app_list_item.dart';
import '../services/storage_service.dart';
import '../services/native_service.dart';
import 'interception_screen.dart';

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
                  Expanded(
                    child: _sortedApps.isEmpty
                        ? const Center(
                            child: Text(
                              "No significant app usage data recorded today.",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sortedApps.length,
                            itemBuilder: (context, index) {
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
                                onLongPress: () async {
                                  await StorageService.toggleFlaggedApp(
                                    app.packageName,
                                  );
                                  if (mounted) setState(() {});
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
-----./services/native_service.dart-----
import 'package:flutter/services.dart';

class NativeService {
static const platform = MethodChannel('com.koralauncher.app/native');
  static Future<bool> isDefaultLauncher() async {
    try {
      final bool result = await platform.invokeMethod('isDefaultLauncher');
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasUsagePermission() async {
    try {
      final bool result = await platform.invokeMethod('hasUsagePermission');
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
}
-----./services/launcher_service.dart-----
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
-----./services/storage_service.dart-----
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _flaggedAppsKey = 'flagged_apps';
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
  }

  static bool isAppFlagged(String packageName) {
    return getFlaggedApps().contains(packageName);
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

}

-----./services/usage_service.dart-----
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
-----./theme/app_theme.dart-----
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
-----./widgets/micro_habit_suggestion.dart-----
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
-----./widgets/intention_setter.dart-----
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../database/database_provider.dart';

class IntentionSetter extends StatefulWidget {
  final VoidCallback onIntentionSet;
  final VoidCallback? onDismiss;
  final String? initialIntention;

  const IntentionSetter({super.key, required this.onIntentionSet, this.onDismiss, this.initialIntention});

  @override
  State<IntentionSetter> createState() => _IntentionSetterState();
}

class _IntentionSetterState extends State<IntentionSetter> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialIntention);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_controller.text.trim().isNotEmpty) {
      await StorageService.setDailyIntention(_controller.text.trim());
      await db.saveIntention(_controller.text.trim()); 
      widget.onIntentionSet();
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
              color: const Color(0xFF0F172A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "What is your intention for today?",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: "e.g. Finish my project",
                    hintStyle: TextStyle(color: Colors.white24),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Set Intention", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                if (widget.onDismiss != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text("Skip for now", style: TextStyle(color: Colors.white60)),
                  ),
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
-----./widgets/live_clock.dart-----
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
-----./widgets/app_list_item.dart-----
import 'package:installed_apps/app_info.dart';
import 'package:flutter/material.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isFlagged;
  final Duration usage;

  const AppListItem({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
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
              if (isFlagged)
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
-----./database/database_provider.dart-----
import 'kora_database.dart';

// Fix — lazy singleton
KoraDatabase? _dbInstance;
KoraDatabase get db {
  _dbInstance ??= KoraDatabase();
  return _dbInstance!;
}-----./database/kora_database.dart-----
import 'dart:io';
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
// DATABASE CLASS
// ─────────────────────────────────────────────
@DriftDatabase(tables: [Sessions, Moods, Decisions, Intentions])
class KoraDatabase extends _$KoraDatabase {
  KoraDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
-----./database/kora_database.g.dart-----
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

abstract class _$KoraDatabase extends GeneratedDatabase {
  _$KoraDatabase(QueryExecutor e) : super(e);
  $KoraDatabaseManager get managers => $KoraDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MoodsTable moods = $MoodsTable(this);
  late final $DecisionsTable decisions = $DecisionsTable(this);
  late final $IntentionsTable intentions = $IntentionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    moods,
    decisions,
    intentions,
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
}
-----./main.dart-----
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/launcher_service.dart';
import 'services/usage_service.dart';

// Fix — remove that line entirely, the lazy getter handles it
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await LauncherService.init();
  await UsageService.refreshUsage();
  runApp(const KoraLauncher());
}

class KoraLauncher extends StatelessWidget {
  const KoraLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kora Launcher',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
