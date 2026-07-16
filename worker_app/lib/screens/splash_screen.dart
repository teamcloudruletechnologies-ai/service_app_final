import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
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
        color: Colors.white,
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
