import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/launcher_service.dart';
import '../services/storage_service.dart';
import '../services/usage_service.dart';
import '../services/native_service.dart';
import '../widgets/app_list_item.dart';
import '../widgets/app_long_press_menu.dart';
import '../widgets/accessibility_disclosure_sheet.dart';
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

  bool _isLaunching = false;

  Future<void> _openApp(AppInfo app) async {
    if (_isLaunching) return;
    _isLaunching = true;
    try {
      final isFlagged = StorageService.isAppFlagged(app.packageName);

      if (isFlagged) {
        _searchController.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                InterceptionScreen(app: app),
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
      _filteredApps = _apps.where((app) {
        return app.name.toLowerCase().contains(query);
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
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Dark Blur Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
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
                          // Using a lower threshold (-30) and capturing all scroll notification types
                          // for immediate, snappy closure.
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
            _openApp(_filteredApps.first);
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
            // Gate: Accessibility permission required for Rising Tide flagging.
            // If not granted, show the disclosure sheet (same as onboarding).
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
          },
          onTap: () => _openApp(app),
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
