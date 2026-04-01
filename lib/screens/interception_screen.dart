import 'dart:async';
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

/// Rising Tide Stage 2 — Dim Gate
///
/// Shown when the user opens a flagged app at ≥50% of their daily limit.
/// The gate is unskippable for 10 seconds. After that the user must make
/// a CONSCIOUS CHOICE:
///   • "Open anyway"  → records decision, app opens, gate won't fire again today
///   • "Close"        → does NOT record, so gate fires again next open
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

  // Countdown
  int _countdown = 10;
  Timer? _countdownTimer;
  bool get _canAct => _countdown == 0;

  // Fade-in
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initStage();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
    if (!mounted) return;

    setState(() {
      _minutesToday = stats['minutes'] ?? 0;
      _limitMinutes = RisingTideService.getAppDailyLimit(widget.app.packageName).inMinutes;
      _isLoading = false;
    });

    _fadeController.forward();
    RisingTideLogger.logAppOpen(widget.app.packageName, stage);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  /// Launches the app WITHOUT recording a conscious decision.
  /// Used internally — not called on user action.
  Future<void> _launchApp() async {
    final pkg = widget.app.packageName;

    await StorageService.incrementTodayOpenCount(pkg);
    await db.startSession(pkg, widget.app.name);

    ForegroundInterceptGuard.recordPostLaunchBypass(pkg,
        window: const Duration(seconds: 6));

    // Atomically remove this app from the native blocklist to prevent
    // AccessibilityWatcherService from re-intercepting during the launch.
    final currentBlockList = StorageService.getFlaggedApps()
        .where((p) =>
            p != pkg && RisingTideService.getStage(p) != RisingTideStage.whisper)
        .toList();
    await NativeService.sendBlockedApps(currentBlockList);

    if (mounted) Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    InstalledApps.startApp(pkg);

    // Restore full blocklist after a safe delay
    Future.delayed(const Duration(seconds: 5), () {
      RisingTideService.syncInterceptionState();
    });
  }

  /// User consciously chose to open. Records the decision so gate won't fire again today.
  Future<void> _onOpenAnyway() async {
    if (!_canAct) return;
    await RisingTideService.markUserDecision(widget.app.packageName);
    RisingTideLogger.logDecision(widget.app.packageName, "open_anyway", "conscious");
    await _launchApp();
  }

  /// User chose to close. Does NOT record the decision — gate will fire again next open.
  void _onClose() {
    RisingTideLogger.logDecision(widget.app.packageName, "close", "none");
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

    final remaining = (_limitMinutes - _minutesToday).clamp(0, _limitMinutes);
    final progress = _limitMinutes > 0
        ? (_minutesToday / _limitMinutes).clamp(0.0, 1.0)
        : 0.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2232),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: widget.app.icon != null
                            ? Image.memory(widget.app.icon!, width: 56, height: 56)
                            : const Icon(Icons.apps, size: 56, color: Colors.white24),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      const Text(
                        "Heads up",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Usage message
                      Text(
                        "You've used ${widget.app.name} for "
                        "$_minutesToday ${_minutesToday == 1 ? 'minute' : 'minutes'} today.\n"
                        "You have $remaining ${remaining == 1 ? 'minute' : 'minutes'} left "
                        "of your ${LimitTimeFormat.dualLabel(_limitMinutes)} limit.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Usage progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          color: progress >= 1.0
                              ? Colors.redAccent
                              : progress >= 0.75
                                  ? Colors.orange
                                  : Colors.white70,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Close button (immediately available)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _onClose,
                          child: Text(
                            "Close",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // "Open anyway" — greyed and disabled for 10 seconds
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: _canAct ? 1.0 : 0.35,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _canAct ? _onOpenAnyway : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.white24,
                              disabledForegroundColor: Colors.white38,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _canAct
                                  ? "Open anyway"
                                  : "Open anyway  ($_countdown)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
