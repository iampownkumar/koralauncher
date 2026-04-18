import 'package:installed_apps/app_info.dart';
import 'package:flutter/material.dart';

const _kFlagColor = Colors.cyanAccent;

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFlagTap;
  final bool isFlagged;
  final Duration usage;

  const AppListItem({
    super.key,
    required this.app,
    required this.onTap,
    this.onLongPress,
    this.onFlagTap,
    this.isFlagged = false,
    this.usage = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isFlagged
            ? _kFlagColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isFlagged
            ? Border.all(color: _kFlagColor.withValues(alpha: 0.4), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        splashColor: _kFlagColor.withValues(alpha: 0.15),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: app.packageName,
                    child: app.icon != null
                        ? Image.memory(app.icon!, fit: BoxFit.cover)
                        : const Icon(Icons.apps),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  app.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onFlagTap != null) ...[
                IconButton(
                  tooltip: isFlagged
                      ? 'Rising Tide on — tap to turn off'
                      : 'Mark for Rising Tide',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(
                    Icons.waves,
                    size: 24,
                    color: isFlagged ? _kFlagColor : Colors.white38,
                  ),
                  onPressed: onFlagTap,
                ),
              ],
              if (usage != Duration.zero) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    "${_formatUsage(usage)} today",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isFlagged && onFlagTap == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kFlagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline,
                          color: _kFlagColor, size: 16),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        "FLAGGED",
                        style: TextStyle(
                          color: _kFlagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUsage(Duration d) {
    final totalMinutes = (d.inMilliseconds + 30000) ~/ 60000;
    if (totalMinutes <= 0) return "0m";
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }
}
