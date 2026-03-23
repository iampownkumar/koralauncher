import 'package:installed_apps/app_info.dart';
import 'package:flutter/material.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isFlagged;

  const AppListItem({
    super.key,
    required this.app,
    required this.onTap,
    required this.onLongPress,
    this.isFlagged = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isFlagged 
            ? Theme.of(context).primaryColor.withValues(alpha: 0.15) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isFlagged
            ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
              if (isFlagged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline, color: Theme.of(context).primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "FLAGGED",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
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
}
