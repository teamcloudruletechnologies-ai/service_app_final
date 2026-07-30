import 'dart:math' as math;

import 'package:flutter/material.dart';

class CitySkylinePainter extends CustomPainter {
  CitySkylinePainter({required this.progress, required this.windowGlow});

  final double progress;
  final double windowGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final buildings = _buildings(size);
    final baseY = size.height * 0.92;

    for (final b in buildings) {
      final left = b.left * size.width;
      final width = b.width * size.width;
      final height = b.height * size.height * progress;
      final top = baseY - height;

      final outline = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final fill = Paint()
        ..color = const Color(0xFF111111).withValues(alpha: progress)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, outline);

      _drawWindows(canvas, left, top, width, height, b.density);
    }
  }

  void _drawWindows(Canvas canvas, double left, double top, double width, double height, double density) {
    const cols = 4;
    final rows = (height / 14).floor().clamp(2, 12);
    final cellW = width / cols;
    final cellH = height / rows;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c) % 3 == 0) continue;
        if (math.Random((left.toInt() + r * 7 + c * 13)).nextDouble() > density) continue;

        final flicker = 0.35 + 0.65 * ((math.sin(windowGlow * math.pi * 2 + r + c) + 1) / 2);
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: flicker * progress * 0.9)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            left + c * cellW + cellW * 0.22,
            top + r * cellH + cellH * 0.25,
            cellW * 0.45,
            cellH * 0.35,
          ),
          paint,
        );
      }
    }
  }

  List<_Building> _buildings(Size size) {
    return const [
      _Building(0.02, 0.10, 0.38, 0.55),
      _Building(0.12, 0.08, 0.52, 0.62),
      _Building(0.20, 0.11, 0.48, 0.58),
      _Building(0.31, 0.09, 0.62, 0.72),
      _Building(0.40, 0.10, 0.55, 0.65),
      _Building(0.50, 0.12, 0.70, 0.82),
      _Building(0.62, 0.09, 0.58, 0.68),
      _Building(0.71, 0.10, 0.65, 0.78),
      _Building(0.81, 0.08, 0.50, 0.60),
      _Building(0.89, 0.11, 0.42, 0.52),
    ];
  }

  @override
  bool shouldRepaint(covariant CitySkylinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.windowGlow != windowGlow;
  }
}

class _Building {
  const _Building(this.left, this.width, this.height, this.density);
  final double left;
  final double width;
  final double height;
  final double density;
}
