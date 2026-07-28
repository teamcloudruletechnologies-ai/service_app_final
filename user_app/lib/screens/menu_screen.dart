import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'help_centre_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.translate('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(context.translate('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.translate('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
          title: Text(context.translate('select_language'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                trailing: !lang.isTamil ? const Icon(Icons.check, color: AppTheme.secondary) : null,
                onTap: () {
                  lang.setLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('தமிழ்'),
                trailing: lang.isTamil ? const Icon(Icons.check, color: AppTheme.secondary) : null,
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Urban Service',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'U',
          style: TextStyle(
            color: AppTheme.accent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      children: const [
        Text('Urban Service is your premium destination for trusted local professionals.'),
        SizedBox(height: 8),
        Text('Developed with love.'),
      ],
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final initial = (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Hero(
        tag: 'profile_avatar_hero',
        child: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE3D0BA),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A1A1A),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        title: Text(context.translate('menu')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildProfileButton(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.accent,
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? context.translate('guest_user'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? context.translate('sign_in_access'),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Options
          _buildMenuSection(
            title: context.translate('account_settings'),
            children: [
              _buildMenuTile(
                icon: Icons.person_outline,
                title: context.translate('edit_profile'),
                subtitle: context.translate('manage_details'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildMenuSection(
            title: context.translate('language'),
            children: [
              _buildMenuTile(
                icon: Icons.language_outlined,
                title: context.translate('select_language'),
                subtitle: lang.isTamil ? 'தமிழ்' : 'English',
                onTap: () => _showLanguageDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildMenuSection(
            title: context.translate('general'),
            children: [
              _buildMenuTile(
                icon: Icons.info_outline,
                title: context.translate('about_app'),
                subtitle: context.translate('version_info'),
                onTap: () => _showAboutDialog(context),
              ),
              _buildMenuTile(
                icon: Icons.help_outline,
                title: context.translate('help_support'),
                subtitle: context.translate('contact_us'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpCentreScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Login / Logout Button
          auth.isLoggedIn
              ? OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(context.translate('logout'), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(context.translate('login_register'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE3D0BA), width: 1.0),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE3D0BA).withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppTheme.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}