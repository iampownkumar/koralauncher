import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../database/database_provider.dart';

class IntentionSetter extends StatefulWidget {
  final VoidCallback onIntentionSet;
  final VoidCallback? onDismiss;
  final String? initialIntention;

  const IntentionSetter({super.key, required this.onIntentionSet, this.onDismiss, this.initialIntention});

  @override
  State<IntentionSetter> createState() => _IntentionSetterState();
}

class _IntentionSetterState extends State<IntentionSetter> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialIntention);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_controller.text.trim().isNotEmpty) {
      await StorageService.setDailyIntention(_controller.text.trim());
      await db.saveIntention(_controller.text.trim()); 
      widget.onIntentionSet();
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "What is your intention for today?",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: "e.g. Finish my project",
                    hintStyle: TextStyle(color: Colors.white24),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Set Intention", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                if (widget.onDismiss != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text("Skip for now", style: TextStyle(color: Colors.white60)),
                  ),
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
