import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/storage_service.dart';
import '../services/launcher_service.dart';
import '../utils/limit_time_format.dart';
import '../widgets/daily_limit_sheet.dart';
import '../widgets/app_long_press_menu.dart';

/// Swipe in from the right — calm “breathing room” + flagged apps at a glance.
class TidePoolScreen extends StatefulWidget {
  const TidePoolScreen({super.key});

  @override
  State<TidePoolScreen> createState() => _TidePoolScreenState();
}

class _TidePoolScreenState extends State<TidePoolScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flagged = StorageService.getFlaggedApps();
    final allApps = LauncherService.cachedApps
        .where((app) => !app.packageName.contains('koralauncher'))
        .toList();

    List<AppInfo> displayApps;
    if (_searchQuery.isEmpty) {
      displayApps = allApps.where((a) => flagged.contains(a.packageName)).toList();
    } else {
      displayApps = allApps
          .where((app) => app.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        floatingActionButton: _searchQuery.isEmpty ? FloatingActionButton.extended(
          onPressed: () {
            FocusScope.of(context).requestFocus(_searchFocusNode);
          },
          label: const Text('Add App to Flag', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.cyan.withValues(alpha: 0.8),
          foregroundColor: Colors.black,
        ) : null,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020617),
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
              stops: [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Tide pool',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Text(
                    'What you give attention to, grows.\n'
                    'Use this side when you want a pause before the scroll.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.5,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search any app to flag...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.waves, color: Colors.cyanAccent, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rising Tide',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                StorageService.isRisingTideMasterEnabled()
                                    ? 'Gates are active for flagged apps'
                                    : 'Gates are off — same as home switch',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: StorageService.isRisingTideMasterEnabled(),
                          activeThumbColor: Colors.cyanAccent,
                          activeTrackColor: Colors.cyan.withValues(alpha: 0.45),
                          onChanged: (v) async {
                            await StorageService.setRisingTideMasterEnabled(v);
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _searchQuery.isEmpty ? 'FLAGGED APPS' : 'SEARCH RESULTS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 3,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: displayApps.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No apps flagged yet.\nSearch above to find an app to flag,\nor long-press an app in the drawer.'
                                : 'No apps found matching "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              height: 1.45,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: displayApps.length,
                          itemBuilder: (context, i) {
                            final app = displayApps[i];
                            final pkg = app.packageName;
                            final isFlagged = StorageService.isAppFlagged(pkg);
                            final limit = StorageService.getAppDailyLimitMinutes(pkg);
                            return Card(
                              color: isFlagged 
                                  ? Colors.cyan.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isFlagged ? Colors.cyan.withValues(alpha: 0.3) : Colors.white10,
                                ),
                              ),
                              child: ListTile(
                                leading: isFlagged 
                                    ? const Icon(Icons.waves, color: Colors.cyanAccent, size: 20)
                                    : const Icon(Icons.waves, color: Colors.white24, size: 20),
                                title: Text(
                                  app.name,
                                  style: TextStyle(
                                    color: isFlagged ? Colors.white : Colors.white70,
                                    fontWeight: isFlagged ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                subtitle: isFlagged
                                    ? Text(
                                        'Limit ${LimitTimeFormat.dualLabel(limit)}',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                                      )
                                    : Text(
                                        'Not flagged',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                                      ),
                                trailing: isFlagged
                                    ? IconButton(
                                        icon: const Icon(Icons.tune, color: Colors.white54),
                                        onPressed: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => DailyLimitSheet(
                                              packageName: app.packageName,
                                              appLabel: app.name,
                                              initialLimitMinutes: limit,
                                            ),
                                          );
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.white38),
                                        onPressed: () async {
                                          await StorageService.toggleFlaggedApp(pkg);
                                          if (mounted) setState(() {});
                                        },
                                      ),
                                onTap: () {
                                  showAppLongPressMenu(
                                    context,
                                    app,
                                    onChanged: () => setState(() {}),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Swipe right to return home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
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
}
