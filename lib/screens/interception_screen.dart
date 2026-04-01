import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../services/rising_tide_service.dart';
import '../models/rising_tide_stage.dart';
import '../services/rising_tide_logger.dart';
import '../services/usage_service.dart';
import '../widgets/gate_settings_sheet.dart';
import '../database/database_provider.dart';
import '../services/storage_service.dart';
  import '../services/foreground_intercept_guard.dart';
import '../services/native_service.dart';
import '../utils/limit_time_format.dart';


class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  late RisingTideStage _stage;
  bool _isLoading = true;

  int _opensToday = 0;
  int _minutesToday = 0;
  int _limitMinutes = 0;
  String? _dailyIntention;

  // Flow control
  String? _selectedMood;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  // Reopen lock display
  int _lockRemainingSeconds = 0;
  Timer? _lockTimer;
  int _overridesCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initStage();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _lockTimer?.cancel();
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
    _dailyIntention = RisingTideService.getDailyIntention();

    if (mounted) {
      setState(() {
        _stage = stage;
        _opensToday = stats['opens'] ?? 0;
        _minutesToday = stats['minutes'] ?? 0;
        _limitMinutes = RisingTideService.getAppDailyLimit(widget.app.packageName).inMinutes;
        _isLoading = false;

        _startInitialCountdown();

        _overridesCount = RisingTideService.getTodayOverrideCount(widget.app.packageName);
        final lockRemaining = RisingTideService.getRemainingLockDuration(widget.app.packageName);
        if (lockRemaining > Duration.zero) {
          _lockRemainingSeconds = lockRemaining.inSeconds;
          _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() {
              if (_lockRemainingSeconds > 0) {
                _lockRemainingSeconds--;
              } else {
                _lockTimer?.cancel();
              }
            });
          });
        }
      });
      RisingTideLogger.logAppOpen(widget.app.packageName, _stage);
    }
  }

  void _startInitialCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 5;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            _countdownTimer?.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _launchApp({bool afterInterceptionFlow = false}) async {
    final pkg = widget.app.packageName;

    await StorageService.incrementTodayOpenCount(pkg);
    await db.startSession(pkg, widget.app.name);

    // Register bypass BEFORE removing from blocklist
    ForegroundInterceptGuard.recordPostLaunchBypass(pkg,
        window: const Duration(seconds: 6));

    // Temporarily remove from native blocklist to prevent Accessibility re-intercept
    final currentBlockList = StorageService.getFlaggedApps()
        .where((p) =>
            p != pkg && RisingTideService.getStage(p) != RisingTideStage.whisper)
        .toList();
    await NativeService.sendBlockedApps(currentBlockList);

    if (mounted) Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    InstalledApps.startApp(pkg);

    // Restore the full blocklist after the app is open
    Future.delayed(const Duration(seconds: 5), () {
      RisingTideService.syncInterceptionState();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white24)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E293B).withValues(alpha: 0.65),
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (_lockRemainingSeconds > 0) _buildLockBanner(),
                  const SizedBox(height: 24),
                  _buildAppHeader(),
                  const Spacer(),
                  _buildDimContent(),
                  const Spacer(),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockBanner() {
    final mins = _lockRemainingSeconds ~/ 60;
    final secs = _lockRemainingSeconds % 60;
    final label = mins > 0
        ? 'Reopen lock: ${mins}m ${secs.toString().padLeft(2, '0')}s remaining'
        : 'Reopen lock: ${secs}s remaining';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 14, color: Colors.orange.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: widget.app.icon != null
              ? Image.memory(widget.app.icon!, width: 64, height: 64)
              : const Icon(Icons.apps, size: 64, color: Colors.white24),
        ),
        const SizedBox(height: 12),
        Text(
          widget.app.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDimContent() {
    final remaining = _limitMinutes - _minutesToday;
    final remainingClamped = remaining.clamp(0, _limitMinutes);

    return Column(
      children: [
        const Text(
          "Pause for a second.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Clear usage summary
        Text(
          "You've used ${widget.app.name} for $_minutesToday ${_minutesToday == 1 ? 'minute' : 'minutes'} today.",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "You have $remainingClamped ${remainingClamped == 1 ? 'minute' : 'minutes'} left.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Progress bar
        _buildUsageBar(),
        const SizedBox(height: 8),
        Text(
          'Opens: $_opensToday${_overridesCount > 0 ? ' · Overrides: $_overridesCount' : ''} · Limit ${LimitTimeFormat.dualLabel(_limitMinutes)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          textAlign: TextAlign.center,
        ),
        _buildGateSettingsLink(),
        const SizedBox(height: 24),
        if (_dailyIntention != null) ...[
          Text(
            '"$_dailyIntention"',
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
        _buildMoodSelector(),
      ],
    );
  }

  Widget _buildUsageBar() {
    final progress = _limitMinutes > 0
        ? (_minutesToday / _limitMinutes).clamp(0.0, 1.0)
        : 0.0;
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: 6,
        width: constraints.maxWidth * 0.7,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: constraints.maxWidth * 0.7 * progress,
            height: 6,
            decoration: BoxDecoration(
              color: progress >= 0.9
                  ? Colors.redAccent
                  : progress >= 0.7
                      ? Colors.orange
                      : Colors.white70,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    });
  }

  void _showGateSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => GateSettingsSheet(
        packageName: widget.app.packageName,
        appLabel: widget.app.name,
        initialLimitMinutes: StorageService.getAppDailyLimitMinutes(
          widget.app.packageName,
        ),
        initialIntention: _dailyIntention,
        onApply: (limit, intentionText) async {
          await StorageService.setAppDailyLimitMinutes(
            widget.app.packageName,
            limit,
          );
          if (intentionText != null && intentionText.isNotEmpty) {
            await StorageService.setDailyIntention(intentionText);
            await db.saveIntention(intentionText);
          }
          RisingTideService.invalidateIntentionCache();
          await RisingTideService.syncInterceptionState();
          await UsageService.refreshUsage();
          final newStage = RisingTideService.getStage(widget.app.packageName);
          if (!mounted) return;
          if (newStage == RisingTideStage.whisper) {
            await _launchApp();
            return;
          }
          final stats = await RisingTideService.getStats(widget.app.packageName);
          if (mounted) {
            setState(() {
              _opensToday = stats['opens'] ?? 0;
              _minutesToday = stats['minutes'] ?? 0;
              _limitMinutes = limit;
              _dailyIntention = RisingTideService.getDailyIntention();
            });
          }
        },
      ),
    );
  }

  Widget _buildGateSettingsLink() {
    return TextButton.icon(
      onPressed: _showGateSettings,
      icon: Icon(Icons.tune, size: 16, color: Colors.white.withValues(alpha: 0.35)),
      label: Text(
        'Edit limit & optional note',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = [
      {'label': '😌 Relaxing', 'id': 'relaxing'},
      {'label': '😤 Procrastinating', 'id': 'procrastinating'},
      {'label': '🎯 Taking a break', 'id': 'break'},
      {'label': '😶 Just habit', 'id': 'habit'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: moods.map((m) {
        final isSelected = _selectedMood == m['id'];
        return GestureDetector(
          onTap: () {
            setState(() => _selectedMood = m['id'] as String);
            RisingTideLogger.logMoodSelected(
              widget.app.packageName,
              m['id'] as String,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white12,
              ),
            ),
            child: Text(
              m['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    final bool moodRequired = _selectedMood == null;
    final bool countdownActive = _countdownSeconds > 0;
    final bool disabled = moodRequired || countdownActive;

    return Column(
      children: [
        _buildGlassButton(
          title: "Never mind, go back",
          onTap: () async {
            RisingTideLogger.logDecision(
              widget.app.packageName,
              "goback",
              _selectedMood ?? "none",
            );
            if (mounted) Navigator.pop(context);
          },
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildGlassButton(
          title: countdownActive
              ? "Wait ${_countdownSeconds}s…"
              : moodRequired
                  ? "Select a mood first"
                  : "Continue anyway",
          onTap: disabled
              ? null
              : () async {
                  RisingTideLogger.logDecision(
                    widget.app.packageName,
                    "continue",
                    _selectedMood ?? "conscious",
                  );
                  await RisingTideService.recordOverride(widget.app.packageName);
                  await RisingTideService.setReopenLock(widget.app.packageName);
                  await _launchApp(afterInterceptionFlow: true);
                },
          isPrimary: false,
          isDisabled: disabled,
          isCountdown: countdownActive,
          countdownProgress: countdownActive ? (5 - _countdownSeconds) / 5.0 : 1.0,
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required String title,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isDisabled = false,
    bool isCountdown = false,
    double countdownProgress = 0.0,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDisabled && !isCountdown ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.white
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCountdown
                  ? Colors.white.withValues(alpha: 0.25 + 0.35 * countdownProgress)
                  : Colors.white10,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isCountdown)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.linear,
                        widthFactor: countdownProgress,
                        child: Container(color: Colors.white.withValues(alpha: 0.07)),
                      ),
                    ),
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
