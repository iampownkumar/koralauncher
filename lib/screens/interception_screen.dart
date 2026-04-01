import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../services/rising_tide_service.dart';
import '../models/rising_tide_stage.dart';
import '../services/rising_tide_logger.dart';
import '../services/usage_service.dart';
import '../database/database_provider.dart';
import '../services/storage_service.dart';
import '../services/foreground_intercept_guard.dart';
import '../services/native_service.dart';
import '../utils/limit_time_format.dart';

/// A single gentle reminder shown when a user reaches their daily time limit.
/// Shown ONCE per day. After tapping "Continue", the app opens and no more gates fire today.
class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _minutesToday = 0;
  int _limitMinutes = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initStage();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initStage() async {
    await UsageService.refreshUsage();
    final stage = RisingTideService.getStage(widget.app.packageName);

    if (stage == RisingTideStage.whisper) {
      await _launchApp();
      return;
    }

    final stats = await RisingTideService.getStats(widget.app.packageName);
    if (mounted) {
      setState(() {
        _minutesToday = stats['minutes'] ?? 0;
        _limitMinutes = RisingTideService.getAppDailyLimit(widget.app.packageName).inMinutes;
        _isLoading = false;
      });
      _fadeController.forward();
      RisingTideLogger.logAppOpen(widget.app.packageName, stage);
    }
  }

  Future<void> _launchApp() async {
    final pkg = widget.app.packageName;

    await StorageService.incrementTodayOpenCount(pkg);
    await db.startSession(pkg, widget.app.name);

    // Register bypass BEFORE removing from blocklist
    ForegroundInterceptGuard.recordPostLaunchBypass(pkg,
        window: const Duration(seconds: 6));

    // Atomically remove this app from the native blocklist so the Accessibility
    // service cannot re-fire during the launch transition.
    final currentBlockList = StorageService.getFlaggedApps()
        .where((p) =>
            p != pkg && RisingTideService.getStage(p) != RisingTideStage.whisper)
        .toList();
    await NativeService.sendBlockedApps(currentBlockList);

    if (mounted) Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    InstalledApps.startApp(pkg);

    // Restore the full blocklist after launch
    Future.delayed(const Duration(seconds: 5), () {
      RisingTideService.syncInterceptionState();
    });
  }

  Future<void> _onContinue() async {
    // Mark the limit warning as shown for today so the gate won't fire again
    await RisingTideService.markLimitWarningShown(widget.app.packageName);
    RisingTideLogger.logDecision(widget.app.packageName, "continue", "conscious");
    await _launchApp();
  }

  void _onGoBack() {
    RisingTideLogger.logDecision(widget.app.packageName, "goback", "none");
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    final overMinutes = (_minutesToday - _limitMinutes).clamp(0, 99999);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
            // Content card
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: widget.app.icon != null
                            ? Image.memory(widget.app.icon!,
                                width: 52, height: 52)
                            : const Icon(Icons.apps,
                                size: 52, color: Colors.white24),
                      ),
                      const SizedBox(height: 20),

                      // Headline
                      Text(
                        "Time's up for today.",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Usage summary
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          children: [
                            TextSpan(
                              text:
                                  "You've used ${widget.app.name} for $_minutesToday ${_minutesToday == 1 ? 'minute' : 'minutes'} today",
                            ),
                            if (overMinutes > 0)
                              TextSpan(
                                text:
                                    " — ${overMinutes} ${overMinutes == 1 ? 'minute' : 'minutes'} over your ${LimitTimeFormat.dualLabel(_limitMinutes)} limit",
                              )
                            else
                              TextSpan(
                                text:
                                    ", your ${LimitTimeFormat.dualLabel(_limitMinutes)} limit",
                              ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _onContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Open anyway",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Go back button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _onGoBack,
                          child: Text(
                            "Go back",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
