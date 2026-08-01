import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../theme/app_theme.dart';
import 'bookings_screen.dart';
import 'help_centre_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _authProvider?.addListener(_onAuthChange);
    });
  }

  void _onAuthChange() {
    if (!mounted) return;
    if (_authProvider != null && !_authProvider!.isLoggedIn) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChange);
    super.dispose();
  }

  static const List<Widget> _pages = [
    HomeScreen(),
    BookingsScreen(),
    HelpCentreScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _index == index;
    final activeColor = AppTheme.primary;
    final inactiveColor = const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () {
        setState(() => _index = index);
        if (index == 1) {
          context.read<BookingProvider>().loadBookings();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1A1A1A) : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        height: 62 + MediaQuery.paddingOf(context).bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Bookings'),
            _buildNavItem(2, Icons.local_offer_outlined, Icons.local_offer_rounded, 'Offers'),
            _buildNavItem(3, Icons.mail_outline_rounded, Icons.mail_rounded, 'Inbox'),
            _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }
}
