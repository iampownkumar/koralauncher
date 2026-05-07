import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 7-day usage bar chart with gradient bars and day labels.
class WeeklyBarChart extends StatefulWidget {
  /// Map of day label → total minutes for that day.
  /// Expected order: oldest → newest (left → right).
  final List<DayUsage> days;
  final double height;

  const WeeklyBarChart({
    super.key,
    required this.days,
    this.height = 140,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class DayUsage {
  final String label; // "Mon", "Tue", etc.
  final int minutes;
  final bool isToday;

  const DayUsage({
    required this.label,
    required this.minutes,
    this.isToday = false,
  });
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMinutes = widget.days.fold<int>(
      1,
      (prev, d) => math.max(prev, d.minutes),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.days.map((day) {
              final barHeight = maxMinutes > 0
                  ? (day.minutes / maxMinutes) * (widget.height - 48) * _animation.value
                  : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Minutes label above bar
                      if (day.minutes > 0 && _animation.value > 0.5)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _formatMinutes(day.minutes),
                            style: TextStyle(
                              color: day.isToday
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.35),
                              fontSize: 9,
                              fontWeight: day.isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      // Bar
                      Container(
                        height: math.max(barHeight, 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: day.isToday
                                ? const [
                                    Color(0xFF06B6D4),
                                    Color(0xFF8B5CF6),
                                  ]
                                : [
                                    const Color(0xFF06B6D4).withValues(alpha: 0.4),
                                    const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                  ],
                          ),
                          boxShadow: day.isToday
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Day label
                      Text(
                        day.label,
                        style: TextStyle(
                          color: day.isToday
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: day.isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m}m';
  }
}
