import 'dart:async';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  int _countdown = 3; // The Pause: 3 seconds
  Timer? _timer;
  bool _canOpen = false;

  late final String _selectedPrompt;

  @override
  void initState() {
    super.initState();
    final prompts = [
      "You just opened ${widget.app.name}.\nWhat are you looking for right now?",
      "Is opening ${widget.app.name}\nwhat you really need right now?",
      "Take a breath.\nDo you want to continue to ${widget.app.name}?",
    ];
    _selectedPrompt = prompts[DateTime.now().second % prompts.length];
    _startPause();
  }

  void _startPause() {
    // Night Mode Check (Problem 9)
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) {
      _countdown = 10; // Stronger friction at night
      _selectedPrompt = "It's late. Do you really need ${widget.app.name} right now?";
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canOpen = true;
          _countdown = 0;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Immersive "Pause"
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Hero(
                  tag: widget.app.packageName!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.app.icon != null 
                        ? Image.memory(widget.app.icon!, width: 80, height: 80)
                        : const Icon(Icons.apps, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _selectedPrompt,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 24, height: 1.4, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              _buildChoiceButton(
                title: "Not really, close",
                isPrimary: true,
                onTap: () async {
                  await StorageService.logDecision(widget.app.packageName!, false);
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              _buildChoiceButton(
                title: "Give me something else",
                isPrimary: false,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Breathe in for 4s, out for 6s.')),
                  );
                },
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _canOpen ? 1.0 : 0.5,
                child: _canOpen 
                  ? _buildChoiceButton(
                      title: "Open anyway",
                      isPrimary: false,
                      isDestructive: true,
                      onTap: () async {
                        await StorageService.logDecision(widget.app.packageName!, true);
                        InstalledApps.startApp(widget.app.packageName!);
                        if (mounted) Navigator.pop(context);
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Wait $_countdown...",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required bool isPrimary,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        backgroundColor: isPrimary 
          ? Theme.of(context).primaryColor 
          : (isDestructive ? Colors.transparent : const Color(0xFF1E293B)),
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDestructive ? const BorderSide(color: Colors.white24) : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      onPressed: onTap,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
