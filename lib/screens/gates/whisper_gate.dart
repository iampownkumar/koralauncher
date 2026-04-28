/// Created by POWNKUMAR A (Founder of Korelium) – 2026-04-28
/// Last updated – 2026-04-28 13:08 IST

import 'package:flutter/material.dart';
import '../../services/rising_tide_service.dart';
import '../../models/rising_tide_stage.dart';

class WhisperGate extends StatelessWidget {
  final String packageName;
  const WhisperGate({Key? key, required this.packageName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 80),
            const SizedBox(height: 20),
            const Text('You are within your daily limit.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: () async {
                // Just close the gate and let app open
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.cyanAccent),
              child: const Text('Open Anyway', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
