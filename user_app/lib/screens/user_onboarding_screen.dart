import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Madurai');
  final _districtCtrl = TextEditingController(text: 'Madurai');
  final _stateCtrl = TextEditingController(text: 'Tamil Nadu');
  final _pincodeCtrl = TextEditingController();

  String _userType = 'Home'; // 'Home' or 'Other'
  bool _loadingLocation = false;
  bool _saving = false;
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _houseCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _showLocationDialog({required String title, required String message, required VoidCallback onAction, required String actionLabel}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppTheme.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showLocationDialog(
            title: 'GPS Location Disabled',
            message: 'Please enable GPS location services to auto-detect your delivery address.',
            onAction: () => Geolocator.openLocationSettings(),
            actionLabel: 'Turn On GPS',
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showLocationDialog(
              title: 'Permission Required',
              message: 'Location permission is required to detect nearby service professionals.',
              onAction: () => Geolocator.requestPermission(),
              actionLabel: 'Grant Permission',
            );
          }
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showLocationDialog(
            title: 'Permission Denied Permanently',
            message: 'Location permission is permanently denied. Please enable it in Settings.',
            onAction: () => Geolocator.openAppSettings(),
            actionLabel: 'Open Settings',
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _loadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location detected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final fullAddress = [
        _houseCtrl.text.trim(),
        _areaCtrl.text.trim(),
        _cityCtrl.text.trim(),
        _districtCtrl.text.trim(),
        _stateCtrl.text.trim(),
        _pincodeCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join(', ');

      final auth = context.read<AuthProvider>();
      await auth.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: fullAddress.isEmpty ? null : fullAddress,
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Complete Your Profile', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Progress Bar Header (Screen 4 Mockup - Step 2 of 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Step 2 of 3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                    Text('66%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF718096))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.66,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Help us personalize your experience',
                  style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                ),
                const SizedBox(height: 24),

                // Circular Profile Avatar
                Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: const Icon(Icons.person_rounded, size: 52, color: Color(0xFF1A1A1A)),
                  ),
                  ),
                ),
                const SizedBox(height: 28),

                // Full Name Input
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email Address Input
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Select Your Type (Home vs Other)
                const Text(
                  'Select Your Type',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _userType = 'Home'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _userType == 'Home' ? AppTheme.primary.withOpacity(0.15) : Colors.white,
                            border: Border.all(
                              color: _userType == 'Home' ? AppTheme.primary : const Color(0xFFE2E8F0),
                              width: _userType == 'Home' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _userType == 'Home' ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _userType == 'Home' ? AppTheme.primaryDark : const Color(0xFFA0AEC0),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _userType = 'Other'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _userType == 'Other' ? AppTheme.primary.withOpacity(0.15) : Colors.white,
                            border: Border.all(
                              color: _userType == 'Other' ? AppTheme.primary : const Color(0xFFE2E8F0),
                              width: _userType == 'Other' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _userType == 'Other' ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _userType == 'Other' ? AppTheme.primaryDark : const Color(0xFFA0AEC0),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('Other', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // GPS Auto-Detect Address Button
                OutlinedButton.icon(
                  onPressed: _loadingLocation ? null : _fetchLocation,
                  icon: _loadingLocation
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                      : const Icon(Icons.my_location_rounded, color: AppTheme.primaryDark),
                  label: Text(_lat != null ? '📍 GPS Location Detected' : 'Use Current GPS Location'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Yellow Next Button (Screen 4 Mockup)
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: const Color(0xFF1A1A1A),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF1A1A1A)))
                      : const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
