import 'package:flutter/material.dart';

import 'city_skyline_painter.dart';
import 'location_pin_pulse.dart';
import 'perspective_grid_painter.dart';

class UrbanSplashBody extends StatelessWidget {
  const UrbanSplashBody({
    super.key,
    required this.logoOpacity,
    required this.logoScale,
    required this.brandSlide,
    required this.brandOpacity,
    required this.lineWidth,
    required this.taglineOpacity,
    required this.skylineProgress,
    required this.windowGlow,
    required this.gridProgress,
    required this.gridShift,
    required this.pinOpacity,
    required this.pinScale,
    required this.pinPulse,
    required this.pinRipple,
    required this.iconAnimations,
    required this.loaderOpacity,
    required this.loaderRotation,
  });

  final Animation<double> logoOpacity;
  final Animation<double> logoScale;
  final Animation<double> brandSlide;
  final Animation<double> brandOpacity;
  final Animation<double> lineWidth;
  final Animation<double> taglineOpacity;
  final Animation<double> skylineProgress;
  final Animation<double> windowGlow;
  final Animation<double> gridProgress;
  final Animation<double> gridShift;
  final Animation<double> pinOpacity;
  final Animation<double> pinScale;
  final Animation<double> pinPulse;
  final Animation<double> pinRipple;
  final List<Animation<double>> iconAnimations;
  final Animation<double> loaderOpacity;
  final Animation<double> loaderRotation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        logoOpacity,
        logoScale,
        brandSlide,
        brandOpacity,
        lineWidth,
        taglineOpacity,
        skylineProgress,
        windowGlow,
        gridProgress,
        gridShift,
        pinOpacity,
        pinScale,
        pinPulse,
        pinRipple,
        loaderOpacity,
        loaderRotation,
        ...iconAnimations,
      ]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050505), Color(0xFF0A0A0A), Color(0xFF111111)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.42,
                child: CustomPaint(
                  painter: PerspectiveGridPainter(
                    progress: gridProgress.value,
                    shift: gridShift.value,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.34,
                child: CustomPaint(
                  painter: CitySkylinePainter(
                    progress: skylineProgress.value,
                    windowGlow: windowGlow.value,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    UrbanLogoMark(opacity: logoOpacity.value, scale: logoScale.value),
                    const SizedBox(height: 14),
                    Transform.translate(
                      offset: Offset(0, brandSlide.value),
                      child: Opacity(
                        opacity: brandOpacity.value,
                        child: Column(
                          children: [
                            const Text(
                              'URBAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SERVICES',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 180 * lineWidth.value,
                      child: Divider(color: Colors.white.withValues(alpha: 0.35), thickness: 1),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: taglineOpacity.value,
                      child: Text(
                        'All Urban Services, One App',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    LocationPinPulse(
                      opacity: pinOpacity.value,
                      scale: pinScale.value,
                      pulse: pinPulse.value,
                      ripple: pinRipple.value,
                    ),
                    const SizedBox(height: 8),
                    ServiceIconRow(animations: iconAnimations),
                    const Spacer(),
                    Opacity(
                      opacity: loaderOpacity.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
