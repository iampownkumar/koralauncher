/// Created by POWNKUMAR A (Founder of Korelium) – 2026-04-28
/// Last updated – 2026-04-28 13:08 IST

import 'package:flutter/material.dart';
import '../../services/rising_tide_service.dart';
import '../../models/rising_tide_stage.dart';
import '../../services/rising_tide_controller.dart';
import '../../database/kora_database.dart';

class DimGate extends StatefulWidget {
  final String packageName;
  const DimGate({Key? key, required this.packageName}) : super(key: key);

  @override
  State<DimGate> createState() => _DimGateState();
}

class _DimGateState extends State<DimGate> {
  String? _selectedMood;

  final List<String> _moods = ['😌 Relaxed', '😤 Stressed', '🎯 Focused', '😶 Neutral'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('How are you feeling?'), backgroundColor: Colors.amber),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select your current mood (optional):', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _moods.map((m) => ChoiceChip(
                label: Text(m),
                selected: _selectedMood == m,
                onSelected: (_) => _onMoodSelected(m),
                selectedColor: Colors.amberAccent,
                labelStyle: const TextStyle(color: Colors.black),
              )).toList(),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _continue,
              style: FilledButton.styleFrom(backgroundColor: Colors.amberAccent),
              child: const Text('Continue', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _onMoodSelected(String mood) async {
    setState(() => _selectedMood = mood);
    // Persist mood to DB
    final db = KoraDatabase();
    await db.logMood(score: 3, label: mood.split(' ').last, context: 'DimGate');
  }

  void _continue() async {
    // Advance to next stage via controller
    // Advance to next stage via controller using public method
    final controller = RisingTideService().controllerFor(widget.packageName);
    await controller.advanceToStage(RisingTideStage.mirror);
    Navigator.of(context).pop(); // Close gate, InterceptionScreen will rebuild
  }
}
