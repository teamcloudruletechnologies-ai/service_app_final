import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'main_shell.dart';
import 'user_onboarding_screen.dart';
import '../models/models.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  

  
  // OTP Fields (6 digits)
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _showOtpStep = false;
  bool _localLoading = false;
  bool _isPhoneValid = false;
  
  // Timer for Resend OTP
  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void reassemble() {
    super.reassemble();
    if (_otpControllers.length != 6) {
      _otpControllers.clear();
      _otpControllers.addAll(List.generate(6, (_) => TextEditingController()));
    }
    if (_otpFocusNodes.length != 6) {
      _otpFocusNodes.clear();
      _otpFocusNodes.addAll(List.generate(6, (_) => FocusNode()));
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_validatePhone);
    _phoneCtrl.dispose();
    for (var ctrl in _otpControllers) {
      ctrl.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _validatePhone() {
    final cleaned = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final isValid = cleaned.length == 10;
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  void _startResendTimer() {
    _secondsRemaining = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  void _onGetOtpPressed() {
    if (!_phoneFormKey.currentState!.validate()) return;
    
    // Auto fill test OTP 123456 for smooth testing
    final testOtp = '123456';
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = testOtp[i];
    }

    setState(() {
      _showOtpStep = true;
    });
    _startResendTimer();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔑 Test OTP 123456 auto-filled! Tap Verify OTP to proceed.'),
        duration: Duration(seconds: 4),
        backgroundColor: Color(0xFF4A5343),
      ),
    );
    
    // Auto focus last OTP field or verify button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes[5].requestFocus();
    });
  }

  Future<void> _verifyAndProceed() async {
    final otpStr = _otpControllers.map((c) => c.text).join();
    if (otpStr.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    if (otpStr != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Use 123456 for local testing.')),
      );
      return;
    }

    setState(() {
      _localLoading = true;
    });

    final auth = context.read<AuthProvider>();
    final enteredPhone = _phoneCtrl.text.trim();
    // Normalize format to +91XXXXXXXXXX
    final cleanPhone = enteredPhone.startsWith('+91')
        ? enteredPhone
        : enteredPhone.startsWith('91') && enteredPhone.length > 10
            ? '+$enteredPhone'
            : '+91$enteredPhone';

    Map<String, dynamic>? res;
    String? localError;

    try {
      res = await auth.phoneLogin(cleanPhone, role: 'user');
    } catch (e) {
      localError = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _localLoading = false;
    });

    if (res != null) {
      final isNew = res['is_new'] as bool? ?? false;
      final account = UserAccount.fromJson(res['account'] as Map<String, dynamic>);

      // Sync fresh bookings for the logged in user
      context.read<BookingProvider>().loadBookings();

      // Always navigate to Profile Setup screen after OTP verification
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserOnboardingScreen()),
      );
    } else {
      final String? errorText = auth.error ?? localError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText ?? 'Verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.loading || _localLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3), // Pure White Background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back action row (only on OTP step)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      height: _showOtpStep ? 48 : 0,
                      child: _showOtpStep
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _showOtpStep = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Color(0xFF1A1A1A)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Back',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(height: _showOtpStep ? 16 : 48),

                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    firstCurve: Curves.easeInOut,
                    secondCurve: Curves.easeInOut,
                    crossFadeState: !_showOtpStep
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildPhoneEntryStep(isLoading),
                    secondChild: _buildOtpVerificationStep(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // PHONE NUMBER INPUT STEP (Welcome Back state - Light Theme)
  Widget _buildPhoneEntryStep(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                );
              },
              child: const Text(
                'Skip for now ➡️',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Elegant Header Titles
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A), // Primary Accent (Near Black)
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.phone_android_rounded, size: 24, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'Login with your mobile number',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),



          // Mobile Number input field with country code selector (+91)
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            cursorColor: const Color(0xFF1A1A1A),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: 1.0,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter Mobile Number',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                  SizedBox(width: 12),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter mobile number';
              }
              final cleaned = v.replaceAll(RegExp(r'\D'), '');
              if (cleaned.length < 10) {
                return 'Enter a valid 10-digit number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Primary Send OTP Button
          ElevatedButton(
            onPressed: (isLoading || !_isPhoneValid) ? null : _onGetOtpPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPhoneValid ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
              foregroundColor: _isPhoneValid ? Colors.white : const Color(0xFF9CA3AF),
              disabledBackgroundColor: const Color(0xFFF3F4F6),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Send OTP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: _isPhoneValid ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Small text below
          const Text(
            'OTP will be sent to your registered mobile number',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "New to ServiceApp? Enter your phone number. We'll set up your account on verification.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // OTP SCREEN (Second State - Verify OTP)
  Widget _buildOtpVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading
        const Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 6),
        // Display entered mobile number
        Text(
          'We sent a 6-digit verification code to +91 ${_phoneCtrl.text}',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7280), // Secondary Text
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        // Demo OTP helper banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4A5343).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4A5343).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFF4A5343)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Demo Mode: OTP is 123456',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ),
              TextButton(
                onPressed: () {
                  final testOtp = '123456';
                  for (int i = 0; i < 6; i++) {
                    _otpControllers[i].text = testOtp[i];
                  }
                  setState(() {});
                },
                child: const Text('Auto-fill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5343))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6-digit OTP input boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 54,
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
                cursorColor: const Color(0xFF1A1A1A),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
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
        const SizedBox(height: 28),

        // Countdown Timer & Resend Option Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '00:${_secondsRemaining.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            _secondsRemaining > 0
                ? const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
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

      ],
    );
  }
}
