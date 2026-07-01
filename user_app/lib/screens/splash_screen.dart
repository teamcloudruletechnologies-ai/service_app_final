import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashMs = 3200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF4A5343)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_repair_service_rounded, size: 72, color: Color(0xFFE3D0BA)),
            SizedBox(height: 16),
            Text(
              'Urban Service',
              style: TextStyle(color: Color(0xFFF5F5F3), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            SizedBox(height: 8),
            Text(
              'Home services at your doorstep',
              style: TextStyle(color: Color(0xFFE3D0BA)),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFFE3D0BA)),
          ],
        ),
      ),
    );
  }
}
