import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/todo_service.dart';
import '../services/rising_tide_service.dart';
import '../database/database_provider.dart';

/// The daily intention setter overlay.
///
/// **First open of a new day (no intention set)**:
///   - Shows immediately with a 30-second animated countdown ring.
///   - The countdown is purely visual — no "Skip" button exists.
///   - The ONLY way to dismiss is to type a goal and tap "Set Goal".
///
/// **Subsequent opens (intention already set / editing)**:
///   - Normal edit mode with a dismiss button.
class GoalSetter extends StatefulWidget {
  final VoidCallback onGoalSet;
  final VoidCallback onDismiss;
  final String? initialGoal;
  final bool isMandatory;

  const GoalSetter({
    super.key,
    required this.onGoalSet,
    required this.onDismiss,
    this.initialGoal,
    this.isMandatory = false,
  });

  @override
  State<GoalSetter> createState() => _GoalSetterState();
}

class _GoalSetterState extends State<GoalSetter>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;

  // Countdown state — only relevant when this is a mandatory first-set
  static const int _countdownSeconds = 30;
  int _secondsLeft = _countdownSeconds;
  Timer? _timer;

  // Animation for the countdown ring
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _countdownSeconds),
    );
    _ringAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    if (widget.isMandatory) {
      _ringController.forward();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final isNewIntention = widget.initialGoal == null ||
        widget.initialGoal!.isEmpty ||
        widget.initialGoal != text;

    // Save to SharedPreferences (fast retrieval)
    await StorageService.setDailyIntention(text);
    // Save to Drift DB (history / AI context)
    await db.saveIntention(text);
    RisingTideService.invalidateIntentionCache();

    if (isNewIntention) {
      // Auto-add (or update) the intention-linked todo
      await TodoService.addIntentionTodo(text);
    } else if (widget.initialGoal != text) {
      // User edited an existing intention — sync to linked todo
      await TodoService.updateIntentionTodo(text);
    }

    widget.onGoalSet();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning.";
    if (hour < 17) return "Good Afternoon.";
    return "Good Evening.";
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.88,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Countdown ring (mandatory mode only) ──────────
                  if (widget.isMandatory) _buildCountdownRing(),

                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isMandatory
                        ? "Before you continue — set your focus for today."
                        : "What is your primary goal for today?",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Text field ────────────────────────────────────
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: "e.g. Finish my project",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  const SizedBox(height: 8),

                  // ── Set Goal button ───────────────────────────────
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Set Goal",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // ── Dismiss Action ───────────────────────────────
                  if (!widget.isMandatory || _secondsLeft <= 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: Text(
                        widget.isMandatory ? "Skip for now" : "Cancel",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else ...[
                     const SizedBox(height: 55), // reserve space so UI doesn't jump
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownRing() {
    final bool countingDown = _secondsLeft > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring
              AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, child) => CircularProgressIndicator(
                  value: _ringAnimation.value,
                  strokeWidth: 3,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(
                    countingDown
                        ? Colors.cyanAccent.withOpacity(0.8)
                        : Colors.white24,
                  ),
                ),
              ),
              // Number or checkmark
              Text(
                countingDown ? '$_secondsLeft' : '✓',
                style: TextStyle(
                  color: countingDown ? Colors.white70 : Colors.white38,
                  fontSize: countingDown ? 18 : 22,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
