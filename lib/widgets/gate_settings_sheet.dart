import 'package:flutter/material.dart';
import '../utils/limit_time_format.dart';
import 'high_limit_confirm_dialog.dart';

/// Bottom sheet: daily time limit and optional note for Rising Tide.
class GateSettingsSheet extends StatefulWidget {
  const GateSettingsSheet({
    super.key,
    required this.packageName,
    required this.appLabel,
    required this.initialLimitMinutes,
    this.initialIntention,
    required this.onApply,
  });

  final String packageName;
  final String appLabel;
  final int initialLimitMinutes;
  final String? initialIntention;
  final Future<void> Function(int limitMinutes, String? intentionText) onApply;

  @override
  State<GateSettingsSheet> createState() => _GateSettingsSheetState();
}

class _GateSettingsSheetState extends State<GateSettingsSheet> {
  late TextEditingController _limitController;
  late TextEditingController _intentionController;
  int _currentLimit = 5;

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.initialLimitMinutes.clamp(1, 1440);
    _limitController = TextEditingController(text: _currentLimit.toString());
    _intentionController = TextEditingController(
      text: widget.initialIntention ?? '',
    );

    _limitController.addListener(() {
      final val = int.tryParse(_limitController.text);
      if (val != null && val != _currentLimit) {
        setState(() {
          _currentLimit = val.clamp(1, 1440);
        });
      }
    });
  }

  @override
  void dispose() {
    _limitController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final m = _currentLimit;
    final soft = LimitTimeFormat.showsSoftLimitWarning(m);
    final hard = LimitTimeFormat.needsHighLimitConfirm(m);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.appLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your daily boundary',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.45),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Time Display Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: hard
                              ? Colors.deepOrange.shade300
                              : soft
                              ? Colors.amber.shade300
                              : Colors.white,
                          letterSpacing: -1,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mins',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  LimitTimeFormat.dualLabel(m),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (soft) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hard
                          ? Colors.deepOrange.withOpacity(0.1)
                          : Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hard
                            ? Colors.deepOrange.withOpacity(0.3)
                            : Colors.amber.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: hard
                              ? Colors.deepOrange.shade300
                              : Colors.amber.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hard
                                ? 'Very high limit. You will need to confirm twice.'
                                : 'High usage detected. This is a large part of your day.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Text(
                  'NOTATION (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _intentionController,
                  maxLines: 2,
                  maxLength: 120,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Why do you need this app today?',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    filled: true,
                    counterStyle: const TextStyle(color: Colors.white24),
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    final limit = _currentLimit;
                    if (LimitTimeFormat.needsHighLimitConfirm(limit)) {
                      final ok = await showHighLimitConfirmDialog(
                        context,
                        limit,
                      );
                      if (!ok || !context.mounted) return;
                    }
                    final text = _intentionController.text.trim();
                    await widget.onApply(limit, text.isEmpty ? null : text);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: hard
                        ? Colors.deepOrange.shade700
                        : Colors.white,
                    foregroundColor: hard ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hard ? 'Confirm & Save' : 'Set Limit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
