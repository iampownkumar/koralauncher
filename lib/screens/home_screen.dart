import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'interception_screen.dart';
import '../widgets/app_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
    _searchController.addListener(_filterApps);
  }

  Future<void> _loadApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );
    
    // Sort applications alphabetically
    apps.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));

    if (mounted) {
      setState(() {
        _apps = apps;
        _filteredApps = _apps;
        _isLoading = false;
      });
    }
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _apps.where((app) {
        return app.name!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: TextField(
                controller: _searchController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredApps.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final isFlagged = StorageService.isAppFlagged(app.packageName!);
                        return AppListItem(
                          app: app,
                          isFlagged: isFlagged,
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
                              InstalledApps.startApp(app.packageName!);
                            }
                          },
                          onLongPress: () async {
                            await StorageService.toggleFlaggedApp(app.packageName!);
                            if (mounted) setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  StorageService.isAppFlagged(app.packageName!) 
                                    ? '${app.name} is now flagged for interception.'
                                    : '${app.name} is no longer flagged.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
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
}
