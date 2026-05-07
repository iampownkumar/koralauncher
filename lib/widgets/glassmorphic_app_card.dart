import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';

/// Premium glassmorphic app card for the unified dashboard.
/// Shows app icon, name, usage time, flagged state, and usage progress bar.
class GlassmorphicAppCard extends StatelessWidget {
  final AppInfo app;
  final Duration usage;
  final bool isFlagged;
  final int? limitMinutes;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFlagTap;
  final VoidCallback? onSettingsTap;

  const GlassmorphicAppCard({
    super.key,
    required this.app,
    required this.usage,
    required this.onTap,
    this.isFlagged = false,
    this.limitMinutes,
    this.onLongPress,
    this.onFlagTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (usage.inMilliseconds + 30000) ~/ 60000;
    final hasLimit = isFlagged && limitMinutes != null && limitMinutes! > 0;
    final progress = hasLimit ? (minutes / limitMinutes!).clamp(0.0, 1.0) : 0.0;
    final remaining = hasLimit ? (limitMinutes! - minutes).clamp(0, limitMinutes!) : 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isFlagged
              ? const Color(0xFF06B6D4).withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFlagged
                ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: isFlagged
              ? [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // App icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: app.icon != null
                        ? Image.memory(app.icon!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.white.withValues(alpha: 0.1),
                            child: const Icon(Icons.apps, color: Colors.white54, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // App name + usage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: TextStyle(
                          color: isFlagged ? Colors.white : Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: isFlagged ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSubtitle(minutes, remaining, hasLimit),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Usage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUsageColor(minutes).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatMinutes(minutes),
                    style: TextStyle(
                      color: _getUsageColor(minutes),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Flag / settings button
                if (onFlagTap != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onFlagTap,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.waves,
                        size: 20,
                        color: isFlagged
                            ? const Color(0xFF06B6D4)
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ],
                if (isFlagged && onSettingsTap != null) ...[
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: onSettingsTap,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.tune,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Progress bar for flagged apps with limits
            if (hasLimit) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progress),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(int minutes, int remaining, bool hasLimit) {
    if (!isFlagged) {
      return minutes > 0 ? 'Used today' : 'Not used today';
    }
    if (!hasLimit) return 'Flagged · No limit set';
    if (minutes <= 0) return 'Limit: ${_formatMinutes(limitMinutes!)} · Not used';
    return '${remaining}m left of ${_formatMinutes(limitMinutes!)}';
  }

  Color _getUsageColor(int minutes) {
    if (minutes >= 60) return const Color(0xFFEF4444); // red
    if (minutes >= 30) return const Color(0xFFF59E0B); // orange
    return const Color(0xFF06B6D4); // cyan
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return const Color(0xFFEF4444); // red
    if (progress >= 0.7) return const Color(0xFFF59E0B); // orange
    return const Color(0xFF06B6D4); // cyan
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
