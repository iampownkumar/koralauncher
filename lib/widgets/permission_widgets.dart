import 'package:flutter/material.dart';

/// Reusable section header for settings/onboarding screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.topPad = 28});
  final String label;
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPad, 24, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

/// A card showing a permission's current status and an action button.
class PermissionStatusCard extends StatelessWidget {
  const PermissionStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isEnabled;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled
                    ? Colors.cyanAccent.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isEnabled ? Colors.cyanAccent : Colors.white38, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _StatusChip(isEnabled: isEnabled),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Small hint row
                      Row(
                        children: [
                          Icon(
                            isEnabled ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                            color: isEnabled
                                ? Colors.cyanAccent.withValues(alpha: 0.7)
                                : Colors.white24,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEnabled ? actionLabel : 'Tap to $actionLabel'.toLowerCase(),
                            style: TextStyle(
                              color: isEnabled
                                  ? Colors.cyanAccent.withValues(alpha: 0.7)
                                  : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isEnabled});
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEnabled
            ? Colors.cyanAccent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEnabled
              ? Colors.cyanAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        isEnabled ? 'On' : 'Off',
        style: TextStyle(
          color: isEnabled ? Colors.cyanAccent : Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A settings list tile with a status chip and action button.
class SettingsPermissionRow extends StatelessWidget {
  const SettingsPermissionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isEnabled;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(isEnabled: isEnabled),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white24,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
