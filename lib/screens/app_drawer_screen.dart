import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import '../services/launcher_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import '../widgets/app_long_press_menu.dart';
import '../widgets/accessibility_disclosure_sheet.dart';
import 'interception_screen.dart';

class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  List<AppEntry> _apps = [];
  List<AppEntry> _filteredApps = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasUsagePermission = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _checkPermissionsAndLoad();
    _searchController.addListener(_filterApps);
    // Request focus for search bar when drawer opens
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _searchFocusNode.unfocus();
      // Remove the drawer route WITHOUT animation.  Using pop() here would
      // trigger the reverse slide transition, which plays visibly as a
      // "rushing to close" effect during the recents screen.  removeRoute
      // instantly deletes the route from the stack — no animation, no flash.
      final route = ModalRoute.of(context);
      if (route != null && mounted) {
        Navigator.of(context).removeRoute(route);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLoad() async {
    final hasUsage = await NativeService.hasUsagePermission();
    setState(() {
      _hasUsagePermission = hasUsage;
      _apps = LauncherService.cachedEntries;
      _filteredApps = _apps;
    });
  }

  bool _isLaunching = false;

  Future<void> _openApp(AppEntry app) async {
    if (_isLaunching) return;
    _isLaunching = true;
    try {
      // Pinned shortcuts (browser desktop shortcuts) — launch via intent URI or shortcut ID
      if (app.isShortcut) {
        _searchController.clear();
        await NativeService.launchShortcut(
          intentUri: app.intentUri,
          targetPackage: app.targetPackage,
          shortcutId: app.shortcutId,
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      // Regular apps — check Rising Tide flag first
      final isFlagged = StorageService.isRisingTideMasterEnabled() &&
          StorageService.isAppFlagged(app.packageName);
      if (isFlagged) {
        _searchController.clear();
        // Build a minimal AppInfo to pass to InterceptionScreen
        final appInfo = LauncherService.cachedApps
            .firstWhere((a) => a.packageName == app.packageName);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                InterceptionScreen(app: appInfo),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      } else {
        await LauncherService.launchApp(app.packageName);
        _searchController.clear();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error launching app: $e");
    } finally {
      if (mounted) {
        _isLaunching = false;
      }
    }
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _apps.where((entry) {
        return entry.name.toLowerCase().contains(query);
      }).toList();
    });

    if (_filteredApps.length == 1 && query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openApp(_filteredApps.first);
        }
      });
    }
  }

  Future<void> _refreshData() async {
    await LauncherService.refreshApps();
    await UsageService.refreshUsage();
    if (mounted) {
      setState(() {
        _apps = LauncherService.cachedEntries;
        _filterApps();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
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
          backgroundColor: Colors.transparent,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Dark translucent background with subtle blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0A0A1A).withValues(alpha: 0.95),
                            const Color(0xFF050510).withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildSearchField(),
                      if (_searchController.text.isEmpty) _buildQuickStats(),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            // Detect when user is at the top AND pulls down (overscroll)
                            if (notification.metrics.pixels <= -30) {
                              _searchFocusNode.unfocus();
                              Navigator.maybePop(context);
                              return true;
                            }
                            return false;
                          },
                          child: _buildAppList(),
                        ),
                      ),
                      // Space for keyboard when resizeToAvoidBottomInset is false
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          onSubmitted: (_) {
            if (_filteredApps.isNotEmpty) {
              _openApp(_filteredApps.first);
            }
          },
          decoration: InputDecoration(
            hintText: 'Search apps...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _searchFocusNode.requestFocus();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 18,
                    ),
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Quick stats bar showing total apps and flagged count
  Widget _buildQuickStats() {
    final flaggedCount = StorageService.getFlaggedApps().length;
    final totalUsage = _hasUsagePermission
        ? UsageService.getVisibleTotalUsage(minRoundedMinutes: 1)
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: [
          _statChip(
            '${_apps.length} apps',
            Icons.apps_rounded,
            Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          if (flaggedCount > 0)
            _statChip(
              '$flaggedCount flagged',
              Icons.waves,
              const Color(0xFF06B6D4),
            ),
          const SizedBox(width: 8),
          if (_hasUsagePermission && totalUsage.inMinutes > 0)
            _statChip(
              UsageService.formatDuration(totalUsage),
              Icons.access_time_rounded,
              Colors.white.withValues(alpha: 0.4),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList() {
    if (_apps.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
      );
    }

    // Separate flagged apps to show at top when not searching
    final isSearching = _searchController.text.isNotEmpty;
    List<AppEntry> displayApps = _filteredApps;
    int flaggedSectionCount = 0;

    if (!isSearching) {
      final flagged = _filteredApps
          .where((a) => !a.isShortcut && StorageService.isAppFlagged(a.packageName))
          .toList();
      final unflagged = _filteredApps
          .where((a) => a.isShortcut || !StorageService.isAppFlagged(a.packageName))
          .toList();
      flaggedSectionCount = flagged.length;
      displayApps = [...flagged, ...unflagged];
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: displayApps.length + (flaggedSectionCount > 0 ? 2 : 0),
      padding: const EdgeInsets.only(bottom: 32),
      itemBuilder: (context, index) {
        // Section headers for flagged apps
        if (flaggedSectionCount > 0) {
          if (index == 0) {
            return _buildSectionHeader('FLAGGED', const Color(0xFF06B6D4));
          }
          if (index == flaggedSectionCount + 1) {
            return _buildSectionHeader('ALL APPS', Colors.white.withValues(alpha: 0.3));
          }
          // Adjust index for actual app data
          final appIndex = index <= flaggedSectionCount
              ? index - 1
              : index - 2;
          if (appIndex >= displayApps.length) return const SizedBox.shrink();
          return _buildAppTile(displayApps[appIndex]);
        }

        return _buildAppTile(displayApps[index]);
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildAppTile(AppEntry app) {
    final isFlagged =
        !app.isShortcut && StorageService.isAppFlagged(app.packageName);
    final usage = (!app.isShortcut && _hasUsagePermission)
        ? UsageService.getAppUsage(app.packageName)
        : Duration.zero;
    final usageMinutes = (usage.inMilliseconds + 30000) ~/ 60000;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isFlagged
            ? const Color(0xFF06B6D4).withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isFlagged
            ? Border.all(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openApp(app),
          onLongPress: () => _handleLongPress(app),
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF06B6D4).withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // App icon with subtle shadow
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Hero(
                      tag: app.packageName,
                      child: app.icon != null
                          ? Image.memory(app.icon!, fit: BoxFit.cover)
                          : const Icon(Icons.apps, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // App name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: TextStyle(
                          color: isFlagged
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight:
                              isFlagged ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (usageMinutes > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _formatUsage(usage),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Flag indicator
                if (!app.isShortcut)
                  GestureDetector(
                    onTap: () => _handleFlagTap(app),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.waves,
                        size: 20,
                        color: isFlagged
                            ? const Color(0xFF06B6D4)
                            : Colors.white.withValues(alpha: 0.12),
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

  void _handleFlagTap(AppEntry app) async {
    final hasAccess = await NativeService.hasAccessibilityPermission();
    if (!hasAccess) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      await AccessibilityDisclosureSheet.show(context);
      if (mounted) setState(() {});
      return;
    }
    await StorageService.toggleFlaggedApp(app.packageName);
    if (mounted) setState(() {});
  }

  void _handleLongPress(AppEntry app) {
    if (app.isShortcut) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Shortcut'),
          content: Text('Remove ${app.name} from your apps?'),
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                final String id =
                    app.packageName.replaceFirst('shortcut_', '');
                await NativeService.removeShortcut(id);
                _refreshData();
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    } else {
      final appInfo = LauncherService.cachedApps
          .firstWhere((a) => a.packageName == app.packageName);
      showAppLongPressMenu(
        context,
        appInfo,
        onChanged: () {
          if (mounted) setState(() {});
        },
      );
    }
  }

  String _formatUsage(Duration d) {
    final totalMinutes = (d.inMilliseconds + 30000) ~/ 60000;
    if (totalMinutes <= 0) return "";
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return "${hours}h ${minutes}m today";
    return "${minutes}m today";
  }
}
