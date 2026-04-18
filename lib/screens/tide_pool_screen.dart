import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import '../services/storage_service.dart';
import '../services/launcher_service.dart';
import '../services/native_service.dart';
import '../services/usage_service.dart';
import '../utils/limit_time_format.dart';
import '../widgets/daily_limit_sheet.dart';
import '../widgets/app_long_press_menu.dart';
import '../widgets/accessibility_disclosure_sheet.dart';
import '../widgets/permission_gate_card.dart';

/// Swipe in from the right — calm “breathing room” + flagged apps at a glance.
class TidePoolScreen extends StatefulWidget {
  const TidePoolScreen({super.key});

  @override
  State<TidePoolScreen> createState() => _TidePoolScreenState();
}

class _TidePoolScreenState extends State<TidePoolScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _hasAccessibility = true; // optimistic until first check

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    final has = await NativeService.hasAccessibilityPermission();
    if (mounted) setState(() => _hasAccessibility = has);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAccessibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      displayApps = allApps
          .where((a) => flagged.contains(a.packageName))
          .toList();
    } else {
      final cleanQuery = _searchQuery.replaceAll(' ', '');
      displayApps = allApps
          .where((app) {
            final cleanName = app.name.toLowerCase().replaceAll(' ', '');
            final pkg = app.packageName.toLowerCase();
            return cleanName.contains(cleanQuery) || pkg.contains(cleanQuery);
          })
          .toList();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -150) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        floatingActionButton: _searchQuery.isEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                },
                label: const Text(
                  'Add App to Flag',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.add),
                backgroundColor: Colors.cyan.withOpacity(0.8),
                foregroundColor: Colors.black,
              )
            : null,
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
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  child: Text(
                    'What you give attention to, grows.\n'
                    'Use this side when you want a pause before the scroll.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      height: 1.5,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search any app to flag...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white38,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchFocusNode.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.waves,
                          color: _hasAccessibility
                              ? Colors.cyanAccent
                              : Colors.white30,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rising Tide',
                                style: TextStyle(
                                  color: _hasAccessibility
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _hasAccessibility
                                    ? (StorageService.isRisingTideMasterEnabled()
                                          ? 'Gates are active for flagged apps'
                                          : 'Gates are off — same as home switch')
                                    : 'Accessibility required',
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: _hasAccessibility ? 0.5 : 0.3,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          // Force OFF when accessibility is missing
                          value:
                              _hasAccessibility &&
                              StorageService.isRisingTideMasterEnabled(),
                          activeThumbColor: Colors.cyanAccent,
                          activeTrackColor: Colors.cyan.withOpacity(0.45),
                          inactiveThumbColor: Colors.white24,
                          inactiveTrackColor: Colors.white10,
                          onChanged: (v) async {
                            if (!_hasAccessibility) {
                              // Gate: show disclosure first
                              if (!context.mounted) return;
                              // ignore: use_build_context_synchronously
                              await AccessibilityDisclosureSheet.show(context);
                              await _checkAccessibility();
                              return;
                            }
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
                      color: Colors.white.withValues(
                        alpha: _hasAccessibility ? 0.4 : 0.2,
                      ),
                      letterSpacing: 3,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!_hasAccessibility && _searchQuery.isEmpty)
                  Expanded(
                    child: PermissionGateCard(
                      icon: Icons.security_outlined,
                      title: 'Enable Accessibility',
                      body:
                          'Accessibility is required to flag apps for Rising Tide.',
                      buttonLabel: 'Enable Accessibility',
                      onButton: () async {
                        // ignore: use_build_context_synchronously
                        await AccessibilityDisclosureSheet.show(context);
                        await _checkAccessibility();
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Opacity(
                      opacity: _hasAccessibility ? 1.0 : 0.35,
                      child: AbsorbPointer(
                        absorbing: !_hasAccessibility,
                        child: displayApps.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No apps flagged yet.\nSearch above to find an app to flag,\nor long-press an app in the drawer.'
                                      : 'No apps found matching "$_searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    height: 1.45,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  32,
                                ),
                                itemCount: displayApps.length,
                                itemBuilder: (context, i) {
                                  final app = displayApps[i];
                                  final pkg = app.packageName;
                                  final isFlagged = StorageService.isAppFlagged(
                                    pkg,
                                  );
                                  final limit =
                                      StorageService.getAppDailyLimitMinutes(
                                        pkg,
                                      );
                                  final usedMinutes =
                                      UsageService.getRoundedMinutesToday(pkg);
                                  final remaining = (limit - usedMinutes).clamp(
                                    0,
                                    limit,
                                  );
                                  final progress = limit > 0
                                      ? (usedMinutes / limit).clamp(0.0, 1.0)
                                      : 0.0;
                                  return Card(
                                    color: isFlagged
                                        ? Colors.cyan.withOpacity(0.08)
                                        : Colors.white.withOpacity(0.04),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isFlagged
                                            ? Colors.cyan.withOpacity(0.3)
                                            : Colors.white10,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: isFlagged
                                          ? const Icon(
                                              Icons.waves,
                                              color: Colors.cyanAccent,
                                              size: 20,
                                            )
                                          : const Icon(
                                              Icons.waves,
                                              color: Colors.white24,
                                              size: 20,
                                            ),
                                      title: Text(
                                        app.name,
                                        style: TextStyle(
                                          color: isFlagged
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: isFlagged
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      subtitle: isFlagged
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text(
                                                  usedMinutes > 0
                                                      ? '${usedMinutes}m used · ${remaining}m left of ${LimitTimeFormat.dualLabel(limit)}'
                                                      : 'Limit: ${LimitTimeFormat.dualLabel(limit)} · Not used today',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.45,
                                                        ),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: progress,
                                                    minHeight: 3,
                                                    backgroundColor:
                                                        Colors.white12,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          progress >= 1.0
                                                              ? Colors.redAccent
                                                              : progress >= 0.5
                                                              ? Colors.orange
                                                              : Colors
                                                                    .cyanAccent,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'Not flagged',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                              ),
                                            ),
                                      trailing: isFlagged
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.tune,
                                                color: Colors.white54,
                                              ),
                                              onPressed: () {
                                                showModalBottomSheet<void>(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (context) =>
                                                      DailyLimitSheet(
                                                        packageName:
                                                            app.packageName,
                                                        appLabel: app.name,
                                                        initialLimitMinutes:
                                                            limit,
                                                      ),
                                                ).then((_) {
                                                  if (mounted) setState(() {});
                                                });
                                              },
                                            )
                                          : IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.white38,
                                              ),
                                              onPressed: () async {
                                                await StorageService.toggleFlaggedApp(
                                                  pkg,
                                                );
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
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Swipe left to return home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
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
