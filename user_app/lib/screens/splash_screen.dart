import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/splash/urban_splash_body.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _minSplashMs = 3200;

  late final AnimationController _introController;
  late final AnimationController _loopController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandSlide;
  late final Animation<double> _brandOpacity;
  late final Animation<double> _lineWidth;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _skylineProgress;
  late final Animation<double> _gridProgress;
  late final Animation<double> _pinOpacity;
  late final Animation<double> _pinScale;
  late final Animation<double> _loaderOpacity;
  late final List<Animation<double>> _iconAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _introController.forward();
    _loopController.repeat();
    _bootstrap(); 
  }

  void _setupAnimations() {
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.0, 0.28, curve: Curves.easeOutBack)),
    );
    _brandSlide = Tween<double>(begin: -24, end: 0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.12, 0.34, curve: Curves.easeOutCubic)),
    );
    _brandOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.12, 0.34, curve: Curves.easeOut),
    );
    _lineWidth = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.28, 0.46, curve: Curves.easeInOut),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.36, 0.52, curve: Curves.easeOut),
    );
    _skylineProgress = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
    );
    _gridProgress = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.22, 0.66, curve: Curves.easeOut),
    );
    _pinOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.42, 0.62, curve: Curves.easeOut),
    );
    _pinScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.42, 0.66, curve: Curves.elasticOut)),
    );
    _loaderOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.58, 0.78, curve: Curves.easeOut),
    );

    _iconAnimations = List.generate(4, (index) {
      final start = 0.52 + index * 0.06;
      final end = (start + 0.18).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _introController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    final auth = context.read<AuthProvider>();
    await auth.init();

    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed < _minSplashMs) {
      await Future.delayed(Duration(milliseconds: _minSplashMs - elapsed));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, __, ___) => auth.isLoggedIn ? const MainShell() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF1F2937)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_repair_service_rounded, size: 72, color: Colors.black),
            SizedBox(height: 16),
            Text(
              'Urban Service',
              style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Home services at your doorstep', style: TextStyle(color: Colors.black54)),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
