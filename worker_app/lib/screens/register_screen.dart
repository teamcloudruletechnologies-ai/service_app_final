import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  // Worker-specific controllers
  final _experienceCtrl = TextEditingController();
  String? _selectedServiceType;
  String? _selectedCity;
  bool _obscure = true;

  // Dynamic cities fetched from backend
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
      // Extract unique cities
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
      // Fallback: allow free text input if API fails
      setState(() => _loadingCities = false);
    }   
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required for Service Partners')),
      );
      return;
    }
    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Service Type')),
      );
      return;
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your operating city')),
      );
      return;
    }
    
    final exp = int.tryParse(_experienceCtrl.text.trim()) ?? 0;

    final auth = context.read<AuthProvider>();
    final ok = await auth.registerWorker(
      name: name,
      email: email.isEmpty ? null : email,
      phone: phone,
      password: password,
      serviceType: _selectedServiceType!,
      experienceYears: exp,
      city: _selectedCity!,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Join as Service Partner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.handyman_outlined,
                  size: 64,
                  color: Colors.black,
                ),
                const SizedBox(height: 24),
                
                // Form Header
                const Text(
                  'Partner Registration',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameCtrl,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Required)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  cursorColor: Colors.black,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  decoration: const InputDecoration(
                    labelText: 'Primary Service Skill',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _serviceTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedServiceType = val),
                  validator: (v) => v == null ? 'Please select your skill' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _experienceCtrl,
                  keyboardType: TextInputType.number,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.work_history_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Dynamic city dropdown from admin-configured locations
                if (_loadingCities)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_city_outlined, color: Colors.grey),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        ),
                        SizedBox(width: 12),
                        Text('Loading available cities...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                else if (_availableCities.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Operating City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: _availableCities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCity = val),
                    validator: (v) => v == null ? 'Please select your city' : null,
                  )
                else
                  // Fallback to text input if no cities configured yet
                  TextFormField(
                    cursorColor: Colors.black,
                    decoration: const InputDecoration(
                      labelText: 'Operating City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                      hintText: 'Enter your city',
                    ),
                    onChanged: (val) => _selectedCity = val.trim(),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Register'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
