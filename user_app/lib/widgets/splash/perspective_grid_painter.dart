import 'package:flutter/material.dart';

class PerspectiveGridPainter extends CustomPainter {
  PerspectiveGridPainter({required this.progress, required this.shift});

  final double progress;
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.38;
    final vanishX = size.width * 0.5;
    final baseY = size.height;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22 * progress)
      ..strokeWidth = 1;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45 * progress)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Horizontal perspective lines
    for (var i = 0; i <= 8; i++) {
      final t = i / 8;
      final y = horizonY + (baseY - horizonY) * t;
      final spread = 0.15 + t * 0.85;
      final left = vanishX - size.width * spread;
      final right = vanishX + size.width * spread;

      canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);

      final streakT = (shift + t) % 1.0;
      if (streakT < 0.18) {
        final sx = left + (right - left) * streakT * 3;
        canvas.drawLine(Offset(sx, y), Offset(sx + 18, y), glowPaint);
      }
    }

    // Vertical converging lines
    for (var i = -4; i <= 4; i++) {
      final bottomX = vanishX + i * size.width * 0.11;
      canvas.drawLine(Offset(vanishX, horizonY), Offset(bottomX, baseY), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PerspectiveGridPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.shift != shift;
  }
}
