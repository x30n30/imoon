import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:imoon/theme.dart';

/// A circular "moon dial" showing the current cycle day and phase arc.
class MoonDial extends StatelessWidget {
  final int cycleDay;
  final int cycleLength;
  final CyclePhaseUI phase;
  final bool periodActive;

  const MoonDial({
    super.key,
    required this.cycleDay,
    required this.cycleLength,
    required this.phase,
    required this.periodActive,
  });

  @override
  Widget build(BuildContext context) {
    final progress = cycleLength > 0
        ? (cycleDay.clamp(1, cycleLength) / cycleLength).toDouble()
        : 0.0;

    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _DialPainter(
          progress:  progress,
          color:     phaseColor(phase),
          dimColor:  phaseDimColor(phase),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                phaseEmoji(phase),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                periodActive ? 'Day $cycleDay' : 'Day $cycleDay',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 32,
                  color: phaseColor(phase),
                ),
              ),
              Text(
                'of cycle',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color dimColor;

  _DialPainter({required this.progress, required this.color, required this.dimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = dimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,                  // start at top
        2 * math.pi * progress,        // sweep
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dot at current position
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final dotPos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(dotPos, 7, Paint()..color = color);
    canvas.drawCircle(dotPos, 4, Paint()..color = IMoonColors.bg);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color;
}
