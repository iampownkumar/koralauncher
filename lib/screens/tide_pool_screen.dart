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
  @override
  Widget build(BuildContext context) {
    final flagged = StorageService.getFlaggedApps();
    final apps = LauncherService.cachedApps;
    AppInfo? findApp(String pkg) {
      try {
        return apps.firstWhere((a) => a.packageName == pkg);
      } catch (_) {
        return null;
      }
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF020617),
                Color(0xFF0C4A6E),
                Color(0xFF020617),
              ],
              stops: [0.0, 0.45, 1.0],
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
                        Icon(Icons.waves, color: Theme.of(context).primaryColor, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                          activeThumbColor: Theme.of(context).primaryColor,
                          activeTrackColor:
                              Theme.of(context).primaryColor.withValues(alpha: 0.45),
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
                    'FLAGGED APPS',
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
                  child: flagged.isEmpty
                      ? Center(
                          child: Text(
                            'No apps flagged yet.\nSwipe up on the home screen → long-press an app → turn on Rising Tide,\nor tap the wave icon on a row.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              height: 1.45,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: flagged.length,
                          itemBuilder: (context, i) {
                            final pkg = flagged[i];
                            final app = findApp(pkg);
                            final label = app?.name ?? pkg;
                            final limit = StorageService.getAppDailyLimitMinutes(pkg);
                            return Card(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              child: ListTile(
                                title: Text(
                                  label,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Limit ${LimitTimeFormat.dualLabel(limit)}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.tune, color: Colors.white54),
                                  onPressed: app == null
                                      ? null
                                      : () {
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
                                ),
                                onTap: app == null
                                    ? null
                                    : () {
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
