import 'package:flutter/material.dart';

class WorkerSettingsScreen extends StatefulWidget {
  const WorkerSettingsScreen({super.key});

  @override
  State<WorkerSettingsScreen> createState() => _WorkerSettingsScreenState();
}

class _WorkerSettingsScreenState extends State<WorkerSettingsScreen> {
  bool _notificationsOn = true;
  String _language = 'English';

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
        content: const Text(
          'Are you sure you want to permanently delete your worker profile and data? This action cannot be undone.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion request submitted to admin')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
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
            // ─── 1. GENERAL SECTION ───
            const Text(
              'General',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    trailingText: _language,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (ctx) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Language / மொழியைத் தேர்ந்தெடுக்கவும்',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: const Text('English'),
                                  trailing: _language == 'English' ? const Icon(Icons.check_circle, color: Color(0xFF0F172A)) : null,
                                  onTap: () {
                                    setState(() => _language = 'English');
                                    Navigator.pop(ctx);
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  title: const Text('தமிழ் (Tamil)'),
                                  trailing: _language == 'Tamil' ? const Icon(Icons.check_circle, color: Color(0xFF0F172A)) : null,
                                  onTap: () {
                                    setState(() => _language = 'Tamil');
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildSettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    trailingText: _notificationsOn ? 'On' : 'Off',
                    onTap: () {
                      setState(() {
                        _notificationsOn = !_notificationsOn;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── 2. ACCOUNT SECTION ───
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link sent to phone via SMS')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildSettingRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),
                  _buildSettingRow(
                    icon: Icons.info_outline_rounded,
                    title: 'App Version',
                    trailingText: '1.2.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ─── 3. DELETE ACCOUNT RED BUTTON ───
            Center(
              child: TextButton(
                onPressed: _showDeleteAccountDialog,
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0F172A)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
