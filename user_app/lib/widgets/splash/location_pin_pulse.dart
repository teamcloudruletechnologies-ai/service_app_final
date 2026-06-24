import 'package:flutter/material.dart';

class LocationPinPulse extends StatelessWidget {
  const LocationPinPulse({
    super.key,
    required this.pulse,
    required this.ripple,
    required this.opacity,
    required this.scale,
  });

  final double pulse;
  final double ripple;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.scale(
              scale: 0.5 + ripple * 0.9 + i * 0.22,
              child: Opacity(
                opacity: (1 - ripple - i * 0.18).clamp(0.0, 1.0) * opacity * 0.35,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
                  ),
                ),
              ),
            ),
          Transform.scale(
            scale: scale * (0.96 + pulse * 0.06),
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(
                size: const Size(72, 96),
                painter: _PinPainter(glow: pulse),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.glow});

  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15 + glow * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawCircle(Offset(centerX, size.height * 0.72), 22 + glow * 8, glowPaint);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(centerX, size.height * 0.08)
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.22,
        size.width * 0.88,
        size.height * 0.52,
        centerX,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.52,
        size.width * 0.12,
        size.height * 0.22,
        centerX,
        size.height * 0.08,
      )
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    canvas.drawCircle(
      Offset(centerX, size.height * 0.34),
      11,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => oldDelegate.glow != glow;
}

class UrbanLogoMark extends StatelessWidget {
  const UrbanLogoMark({super.key, required this.opacity, required this.scale});

  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: CustomPaint(
          size: const Size(56, 56),
          painter: _LogoPainter(),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;

    canvas.drawCircle(
      Offset(cx, size.height * 0.18),
      5,
      Paint()..color = Colors.white,
    );

    final uPath = Path()
      ..moveTo(cx - 16, size.height * 0.34)
      ..quadraticBezierTo(cx - 16, size.height * 0.78, cx, size.height * 0.78)
      ..quadraticBezierTo(cx + 16, size.height * 0.78, cx + 16, size.height * 0.34);

    canvas.drawPath(uPath, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ServiceIconRow extends StatelessWidget {
  const ServiceIconRow({super.key, required this.animations});

  final List<Animation<double>> animations;

  static const _icons = [
    Icons.build_outlined,
    Icons.water_drop_outlined,
    Icons.bolt_outlined,
    Icons.cleaning_services_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_icons.length, (index) {
        return AnimatedBuilder(
          animation: animations[index],
          builder: (context, child) {
            final t = animations[index].value;
            return Transform.translate(
              offset: Offset(0, (1 - t) * 18),
              child: Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.7 + t * 0.3,
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 28, right: index == 3 ? 0 : 0),
                    child: Icon(_icons[index], color: Colors.white.withValues(alpha: 0.92), size: 26),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
