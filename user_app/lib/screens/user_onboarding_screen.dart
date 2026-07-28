import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadCategories();
      catalog.loadServices();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          // Background Watermark Text "SERVICE"
          Positioned(
            left: -20,
            top: MediaQuery.of(context).size.height * 0.15,
            child: Text(
              'SERVICE',
              style: TextStyle(
                fontSize: 110,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.07),
                letterSpacing: 2,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status / Location Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '9:41',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.wifi, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Icon(Icons.battery_full, color: Colors.white, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hero Image Illustration
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          'https://static.vecteezy.com/system/resources/thumbnails/047/020/868/small_2x/a-male-plumber-s-hand-repairing-a-leaking-sink-pipe-with-an-adjustable-wrench-free-photo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.cleaning_services_rounded,
                            size: 140,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom Content Card
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A Cleaner Home\nStarts Here Cleaning',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'From quick touch-ups to deep cleaning, our verified professionals deliver reliable, top-rated home services.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Profile Setup Form Fields
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your Full Name',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your Email (Optional)',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Bottom CTA Button Bar
                      GestureDetector(
                        onTap: () async {
                          final auth = context.read<AuthProvider>();
                          final name = _nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your full name to set up profile')),
                            );
                            return;
                          }
                          await auth.updateUserProfile(
                            name: name,
                            email: _emailCtrl.text.trim(),
                          );
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainShell()),
                            );
                          }
                        },
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Save Profile & Get Started',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.primary,
                                child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}