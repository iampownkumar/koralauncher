import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../services/storage_service.dart';
import 'daily_limit_sheet.dart';

/// Shared long-press menu: app info, daily limit, Rising Tide switch.
void showAppLongPressMenu(
  BuildContext context,
  AppInfo app, {
  required VoidCallback onChanged,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final flagged = StorageService.isAppFlagged(app.packageName);
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      app.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.white70),
                    title: const Text('App info', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'System settings for this app',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await AndroidIntent(
                        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                        data: 'package:${app.packageName}',
                        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                      ).launch();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.white70),
                    title: const Text('Set daily limit', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Rising Tide budget for this app',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DailyLimitSheet(
                          packageName: app.packageName,
                          appLabel: app.name,
                          initialLimitMinutes: StorageService.getAppDailyLimitMinutes(
                            app.packageName,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: flagged
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: flagged
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.85)
                            : Colors.white24,
                        width: flagged ? 2 : 1,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Rising Tide on this app',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: flagged ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        flagged
                            ? 'Pause and ask before opening'
                            : 'Tap to pause before you open',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                      value: flagged,
                      activeThumbColor: Theme.of(context).primaryColor,
                      activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.45),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white12,
                      onChanged: (v) async {
                        if (StorageService.isAppFlagged(app.packageName) != v) {
                          await StorageService.toggleFlaggedApp(app.packageName);
                        }
                        setModalState(() {});
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
