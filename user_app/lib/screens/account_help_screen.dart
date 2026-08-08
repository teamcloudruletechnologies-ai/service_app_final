import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AccountHelpScreen extends StatefulWidget {
  const AccountHelpScreen({super.key});

  @override
  State<AccountHelpScreen> createState() => _AccountHelpScreenState();
}

class _AccountHelpScreenState extends State<AccountHelpScreen> {
  bool _loading = false;

  Future<void> _logoutAllDevices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Logout From All Devices?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'This will invalidate active login sessions on all other phones and tablets. You will remain logged in on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        final apiService = context.read<ApiService>();
        await apiService.submitAccountRequest(requestType: 'logout_all_devices');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully logged out from all other devices.'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _showDeleteAccountDialog() {
    final reasonCtrl = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account deletion is permanent. Your booking history, wallet balance, and addresses will be erased.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Reason for deletion (optional)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      try {
                        final apiService = context.read<ApiService>();
                        await apiService.submitAccountRequest(
                          requestType: 'deletion',
                          reason: reasonCtrl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account deletion request submitted. An admin will process it shortly.'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Request Deletion', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeMobileDialog() {
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Mobile Number', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your new 10-digit mobile number. Our support team will verify before updating.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+91 ',
                hintText: '98765 43210',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (phoneCtrl.text.trim().length >= 10) {
                final apiService = context.read<ApiService>();
                await apiService.submitAccountRequest(
                  requestType: 'mobile_change',
                  details: {'new_phone': phoneCtrl.text.trim()},
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mobile change request submitted to Support.'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Account Password', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        content: const Text(
          'A password reset link will be sent to your registered email address or phone OTP.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final apiService = context.read<ApiService>();
              await apiService.submitAccountRequest(requestType: 'password_reset');
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset request initiated.'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.w800)),
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
          'Account Help & Settings',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'ACCOUNT MANAGEMENT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1.0),
              ),
            ),

            // Card 1: Change Mobile Number
            _ActionTile(
              icon: Icons.phone_android_rounded,
              title: 'Change Mobile Number',
              subtitle: 'Request mobile number update with OTP verification',
              iconBg: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              onTap: _showChangeMobileDialog,
            ),

            const SizedBox(height: 12),

            // Card 2: Reset Password
            _ActionTile(
              icon: Icons.lock_reset_rounded,
              title: 'Reset Password',
              subtitle: 'Send password reset link to email or phone',
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFD97706),
              onTap: _showResetPasswordDialog,
            ),

            const SizedBox(height: 12),

            // Card 3: Logout From All Devices
            _ActionTile(
              icon: Icons.phonelink_erase_rounded,
              title: 'Logout From All Devices',
              subtitle: 'Invalidate all other active login sessions',
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
              onTap: _logoutAllDevices,
            ),

            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'DANGER ZONE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFFDC2626), letterSpacing: 1.0),
              ),
            ),

            // Card 4: Delete Account
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account and stored data',
              iconBg: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFDC2626),
              isDanger: true,
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final bool isDanger;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDanger ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}
