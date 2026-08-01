import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'user_onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _showOtpStep = false;
  bool _isPhoneValid = false;

  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_validatePhone);
  }

  void _validatePhone() {
    final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final valid = cleaned.length >= 10;
    if (valid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = valid;
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_validatePhone);
    _phoneCtrl.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _onGetOtpPressed() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

    final res = await auth.phoneLogin(cleaned);
    final success = res != null;

    if (!mounted) return;

    if (success) {
      setState(() {
        _showOtpStep = true;
      });
      _startResendTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to send OTP. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyAndProceed() async {
    final otpStr = _otpControllers.map((e) => e.text.trim()).join();
    if (otpStr.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits of the OTP.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    final success = await auth.verifyOtp(otpStr);

    if (!mounted) return;

    if (success) {
      if (auth.user != null && auth.user!.needsOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserOnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid OTP code. Try 123456 in demo mode.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Animated Top Back Navigation Button (Screen 2 & 3 Mockup)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _showOtpStep ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 24),
                secondChild: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showOtpStep = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF1A1A1A)),
                            SizedBox(width: 6),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: !_showOtpStep ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: _buildPhoneEntryStep(isLoading),
                secondChild: _buildOtpVerificationStep(isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PHONE NUMBER ENTRY STEP (Mockup Screen 2)
  Widget _buildPhoneEntryStep(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back! 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Login to your account',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF718096),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 32),

          // Side-by-Side Country Code + Phone Input Card Container (Mockup Screen 2)
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
                    Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    hintStyle: const TextStyle(
                      color: Color(0xFFA0AEC0),
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                    final cleaned = v.replaceAll(RegExp(r'\D'), '');
                    if (cleaned.length < 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Primary Yellow Send OTP Button (Mockup 2)
          ElevatedButton(
            onPressed: (isLoading || !_isPhoneValid) ? null : _onGetOtpPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPhoneValid ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.5),
              foregroundColor: const Color(0xFF1A1A1A),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF1A1A1A)),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
          ),
          const SizedBox(height: 36),

          // Terms & Privacy Policy Footer
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: Color(0xFF718096), height: 1.5),
                children: [
                  TextSpan(text: 'By continuing, you agree to our\n'),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OTP VERIFICATION STEP (Mockup Screen 3)
  Widget _buildOtpVerificationStep(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit verification code to +91 ${_phoneCtrl.text}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 20),

        // Demo Mode Helper Banner (Screen 3 Mockup)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, size: 20, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Demo Mode: OTP is 123456',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final testOtp = '123456';
                  for (int i = 0; i < 6; i++) {
                    _otpControllers[i].text = testOtp[i];
                  }
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Auto-fill',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6-Digit OTP TextFields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                textAlign: TextAlign.center,
                maxLength: 1,
                cursorColor: AppTheme.primary,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2.0),
                  ),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      _verifyAndProceed();
                    }
                  } else {
                    if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '00:${_secondsRemaining.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            _secondsRemaining > 0
                ? const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Color(0xFFA0AEC0),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                : GestureDetector(
                    onTap: _startResendTimer,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 28),

        // Full-width Golden Yellow Verify OTP Button
        ElevatedButton(
          onPressed: isLoading ? null : _verifyAndProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: const Color(0xFF1A1A1A),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF1A1A1A)),
                )
              : const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
        ),
      ],
    );
  }
}
