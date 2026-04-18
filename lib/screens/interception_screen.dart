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
import '../services/todo_service.dart';
import '../ai/ai_prompt_engine.dart';

class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  late RisingTideStage _stage;
  bool _isLoading = true;
  // Stats for Stage 2–4
  int _opensToday = 0;
  int _minutesToday = 0;
  String? _dailyIntention;

  // AI-generated interception message
  String? _aiMessage;
  bool _isAIGenerated = false;

  // Flow control
  int _countdownSeconds = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Defer init until after first frame so the route is fully mounted.
    // Without this, Navigator.pop() called from Whisper fast-path crashes
    // because the route isn't yet in the navigator stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initStage();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initStage() async {
    await UsageService.refreshUsage();
    final stage = RisingTideService.getStage(widget.app.packageName);

    if (stage == RisingTideStage.whisper) {
      // Whisper: no interception, launch directly
      await _launchApp();
      return;
    }

    final stats = await RisingTideService.getStats(widget.app.packageName);
    _dailyIntention = RisingTideService.getDailyIntention();

    // Generate humanised AI message (cached / on-device AI / template fallback)
    AIMessage aiMsg = const AIMessage(text: '', source: AIMessageSource.none);
    try {
      aiMsg = await AIPromptEngine.generateMessage(
        packageName: widget.app.packageName,
        appName: widget.app.name,
        stage: stage,
      );
    } catch (e) {
      debugPrint('InterceptionScreen: AI message generation failed: $e');
    }

    if (mounted) {
      setState(() {
        _stage = stage;
        _opensToday = stats['opens'] ?? 0;
        _minutesToday = stats['minutes'] ?? 0;
        _aiMessage = aiMsg.hasMessage ? aiMsg.text : null;
        _isAIGenerated = aiMsg.isAIGenerated;
        _isLoading = false;
        _startInitialCountdown();
      });
      RisingTideLogger.logAppOpen(widget.app.packageName, _stage);
    }
  }

  void _startInitialCountdown() {
    _countdownTimer?.cancel();
    // Dim is unskippable for 10s; Mirror/others use 5s
    _countdownSeconds = (_stage == RisingTideStage.dim) ? 5 : 5;

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

    // Register bypass FIRST so AccessibilityWatcherService ignores the next
    // focus event for this package.
    ForegroundInterceptGuard.recordPostLaunchBypass(
      pkg,
      window: const Duration(seconds: 6),
    );

    // Atomically remove this app from the native blocklist so the Accessibility
    // service cannot re-fire the interception during the launch transition.
    // Without this, the service still sees the app as blocked and immediately
    // brings Kora to the foreground, causing the "closes the app" bug.
    final currentBlockList = StorageService.getFlaggedApps()
        .where(
          (p) =>
              p != pkg &&
              RisingTideService.getStage(p) != RisingTideStage.whisper,
        )
        .toList();
    await NativeService.sendBlockedApps(currentBlockList);

    if (mounted) Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));

    InstalledApps.startApp(pkg);

    // Restore the full native blocklist after the launch transition completes.
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
          // Background - Semi-transparent app icon or just slate
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),

          // Glassmorphic Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _getSigma(),
                sigmaY: _getSigma(),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(
                        0xFF1E293B,
                      ).withValues(alpha: _getOverlayOpacity() * 0.7),
                      const Color(
                        0xFF0F172A,
                      ).withValues(alpha: _getOverlayOpacity()),
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
                  const SizedBox(height: 40),
                  _buildAppHeader(),
                  const Spacer(),
                  _buildStageContent(),
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

  double _getSigma() {
    switch (_stage) {
      case RisingTideStage.whisper:
        return 5;
      case RisingTideStage.dim:
        return 15;
      case RisingTideStage.mirror:
        return 30;
    }
  }

  double _getOverlayOpacity() {
    switch (_stage) {
      case RisingTideStage.whisper:
        return 0.2;
      case RisingTideStage.dim:
        return 0.4;
      case RisingTideStage.mirror:
        return 0.6;
    }
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        Hero(
          tag: widget.app.packageName,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.app.icon != null
                ? Image.memory(widget.app.icon!, width: 64, height: 64)
                : const Icon(Icons.apps, size: 64, color: Colors.white24),
          ),
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

  Widget _buildStageContent() {
    switch (_stage) {
      case RisingTideStage.dim:
        return _buildDimContent();
      case RisingTideStage.mirror:
        return _buildMirrorContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDimContent() {
    final limitMinutes = RisingTideService.getAppDailyLimit(
      widget.app.packageName,
    ).inMinutes;
    final remaining = (limitMinutes - _minutesToday).clamp(0, limitMinutes);
    final progress = limitMinutes > 0
        ? (_minutesToday / limitMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Text(
          'Heads up',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),

        // AI-generated message (or fallback to original)
        Text(
          _aiMessage ?? "You've used ${widget.app.name} for "
              "$_minutesToday ${_minutesToday == 1 ? 'minute' : 'minutes'} today.",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),

        // Subtle AI indicator
        if (_isAIGenerated) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: Colors.cyanAccent.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                'personalised',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.cyanAccent.withOpacity(0.3),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 10),
        if (_aiMessage == null) ...[
          Text(
            "You have $remaining ${remaining == 1 ? 'minute' : 'minutes'} left "
            "of your ${LimitTimeFormat.dualLabel(limitMinutes)} limit.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.55),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        // Progress bar
        LayoutBuilder(
          builder: (ctx, constraints) {
            return Container(
              height: 5,
              width: constraints.maxWidth * 0.65,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: constraints.maxWidth * 0.65 * progress,
                  height: 5,
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
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Opens today: $_opensToday · Limit ${LimitTimeFormat.dualLabel(limitMinutes)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.3),
          ),
          textAlign: TextAlign.center,
        ),
        _buildGateSettingsLink(),
      ],
    );
  }

  Widget _buildMirrorContent() {
    final limitMinutes = RisingTideService.getAppDailyLimit(
      widget.app.packageName,
    ).inMinutes;
    // Top pending todo — use cast to null-safe version to avoid 'Bad state: No element'
    final topTodo = TodoService.todos.cast<dynamic>().firstWhere(
      (t) => !(t.isCompleted as bool),
      orElse: () => null,
    );
    final hasPendingTodo = topTodo != null;

    return Column(
      children: [
        // Red "Limit Reached" badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_off_rounded,
                size: 14,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'LIMIT REACHED  ·  ${LimitTimeFormat.dualLabel(limitMinutes)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // AI-generated mirror message
        if (_aiMessage != null) ...[
          Text(
            _aiMessage!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          // Subtle AI indicator
          if (_isAIGenerated) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Colors.cyanAccent.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'personalised',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.cyanAccent.withOpacity(0.3),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ] else if (hasPendingTodo) ...[
          // Fallback: show todo-based mirror (original behaviour)
          Text(
            'You said you\'d do this today:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              (topTodo as dynamic).title as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Does opening ${widget.app.name} help with that?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ] else if (_dailyIntention != null) ...[
          // Fallback to daily intention if no todos
          Text(
            'Your note for today:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '"$_dailyIntention"',
            style: const TextStyle(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Does opening ${widget.app.name} align with this?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          // No todo, no intention — bare mirror
          Text(
            'You\'ve hit your limit for ${widget.app.name} today.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Think for a moment before continuing.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 24),
        _buildStatsRow(),
        _buildGateSettingsLink(),
      ],
    );
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

          await StorageService.reloadPrefs();
          await UsageService.refreshUsage();
          await RisingTideService.syncInterceptionState();

          final newStage = RisingTideService.getStage(widget.app.packageName);
          if (!mounted) return;

          if (newStage != RisingTideStage.mirror) {
            RisingTideLogger.logDecision(
              widget.app.packageName,
              "open_anyway",
              "conscious",
            );
            await _launchApp(afterInterceptionFlow: true);
            return;
          }

          final stats = await RisingTideService.getStats(
            widget.app.packageName,
          );

          if (mounted) {
            setState(() {
              _stage = newStage;
              _opensToday = stats['opens'] ?? 0;
              _minutesToday = stats['minutes'] ?? 0;
              _dailyIntention = RisingTideService.getDailyIntention();
              _startInitialCountdown();
            });
          }
        },
      ),
    );
  }

  Widget _buildGateSettingsLink() {
    return TextButton.icon(
      onPressed: _showGateSettings,
      icon: Icon(
        Icons.tune,
        size: 18,
        color: Colors.white.withOpacity(0.4),
      ),
      label: Text(
        'Edit limit & optional note',
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final limit = RisingTideService.getAppDailyLimit(
      widget.app.packageName,
    ).inMinutes;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem("Opens Today", "$_opensToday"),
        const SizedBox(width: 40),
        _buildStatItem(
          "Time vs limit",
          "${LimitTimeFormat.compact(_minutesToday)} / ${LimitTimeFormat.compact(limit)}",
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final bool countdownActive = _countdownSeconds > 0;

    // DIM: 10s unskippable. "Close" exits without recording. "Open anyway"
    // records the decision so the gate won't fire for the rest of the day.
    if (_stage == RisingTideStage.dim) {
      return Column(
        children: [
          _buildGlassButton(
            title: "Close",
            onTap: () {
              RisingTideLogger.logDecision(
                widget.app.packageName,
                "close",
                "none",
              );
              if (mounted) Navigator.pop(context);
            },
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: countdownActive ? 0.35 : 1.0,
            child: _buildGlassButton(
              title: countdownActive
                  ? "Open anyway  ($_countdownSeconds)"
                  : "Open anyway",
              onTap: countdownActive
                  ? null
                  : () async {
                      await RisingTideService.markUserDecision(
                        widget.app.packageName,
                      );
                      RisingTideLogger.logDecision(
                        widget.app.packageName,
                        "open_anyway",
                        "conscious",
                      );
                      await _launchApp(afterInterceptionFlow: true);
                    },
              isPrimary: false,
              isDisabled: countdownActive,
            ),
          ),
        ],
      );
    }

    // MIRROR: 5s countdown then "Continue anyway"
    return Column(
      children: [
        _buildGlassButton(
          title: "Never mind, go back",
          onTap: () {
            RisingTideLogger.logDecision(
              widget.app.packageName,
              "goback",
              "none",
            );
            if (mounted) Navigator.pop(context);
          },
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        _buildGlassButton(
          title: countdownActive
              ? "Wait ${_countdownSeconds}s"
              : "Continue anyway",
          onTap: countdownActive
              ? null
              : () async {
                  RisingTideLogger.logDecision(
                    widget.app.packageName,
                    "continue",
                    "conscious",
                  );
                  await RisingTideService.recordOverride(
                    widget.app.packageName,
                  );
                  await RisingTideService.setReopenLock(widget.app.packageName);
                  await _launchApp(afterInterceptionFlow: true);
                },
          isPrimary: false,
          isDisabled: countdownActive,
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required String title,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isDisabled = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDisabled ? 0.3 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.white
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
