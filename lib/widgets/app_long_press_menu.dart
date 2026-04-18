import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../services/storage_service.dart';
import '../services/native_service.dart';
import 'daily_limit_sheet.dart';
import 'accessibility_disclosure_sheet.dart';

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
          return FutureBuilder<bool>(
            future: NativeService.hasAccessibilityPermission(),
            builder: (context, snapshot) {
              final hasAccess = snapshot.data ?? true;
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
                        leading: const Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'App info',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'System settings for this app',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
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
                        leading: Icon(
                          Icons.schedule,
                          color: hasAccess ? Colors.white70 : Colors.white24,
                        ),
                        title: Text(
                          'Set daily limit',
                          style: TextStyle(
                            color: hasAccess ? Colors.white : Colors.white38,
                          ),
                        ),
                        subtitle: Text(
                          hasAccess
                              ? 'Rising Tide budget for this app'
                              : 'Accessibility permission required',
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: hasAccess ? 0.45 : 0.25,
                            ),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () async {
                          if (!hasAccess) {
                            await AccessibilityDisclosureSheet.show(context);
                            setModalState(() {});
                            return;
                          }
                          Navigator.pop(ctx);
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DailyLimitSheet(
                              packageName: app.packageName,
                              appLabel: app.name,
                              initialLimitMinutes:
                                  StorageService.getAppDailyLimitMinutes(
                                    app.packageName,
                                  ),
                            ),
                          ).then((_) {
                            onChanged();
                          });
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: flagged
                              ? Colors.cyanAccent.withOpacity(0.1)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: flagged
                                ? Colors.cyanAccent.withOpacity(0.6)
                                : Colors.white24,
                            width: flagged ? 2 : 1,
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Rising Tide on this app',
                            style: TextStyle(
                              color: hasAccess ? Colors.white : Colors.white38,
                              fontWeight: flagged ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            hasAccess
                                ? (flagged
                                    ? 'Pause and ask before opening'
                                    : 'Tap to pause before you open')
                                : 'Accessibility required',
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: hasAccess ? 0.55 : 0.3,
                              ),
                              fontSize: 13,
                            ),
                          ),
                          value: hasAccess && flagged,
                          activeThumbColor: Colors.cyanAccent,
                          activeTrackColor: Colors.cyan.withOpacity(0.45),
                          inactiveThumbColor: Colors.white24,
                          inactiveTrackColor: Colors.white10,
                          onChanged: (v) async {
                            if (!hasAccess) {
                              await AccessibilityDisclosureSheet.show(context);
                              setModalState(() {});
                              return;
                            }
                            if (StorageService.isAppFlagged(app.packageName) != v) {
                              await StorageService.toggleFlaggedApp(
                                app.packageName,
                              );
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
    },
  );
}
