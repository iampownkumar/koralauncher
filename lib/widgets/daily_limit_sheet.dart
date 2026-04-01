import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/rising_tide_service.dart';
import '../utils/limit_time_format.dart';
import 'high_limit_confirm_dialog.dart';

/// Daily time limit for one app — shows hours + minutes, warns above 4h.
class DailyLimitSheet extends StatefulWidget {
  const DailyLimitSheet({
    super.key,
    required this.packageName,
    required this.appLabel,
    required this.initialLimitMinutes,
  });

  final String packageName;
  final String appLabel;
  final int initialLimitMinutes;

  @override
  State<DailyLimitSheet> createState() => _DailyLimitSheetState();
}

class _DailyLimitSheetState extends State<DailyLimitSheet> {
  late double _limitMinutes;

  @override
  void initState() {
    super.initState();
    _limitMinutes = widget.initialLimitMinutes.toDouble().clamp(5, 1440);
  }

  Color _thumbColor() {
    final m = _limitMinutes.round();
    if (LimitTimeFormat.needsHighLimitConfirm(m)) {
      return Colors.deepOrange.shade400;
    }
    if (LimitTimeFormat.showsSoftLimitWarning(m)) {
      return Colors.amber.shade400;
    }
    return Colors.white;
  }

  Color _trackColor() {
    final m = _limitMinutes.round();
    if (LimitTimeFormat.needsHighLimitConfirm(m)) {
      return Colors.deepOrange.withValues(alpha: 0.45);
    }
    if (LimitTimeFormat.showsSoftLimitWarning(m)) {
      return Colors.amber.withValues(alpha: 0.35);
    }
    return Colors.white24;
  }

  Future<void> _save() async {
    final m = _limitMinutes.round();
    if (LimitTimeFormat.needsHighLimitConfirm(m)) {
      final ok = await showHighLimitConfirmDialog(context, m);
      if (!ok || !mounted) return;
    }
    await StorageService.setAppDailyLimitMinutes(widget.packageName, m);
    await RisingTideService.syncInterceptionState();
    if (mounted) Navigator.of(context).pop();
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  'Daily time limit',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  LimitTimeFormat.dualLabel(m),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
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
                          ? 'That is more than 4 hours in one app. Long blocks can quietly consume your whole day — you will be asked to confirm when you save.'
                          : '4 hours or more: a large share of your waking day. Make sure this limit matches what you really want.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _trackColor(),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: _thumbColor(),
                          overlayColor: _thumbColor().withValues(alpha: 0.25),
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
                    ),
                  ],
                ),
                Text(
                  'Rising Tide uses 50% / 100% / 200% of this limit for stages.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: hard
                        ? Colors.deepOrange.shade700
                        : Colors.white,
                    foregroundColor: hard ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    hard ? 'Save (confirm if needed)' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
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
