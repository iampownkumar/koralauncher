import 'package:flutter/material.dart';
import '../utils/limit_time_format.dart';

/// Returns true if user confirms a high daily limit.
Future<bool> showHighLimitConfirmDialog(
  BuildContext context,
  int limitMinutes,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'That is a large slice of your day',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You chose ${LimitTimeFormat.compact(limitMinutes)} ($limitMinutes min) for this app.',
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 16),
            const Text(
              'Long sessions here can quietly eat your focus, your evening, and your sleep. '
              'Before you save: is this limit really worth it for you today?',
              style: TextStyle(color: Colors.white60, height: 1.45, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Pick a smaller limit',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('I still want this limit'),
        ),
      ],
    ),
  );
  return result ?? false;
}
