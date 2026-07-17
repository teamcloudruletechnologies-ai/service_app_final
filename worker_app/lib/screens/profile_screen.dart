import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'worker_kyc_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  bool _editMode = false;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _apiService.init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _apiService.updateWorkerProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _editMode = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: AppTheme.olive),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final kycStatus = user?.kycStatus ?? 'not_submitted';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          if (!_editMode)
            TextButton.icon(
              onPressed: () => setState(() => _editMode = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          if (_editMode)
            TextButton(
              onPressed: () => setState(() => _editMode = false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true ? user!.name[0] : 'W').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: user?.status == 'active' ? AppTheme.olive : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            user?.status == 'active' ? Icons.check : Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Worker',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user?.experienceYears != null) ...[
                          Text(
                            '${user!.experienceYears} yrs exp',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            color: Colors.white.withValues(alpha: 0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ],
                        if (user?.serviceType != null)
                          Text(
                            user!.serviceType!,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user?.status == 'active'
                          ? AppTheme.olive.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: user?.status == 'active' ? AppTheme.olive : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user?.status.toUpperCase() ?? 'INACTIVE',
                          style: TextStyle(
                            color: user?.status == 'active' ? AppTheme.olive : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Personal Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    _ProfileField(
                      label: 'Full Name',
                      icon: Icons.person_outlined,
                      controller: _nameCtrl,
                      editable: _editMode,
                    ),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      controller: _emailCtrl,
                      editable: _editMode,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      controller: _phoneCtrl,
                      editable: _editMode,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),

            if (_editMode) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // KYC Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kycStatus == 'approved'
                        ? AppTheme.olive.withValues(alpha: 0.1)
                        : kycStatus == 'pending'
                            ? AppTheme.sandal.withValues(alpha: 0.3)
                            : AppTheme.zomatoRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: kycStatus == 'approved'
                        ? AppTheme.olive
                        : kycStatus == 'pending'
                            ? AppTheme.sandal
                            : AppTheme.zomatoRed,
                    size: 22,
                  ),
                ),
                title: Text(
                  'KYC Verification',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  kycStatus == 'approved'
                      ? 'Verified'
                      : kycStatus == 'pending'
                          ? 'Under review'
                          : kycStatus == 'rejected'
                              ? 'Rejected - re-upload'
                              : 'Not submitted',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkerKycScreen()),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppTheme.zomatoRed),
              label: const Text('Sign Out', style: TextStyle(color: AppTheme.zomatoRed, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppTheme.zomatoRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.editable,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool editable;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        if (editable)
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppTheme.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          )
        else
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.text.isNotEmpty ? controller.text : 'Not set',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: controller.text.isNotEmpty ? AppTheme.primary : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
