import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/material.dart';
import '../database/database_provider.dart';
import '../widgets/micro_habit_suggestion.dart';

class InterceptionScreen extends StatefulWidget {
  final AppInfo app;

  const InterceptionScreen({super.key, required this.app});

  @override
  State<InterceptionScreen> createState() => _InterceptionScreenState();
}

class _InterceptionScreenState extends State<InterceptionScreen> {
  bool _reasonSelected = false;
  bool _showSuggestion = false;
  String? _selectedReason;

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
                  tag: widget.app.packageName,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.app.icon != null 
                        ? Image.memory(widget.app.icon!, width: 80, height: 80)
                        : const Icon(Icons.apps, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              if (!_showSuggestion) ...[
                Text(
                  _reasonSelected ? "You chose: $_selectedReason" : "Why are you opening ${widget.app.name}?",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 24, height: 1.4, color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (!_reasonSelected) ...[
                  _buildChoiceButton(
                    title: "Habit / Boredom",
                    isPrimary: false,
                    onTap: () => setState(() {
                      _reasonSelected = true;
                      _selectedReason = "Habit / Boredom";
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Quick Task",
                    isPrimary: false,
                    onTap: () => setState(() {
                      _reasonSelected = true;
                      _selectedReason = "Quick Task";
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Important Work",
                    isPrimary: false,
                    onTap: () => setState(() {
                      _reasonSelected = true;
                      _selectedReason = "Important Work";
                    }),
                  ),
                ] else ...[
                  // Once reason is selected, show final choices
                  _buildChoiceButton(
                    title: "Never mind, close",
                    isPrimary: true,
                    textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    onTap: () async {
                      if (_selectedReason == null) return;
                      try {
                        await db.logDecision(
                          packageName: widget.app.packageName,
                          reason: _selectedReason!,
                          opened: false,
                          resistedCompletely: true,
                        );
                      } catch (e) {
                        debugPrint('Database error: $e');
                      }
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Give me something else",
                    isPrimary: false,
                    onTap: () {
                      setState(() {
                        _showSuggestion = true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildChoiceButton(
                    title: "Open anyway",
                    isPrimary: false,
                    isDestructive: true,
                    onTap: () async {
                      if (_selectedReason == null) return;
                      try {
                        await db.logDecision(
                          packageName: widget.app.packageName,
                          reason: _selectedReason!,
                          opened: true,
                        );
                        await db.startSession(widget.app.packageName, widget.app.name);
                      } catch (e) {
                        debugPrint('Database error: $e');
                      }
                      InstalledApps.startApp(widget.app.packageName);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ] else ...[
                MicroHabitSuggestion(
                  onDismiss: () => Navigator.pop(context),
                ),
              ],
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
    TextStyle? textStyle,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        backgroundColor: isPrimary 
          ? Colors.white 
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
        style: textStyle ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
