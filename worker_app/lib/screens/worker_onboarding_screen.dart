import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Tamil Nadu');
  final _experienceCtrl = TextEditingController();
  
  String? _selectedServiceType;
  String? _selectedCity;
  
  List<String> _availableCities = [];
  bool _loadingCities = false;

  final List<String> _serviceTypes = [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Appliance Repair',
    'Painting',
    'Carpentry',
    'Pest Control'
  ];

  @override
  void initState() {
    super.initState();
    _loadServiceableCities();
  }

  Future<void> _loadServiceableCities() async {
    setState(() => _loadingCities = true);
    try {
      final api = context.read<ApiService>();
      final locations = await api.fetchServiceableLocations();
      final cities = locations
          .map((l) => (l['city'] as String?)?.trim() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _availableCities = cities;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _stateCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final city = _selectedCity;
    final serviceType = _selectedServiceType;
    final exp = int.tryParse(_experienceCtrl.text.trim()) ?? 0;

    if (city == null || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an operating city')),
      );
      return;
    }
    if (serviceType == null || serviceType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateWorkerProfile(
      name: name,
      email: email.isEmpty ? null : email,
      state: state,
      city: city,
      serviceType: serviceType,
      experienceYears: exp,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Onboarding profile update failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.loading || _loadingCities;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Partner Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join as Service Partner',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please fill in your basic details to start getting orders near your area.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailReg.hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // State
                TextFormField(
                  controller: _stateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    hintText: 'Enter your state',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  hint: const Text('Select Operating City/Area'),
                  decoration: const InputDecoration(
                    labelText: 'Operating City/Area',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: _availableCities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCity = val;
                    });
                  },
                  validator: (v) => v == null ? 'Operating city is required' : null,
                ),
                const SizedBox(height: 16),

                // Service Type
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  hint: const Text('Select Service Type'),
                  decoration: const InputDecoration(
                    labelText: 'Service Type / Skill',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _serviceTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedServiceType = val;
                    });
                  },
                  validator: (v) => v == null ? 'Service type is required' : null,
                ),
                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  controller: _experienceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'e.g. 5',
                    prefixIcon: Icon(Icons.timelapse_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Experience is required';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF3F4F6),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
