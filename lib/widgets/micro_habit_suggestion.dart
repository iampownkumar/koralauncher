import 'dart:math';
import 'package:flutter/material.dart';

class MicroHabit {
  final String title;
  final String description;
  final IconData icon;

  MicroHabit({required this.title, required this.description, required this.icon});
}

class MicroHabitSuggestion extends StatefulWidget {
  final VoidCallback onDismiss;

  const MicroHabitSuggestion({super.key, required this.onDismiss});

  @override
  State<MicroHabitSuggestion> createState() => _MicroHabitSuggestionState();
}

class _MicroHabitSuggestionState extends State<MicroHabitSuggestion> {
  late final MicroHabit _selectedHabit;

  final List<MicroHabit> _habits = [
    MicroHabit(
      title: "Box Breathing",
      description: "Inhale for 4s, hold for 4s, exhale for 4s, hold for 4s. Repeat 3 times.",
      icon: Icons.air,
    ),
    MicroHabit(
      title: "Quick Stretch",
      description: "Reach for the sky for 10 seconds, then touch your toes. Shake it off.",
      icon: Icons.accessibility_new,
    ),
    MicroHabit(
      title: "Micro-Journal",
      description: "Think of one thing you are genuinely grateful for right now.",
      icon: Icons.edit_note,
    ),
    MicroHabit(
      title: "Hydrate",
      description: "Take a slow sip of water. Feel it cool your throat.",
      icon: Icons.local_drink,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedHabit = _habits[Random().nextInt(_habits.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_selectedHabit.icon, size: 48, color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(
            _selectedHabit.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedHabit.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: widget.onDismiss,
            child: const Text("I'm done", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
