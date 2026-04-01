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
import '../services/app_lock_manager.dart';
import '../services/foreground_intercept_guard.dart';
import '../utils/limit_time_format.dart';
import '../services/todo_service.dart';
import '../database/kora_database.dart';

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

  // Flow control
  String? _selectedMood;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  bool _canProceed = false;

  // Tasks state
  bool _showTasks = false;
  List<Todo> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initStage();
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
      await StorageService.incrementTodayOpenCount(widget.app.packageName);
      await _launchApp();
      return;
    }

    await StorageService.incrementTodayOpenCount(widget.app.packageName);

    final stats = await RisingTideService.getStats(widget.app.packageName);
    _dailyIntention = RisingTideService.getDailyIntention();

    if (mounted) {
      setState(() {
        _stage = stage;
        _opensToday = stats['opens'] ?? 0;
        _minutesToday = stats['minutes'] ?? 0;
        _isLoading = false;

        // Stage 4 / Silence has no countdown and is always blocked
        if (_stage == RisingTideStage.silence) {
          _tasks = TodoService.todos.where((t) => !t.isCompleted).toList();
        } else {
          _startInitialCountdown();
        }
      });
      RisingTideLogger.logAppOpen(widget.app.packageName, _stage);
    }
  }

  void _startInitialCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 5;
    _canProceed = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            _canProceed = true;
            _countdownTimer?.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _launchApp({bool afterInterceptionFlow = false}) async {
    // Log the session start in the database to increment the open count
    await db.startSession(widget.app.packageName, widget.app.name);
    if (afterInterceptionFlow) {
      ForegroundInterceptGuard.recordPostLaunchBypass(widget.app.packageName);
    }
    InstalledApps.startApp(widget.app.packageName);
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
                      const Color(0xFF1E293B).withValues(
                        alpha: _getOverlayOpacity() * 0.7,
                      ),
                      const Color(0xFF0F172A).withValues(alpha: _getOverlayOpacity()),
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
      case RisingTideStage.silence:
        return 50;
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
      case RisingTideStage.silence:
        return 0.8;
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
      case RisingTideStage.silence:
        return _buildSilenceContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDimContent() {
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
        Text(
          "You've used ${widget.app.name} for $_minutesToday mins today.\nWhat's the vibe?",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Opens today: $_opensToday · Limit ${LimitTimeFormat.dualLabel(RisingTideService.getAppDailyLimit(widget.app.packageName).inMinutes)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          textAlign: TextAlign.center,
        ),
        _buildGateSettingsLink(),
        const SizedBox(height: 24),
        _buildMoodSelector(),
      ],
    );
  }

  Widget _buildMirrorContent() {
    return Column(
      children: [
        const Text(
          "Limit Reached",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        if (_dailyIntention != null) ...[
          Text(
            "\"$_dailyIntention\"",
            style: const TextStyle(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Does opening this help with your intention?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Text(
            "No note for today (optional).",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          TextButton(
            onPressed: _showGateSettings,
            child: const Text(
              "Set daily limit",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildStatsRow(),
        if (_dailyIntention != null) _buildGateSettingsLink(),
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
          await RisingTideService.syncInterceptionState();
          await UsageService.refreshUsage();
          final newStage = RisingTideService.getStage(widget.app.packageName);
          if (!mounted) return;
          if (newStage == RisingTideStage.whisper) {
            await _launchApp();
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
        color: Colors.white.withValues(alpha: 0.4),
      ),
      label: Text(
        'Edit limit & optional note',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
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

  Widget _buildSilenceContent() {
    if (_showTasks) {
      return Column(
        children: [
          const Text(
            "Complete a task to unlock 5m",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          if (_tasks.isEmpty)
            const Text(
              "No tasks remaining today.",
              style: TextStyle(color: Colors.white38),
            )
          else
            ..._tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () async {
                    await TodoService.toggleTodo(task.id);
                    await AppLockManager.grantUnlock(
                      widget.app.packageName,
                      minutes: 5,
                    );
                    RisingTideLogger.logTideEvent(
                      packageName: widget.app.packageName,
                      eventType: 'stage4_task_unlock',
                      stage: RisingTideStage.silence,
                      detail: task.title,
                    );
                    await _launchApp(afterInterceptionFlow: true);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle_outlined,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() => _showTasks = false),
            child: const Text(
              "Go back",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text(
          "Silence",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          "You've chosen to stop here today.",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_dailyIntention != null) ...[
          Text(
            "\"$_dailyIntention\"",
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Text(
            "No note for today",
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white54,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildStatsRow(),
        _buildGateSettingsLink(),
      ],
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
          onTap: () => setState(() => _selectedMood = m['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white12,
                width: 1,
              ),
            ),
            child: Text(
              m['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    if (_stage == RisingTideStage.silence) {
      if (_showTasks) {
        return const SizedBox(); // Action buttons hidden in task view
      }

      final bool usedUnlock = AppLockManager.hasUsedUnlockToday(
        widget.app.packageName,
      );

      return Column(
        children: [
          _buildGlassButton(
            title: "Come back tomorrow",
            onTap: () => Navigator.pop(context),
            isPrimary: true,
          ),
          if (!usedUnlock) ...[
            const SizedBox(height: 16),
            _buildGlassButton(
              title: "Complete a task to unlock 5 minutes",
              onTap: () => setState(() => _showTasks = true),
              isPrimary: false,
            ),
          ],
        ],
      );
    }

    final bool moodRequired =
        _stage == RisingTideStage.dim && _selectedMood == null;
    final bool countdownActive = _countdownSeconds > 0;
    final bool disabled = moodRequired || countdownActive;

    return Column(
      children: [
        _buildGlassButton(
          title: "Never mind, go back",
          onTap: () async {
            await RisingTideService.clearReopenLock(widget.app.packageName);
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
              ? "Wait ${_countdownSeconds}s"
              : "Continue anyway",
          onTap: disabled
              ? null
              : () async {
                  RisingTideLogger.logDecision(
                    widget.app.packageName,
                    "continue",
                    _selectedMood ?? "conscious",
                  );
                  await RisingTideService.recordOverride(
                    widget.app.packageName,
                  );
                  await RisingTideService.setReopenLock(widget.app.packageName);
                  await _launchApp(afterInterceptionFlow: true);
                  if (mounted) Navigator.pop(context);
                },
          isPrimary: false,
          isDisabled: disabled,
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
                : Colors.white.withValues(alpha: 0.05),
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
