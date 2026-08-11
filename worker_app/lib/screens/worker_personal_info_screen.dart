import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class WorkerPersonalInfoScreen extends StatefulWidget {
  const WorkerPersonalInfoScreen({super.key});

  @override
  State<WorkerPersonalInfoScreen> createState() => _WorkerPersonalInfoScreenState();
}

class _WorkerPersonalInfoScreenState extends State<WorkerPersonalInfoScreen> {
  final ApiService _api = ApiService();
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emergencyCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _dobCtrl = TextEditingController(text: '15 Aug 1995');
    _genderCtrl = TextEditingController(text: 'Male');
    _addressCtrl = TextEditingController(text: user?.city != null && user!.city!.isNotEmpty ? '${user.city}, Tamil Nadu, India' : 'Tamil Nadu, India');
    _emergencyCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveInformation() async {
    setState(() {
      _saving = true;
    });

    try {
      await _api.updateWorkerProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (mounted) {
        await context.read<AuthProvider>().reloadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Personal information updated successfully!'),
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Personal Information',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Avatar Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'W').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.name.isNotEmpty == true ? user!.name : 'Worker Partner',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.phone ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo update options opened')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    ),
                    child: const Text(
                      'Change Photo',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Container Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFieldItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    controller: _nameCtrl,
                    canEdit: true,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildFieldItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    controller: _emailCtrl,
                    canEdit: true,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildFieldItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date of Birth',
                    controller: _dobCtrl,
                    canEdit: false,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildFieldItem(
                    icon: Icons.wc_rounded,
                    label: 'Gender',
                    controller: _genderCtrl,
                    canEdit: false,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildFieldItem(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    controller: _addressCtrl,
                    canEdit: false,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildFieldItem(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Emergency Contact',
                    controller: _emergencyCtrl,
                    canEdit: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Bottom Black Action Button
            ElevatedButton(
              onPressed: _saving ? null : _saveInformation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // Black Primary Theme Button
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _saving ? 'Saving...' : 'Edit Information',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldItem({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool canEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}
