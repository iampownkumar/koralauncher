import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rising_tide_service.dart';
import '../database/database_provider.dart';

class GoalSetter extends StatefulWidget {
  final VoidCallback onGoalSet;
  final VoidCallback? onDismiss;
  final String? initialGoal;

  const GoalSetter({
    super.key,
    required this.onGoalSet,
    this.onDismiss,
    this.initialGoal,
  });

  @override
  State<GoalSetter> createState() => _GoalSetterState();
}

class _GoalSetterState extends State<GoalSetter> {
  late TextEditingController _controller;
  bool _canSkip = false;
  bool _isFirstRun = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal);
    _isFirstRun = !StorageService.hasCompletedOnboarding();

    if (widget.onDismiss != null) {
      if (_isFirstRun) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _canSkip = true;
            });
          }
        });
      } else {
        _canSkip = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_controller.text.trim().isNotEmpty) {
      if (_isFirstRun) await StorageService.completeOnboarding();
      // Keep internal storage for fast retrieval
      await StorageService.setDailyIntention(_controller.text.trim());
      // Save to Drift DB for pattern analysis
      await db.saveIntention(_controller.text.trim());
      RisingTideService.invalidateIntentionCache();
      widget.onGoalSet();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning.";
    } else if (hour < 17) {
      return "Good Afternoon.";
    } else {
      return "Good Evening.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "What is your primary goal for today?",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "e.g. Finish my project",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  const SizedBox(height: 12),
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
                  if (widget.onDismiss != null) ...[
                    const SizedBox(height: 12),
                    if (_canSkip)
                      TextButton(
                        onPressed: () async {
                          if (_isFirstRun)
                            await StorageService.completeOnboarding();
                          widget.onDismiss!();
                        },
                        child: Text(
                          "Skip for now",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 36), // preserve same height
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
