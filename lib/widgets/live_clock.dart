import 'dart:async';
import 'package:flutter/material.dart';

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Update every 50ms for smooth millisecond display rendering
    // High update rate is okay since this is a tiny widget and flutter handles dirty-checking well
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  String _formatTime() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");

    String h = twoDigits(_now.hour);
    String m = twoDigits(_now.minute);
    String s = twoDigits(_now.second);
    // Use first two digits of milliseconds for UI stability (00-99 instead of 000-999)
    String ms = threeDigits(_now.millisecond).substring(0, 2); 
    String tz = _now.timeZoneName;

    return "$h:$m:$s:$ms $tz";
  }

  Widget build(BuildContext context) {
    return Text(
      _formatTime(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
            height: 1.0,
            shadows: const [Shadow(blurRadius: 15, color: Colors.black87)],
          ),
    );
  }
}
