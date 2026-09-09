import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'user_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

      final res = await auth.phoneLogin(cleaned);
      if (mounted && res != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserOnboardingScreen()),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.translate('create_account'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.translate('register_subtitle'),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF718096)),
                ),
                const SizedBox(height: 32),

                // First Name & Last Name row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: context.translate('firstname'),
                          hintText: context.translate('firstname'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: context.translate('lastname'),
                          hintText: context.translate('lastname'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Full Name Input
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.translate('full_name'),
                    hintText: context.translate('enter_name'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.translate('enter_name_hint')
                      : null,
                ),
                const SizedBox(height: 16),

                // Mobile Number Input Card
                Row(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: const [
                          Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF718096)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: context.translate('enter_mobile'),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return context.translate('enter_mobile_hint');
                          if (v.replaceAll(RegExp(r'\D'), '').length < 10) return context.translate('valid_mobile');
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Send OTP Button
                ElevatedButton(
                  onPressed: _loading ? null : _onRegisterPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF1A1A1A),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
                      : Text(context.translate('send_otp'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.translate('already_have_account'), style: const TextStyle(color: Color(0xFF718096))),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        context.translate('login'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

