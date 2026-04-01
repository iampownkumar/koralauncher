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
  late double _limitMinutes;
  late TextEditingController _intentionController;

  @override
  void initState() {
    super.initState();
    _limitMinutes = widget.initialLimitMinutes.toDouble().clamp(5, 1440);
    _intentionController = TextEditingController(text: widget.initialIntention ?? '');
  }

  @override
  void dispose() {
    _intentionController.dispose();
    super.dispose();
  }

  Color _thumbColor(double limit) {
    final m = limit.round();
    if (LimitTimeFormat.needsHighLimitConfirm(m)) {
      return Colors.deepOrange.shade400;
    }
    if (LimitTimeFormat.showsSoftLimitWarning(m)) {
      return Colors.amber.shade400;
    }
    return Colors.white;
  }

  Color _trackColor(double limit) {
    final m = limit.round();
    if (LimitTimeFormat.needsHighLimitConfirm(m)) {
      return Colors.deepOrange.withValues(alpha: 0.45);
    }
    if (LimitTimeFormat.showsSoftLimitWarning(m)) {
      return Colors.amber.withValues(alpha: 0.35);
    }
    return Colors.white24;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final m = _limitMinutes.round();
    final soft = LimitTimeFormat.showsSoftLimitWarning(m);
    final hard = LimitTimeFormat.needsHighLimitConfirm(m);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.appLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily limit · optional note',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  LimitTimeFormat.dualLabel(m),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: hard
                        ? Colors.deepOrange.shade200
                        : soft
                            ? Colors.amber.shade200
                            : Colors.white,
                  ),
                ),
                if (soft) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hard
                          ? Colors.deepOrange.withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hard
                            ? Colors.deepOrange.withValues(alpha: 0.45)
                            : Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      hard
                          ? 'More than 4 hours: you will confirm before saving.'
                          : '4h+ is a large part of your day — set this only if it is intentional.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Daily time limit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _trackColor(_limitMinutes),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: _thumbColor(_limitMinutes),
                    overlayColor: _thumbColor(_limitMinutes).withValues(alpha: 0.25),
                  ),
                  child: Slider(
                    min: 5,
                    max: 1440,
                    divisions: 287,
                    value: _limitMinutes.clamp(5, 1440),
                    label: LimitTimeFormat.compact(m),
                    onChanged: (v) => setState(() => _limitMinutes = v),
                  ),
                ),
                Text(
                  'Stages trigger at 50%, 100%, and 200% of this limit.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Note for today (optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _intentionController,
                  maxLines: 3,
                  maxLength: 280,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Skip or add a few words',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final limit = _limitMinutes.round();
                    if (LimitTimeFormat.needsHighLimitConfirm(limit)) {
                      final ok = await showHighLimitConfirmDialog(context, limit);
                      if (!ok || !context.mounted) return;
                    }
                    final text = _intentionController.text.trim();
                    await widget.onApply(
                      limit,
                      text.isEmpty ? null : text,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: hard ? Colors.deepOrange.shade700 : Colors.white,
                    foregroundColor: hard ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    hard ? 'Save (confirm)' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
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
