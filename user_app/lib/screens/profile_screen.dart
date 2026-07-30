import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showEditDialog(BuildContext context, UserAccount user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFFF5F5F3),
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4A5343),
                                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              child: const Text('Change Photo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Full Name', nameCtrl, Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField('Email Address', emailCtrl, Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildTextField('Phone Number', phoneCtrl, Icons.phone_outlined),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                foregroundColor: const Color(0xFF4B5563),
                                backgroundColor: Colors.transparent,
                              ),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final name = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();

                                final auth = context.read<AuthProvider>();
                                final ok = await auth.updateUserProfile(name: name, email: email, phone: phone);

                                if (!dialogContext.mounted) return;
                                Navigator.pop(dialogContext);

                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile updated successfully')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(auth.error ?? 'Failed to update profile')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                backgroundColor: const Color(0xFF0A1128),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          cursorColor: const Color(0xFF1A1A1A),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (label == 'Email Address' && !v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Hero(
              // FIX: was 'profile_avatar_hero' which collided with the same
              // tag used in bookings_screen.dart. Because MainShell uses an
              // IndexedStack, all tab screens (Home, Bookings, Profile, Menu)
              // stay mounted simultaneously (just offstage), so two Hero
              // widgets sharing one tag existed in the tree at the same time.
              // That triggered "multiple heroes that share the same tag
              // within a subtree", which cascaded into the layout crashes
              // (infinite width / RenderBox not laid out / blank bookings
              // list) seen in the logs. Giving each screen's Hero its own
              // unique tag fixes it.
              tag: 'profile_avatar_hero_profile',
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.name ?? 'User',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade200, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${user?.credits ?? 0} Credits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? 'Not set'),
          _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? 'Not set'),
          _InfoTile(icon: Icons.verified_outlined, label: 'Status', value: user?.status ?? 'active'),
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Primary Saved Address',
            value: user?.address != null && user!.address.isNotEmpty
                ? user.address
                : 'No address set yet (GPS Auto-Detected)',
          ),
          const SizedBox(height: 32),
          if (user != null) ...[
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(context, user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}