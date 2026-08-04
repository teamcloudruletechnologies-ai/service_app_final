import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
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
    '🏠 Home Maintenance',
    '❄️ Appliance Services',
    '💄 Beauty & Wellness',
    '🧼 Cleaning',
    '🔧 Plumbing',
    '⚡ Electrical',
    '📹 Security & CCTV',
  ];

  List<String> _getServicesForCategory(String categoryName) {
    final cleanName = categoryName.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim().toLowerCase();
    
    if (cleanName.contains('clean')) {
      return [
        'Full Home Deep Clean',
        'Kitchen Deep Clean & Degreasing',
        'Bathroom Cleaning & Sanitization',
        'Sofa & Carpet Dry Cleaning',
        'Window & Glass Cleaning',
        'Balcony & Floor Scrubbing',
      ];
    } else if (cleanName.contains('appliance')) {
      return [
        'AC Service, Gas Charge & Repair',
        'Washing Machine Repair',
        'Refrigerator / Fridge Repair',
        'Water Purifier / RO Service',
        'Microwave & Oven Repair',
        'TV Wall Mount & Repair',
      ];
    } else if (cleanName.contains('beauty') || cleanName.contains('wellness')) {
      return [
        'Salon & Spa Treatments',
        'Haircut & Hair Styling',
        'Facial, Waxing & Threading',
        'Manicure & Pedicure',
        'Bridal & Party Makeup',
      ];
    } else if (cleanName.contains('security') || cleanName.contains('cctv')) {
      return [
        'CCTV Camera Installation & Setup',
        'Security Alarm & Sensor Fitting',
        'Biometric Lock Installation',
        'DVR / NVR Configuration & Cabling',
      ];
    } else if (cleanName.contains('plumb')) {
      return [
        'Tap Fitting & Leakage Fix',
        'Toilet & Commode Unblocking',
        'Drain & Pipe Cleaning',
        'Water Tank Cleaning',
        'Motor Pump Repair & Fitting',
        'Basin & Sink Fitting',
      ];
    } else if (cleanName.contains('electr')) {
      return [
        'Fan, Switch & Socket Installation',
        'MCB & Fuse Box Repair',
        'Light & Chandelier Fitting',
        'House Wiring & Short Circuit Fix',
        'Inverter Installation & Repair',
      ];
    } else {
      return [
        'Furniture Repair & Assembly',
        'Door Lock & Latch Fitting',
        'Full Home Wall Painting',
        'Wall Drilling & Frame Hanging',
        'Wooden Cabinet & Wardrobe Fix',
        'General Handyman & Maintenance',
      ];
    }
  }

  // DB Categories & Services
  List<ServiceCategory> _dbCategories = [];
  final Map<int, List<ServiceItem>> _categoryServicesMap = {};
  final Set<String> _selectedServices = {};

  List<String> get categoryOptions {
    if (_dbCategories.isNotEmpty) {
      return _dbCategories.map((c) => c.name).toList();
    }
    return _serviceTypes;
  }

  List<String> _getServicesListForCategory(String categoryName) {
    final cleanCategory = categoryName.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim().toLowerCase();
    
    final dbCat = _dbCategories.firstWhere(
      (c) => c.name.toLowerCase().contains(cleanCategory) || cleanCategory.contains(c.name.toLowerCase()),
      orElse: () => const ServiceCategory(id: -1, name: '', status: ''),
    );

    if (dbCat.id != -1 && _categoryServicesMap.containsKey(dbCat.id)) {
      final dbServices = _categoryServicesMap[dbCat.id]!.map((s) => s.name).toList();
      if (dbServices.isNotEmpty) return dbServices;
    }

    return _getServicesForCategory(categoryName);
  }

  void _onCategoryChanged(String? val) {
    setState(() {
      _selectedServiceType = val;
      _selectedServices.clear();
      if (val != null) {
        final services = _getServicesListForCategory(val);
        _selectedServices.addAll(services);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadServiceableCities();
    _fetchCategoriesAndServices();
  }

  Future<void> _fetchCategoriesAndServices() async {
    try {
      final api = context.read<ApiService>();
      final pagedCats = await api.fetchCategories();
      final pagedServs = await api.fetchServices();

      if (mounted) {
        setState(() {
          _dbCategories = pagedCats.items;
          _categoryServicesMap.clear();
          for (final service in pagedServs.items) {
            if (service.categoryId != null) {
              _categoryServicesMap.putIfAbsent(service.categoryId!, () => []).add(service);
            }
          }
        });
      }
    } catch (_) {}
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
        const SnackBar(content: Text('Please select a Category Type')),
      );
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service you offer')),
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

                // Category Type Dropdown (Fetched from DB)
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  hint: const Text('Select Category'),
                  decoration: const InputDecoration(
                    labelText: 'Category Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categoryOptions.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: _onCategoryChanged,
                  validator: (v) => v == null ? 'Please select your category' : null,
                ),
                if (_selectedServiceType != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select services you offer under $_selectedServiceType:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap chips to select or unselect services you provide:',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _getServicesListForCategory(_selectedServiceType!).map((service) {
                            final isSelected = _selectedServices.contains(service);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedServices.remove(service);
                                  } else {
                                    _selectedServices.add(service);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFEF3C7) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                      size: 14,
                                      color: isSelected ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      service,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF92400E) : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
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
