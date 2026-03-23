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
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: app.packageName!,
                  child: app.icon != null 
                      ? Image.memory(app.icon!, fit: BoxFit.cover)
                      : const Icon(Icons.apps),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                app.name!,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFlagged)
              Icon(Icons.shield_moon, color: Theme.of(context).primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
