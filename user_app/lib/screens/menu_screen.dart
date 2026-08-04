import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'bookings_screen.dart';
import 'help_centre_screen.dart';
import 'location_picker_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final lang = Provider.of<LanguageProvider>(context, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Language / மொழி', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: !lang.isTamil ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryDark) : null,
                onTap: () {
                  lang.setLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('தமிழ் (Tamil)', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: lang.isTamil ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryDark) : null,
                onTap: () {
                  lang.setLanguage('ta');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final lang = context.watch<LanguageProvider>();

    final userName = user?.name ?? '';
    final userPhone = user?.phone ?? '';
    final userInitial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Menu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── USER PROFILE HEADER CARD ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.trim().isNotEmpty ? userName : 'Guest User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userPhone.trim().isNotEmpty ? userPhone : 'Tap below to manage account',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── SECTION 1: SERVICES & NAVIGATION ───
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 12),
              child: Text(
                'SERVICES & BOOKINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItemTile(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF3E8FF),
                    title: 'My Bookings',
                    subtitle: 'View active & completed orders',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BookingsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 76, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildMenuItemTile(
                    context: context,
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                    title: 'Saved Addresses',
                    subtitle: 'Manage delivery & service locations',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 76, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildMenuItemTile(
                    context: context,
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFD1FAE5),
                    title: 'Notifications',
                    subtitle: 'Booking updates & promo offers',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── SECTION 2: ACCOUNT & SETTINGS ───
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 12),
              child: Text(
                'ACCOUNT & SETTINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItemTile(
                    context: context,
                    icon: Icons.headset_mic_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFE0F2FE),
                    title: 'Help & Support',
                    subtitle: '24/7 Customer assistance & FAQs',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpCentreScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 76, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildMenuItemTile(
                    context: context,
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF475569),
                    iconBg: const Color(0xFFF1F5F9),
                    title: 'Settings',
                    subtitle: 'App Language: ${lang.isTamil ? "தமிழ்" : "English"}',
                    onTap: () => _showLanguageDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── SECTION 3: LOGOUT BUTTON ───
            if (auth.isLoggedIn)
              InkWell(
                onTap: () => _logout(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFE11D48),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE11D48),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(15),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}