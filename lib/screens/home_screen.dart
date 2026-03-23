import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'interception_screen.dart';
import '../widgets/app_list_item.dart';
import '../widgets/intention_setter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  bool _showIntentionSetter = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
    _checkIntention();
    _searchController.addListener(_filterApps);
  }

  void _checkIntention() {
    if (!StorageService.hasSetIntentionToday()) {
      setState(() {
        _showIntentionSetter = true;
      });
    }
  }

  Future<void> _loadApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );
    
    // Sort applications alphabetically
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
        return app.name.toLowerCase().contains(query);
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildIntentionHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                            final isFlagged = StorageService.isAppFlagged(app.packageName);
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
                                  ).then((_) => setState(() {}));
                                } else {
                                  InstalledApps.startApp(app.packageName);
                                }
                              },
                              onLongPress: () async {
                                await StorageService.toggleFlaggedApp(app.packageName);
                                if (mounted) setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      StorageService.isAppFlagged(app.packageName) 
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
          if (_showIntentionSetter)
            IntentionSetter(
              onIntentionSet: () {
                setState(() {
                  _showIntentionSetter = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIntentionHeader() {
    final intention = StorageService.getDailyIntention();
    if (intention == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S INTENTION",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            intention,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
