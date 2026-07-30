import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'worker_onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) {
          if (auth.isLoggedIn) {
            if (auth.user?.needsOnboarding == true) {
              return const WorkerOnboardingScreen();
            }
            return const MainShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: AppTheme.milkWhite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.olive,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.home_repair_service_rounded, size: 48, color: AppTheme.milkWhite),
            ),
            const SizedBox(height: 20),
            const Text(
              'Urban Service',
              style: TextStyle(color: AppTheme.primary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Home services at your doorstep',
              style: TextStyle(color: Color(0xFF9A978F)),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.olive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
