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
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        backgroundColor: Colors.black, // Solid dark background to fix recents glitch
        body: Stack(
          children: [
            // Dark Blur Background for premium feel over the list items as they scroll
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
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
                    child: _buildAppList(),
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
      itemCount: _filteredApps.length,
      padding: const EdgeInsets.only(bottom: 32),
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        final isFlagged = StorageService.isAppFlagged(app.packageName);
        final usage = _hasUsagePermission ? UsageService.getAppUsage(app.packageName) : Duration.zero;
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
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
