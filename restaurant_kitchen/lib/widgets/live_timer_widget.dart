import 'dart:async';
import 'package:flutter/material.dart';

class LiveTimerWidget extends StatefulWidget {
  final DateTime placedAt;
  final bool isUrgent;
  final bool isVeryUrgent;

  const LiveTimerWidget({
    super.key,
    required this.placedAt,
    this.isUrgent = false,
    this.isVeryUrgent = false,
  });

  @override
  State<LiveTimerWidget> createState() => _LiveTimerWidgetState();
}

class _LiveTimerWidgetState extends State<LiveTimerWidget> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    // Har second update karo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    if (mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.placedAt);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;

    // Color decide karo time ke hisaab se
    Color timerColor;
    if (minutes >= 20) {
      timerColor = Colors.red[900]!;
    } else if (minutes >= 10) {
      timerColor = Colors.red;
    } else if (minutes >= 5) {
      timerColor = Colors.orange;
    } else {
      timerColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: timerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.4),
          width: widget.isVeryUrgent ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isVeryUrgent
                ? Icons.warning
                : widget.isUrgent
                    ? Icons.timer_off
                    : Icons.timer,
            color: timerColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
