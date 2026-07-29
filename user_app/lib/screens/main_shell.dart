import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'bookings_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
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
    ProfileScreen(),
    MenuScreen(),
  ];

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _index == index;
    final activeColor = const Color(0xFFE23744); // Zomato Red
    final inactiveColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: () {
        setState(() => _index = index);
        if (index == 1) {
          context.read<BookingProvider>().loadBookings();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
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
      backgroundColor: const Color(0xFFF5F5F3),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        height: 60 + MediaQuery.paddingOf(context).bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Bookings'),
            _buildNavItem(2, Icons.person_outline, Icons.person, 'Profile'),
            _buildNavItem(3, Icons.menu_outlined, Icons.menu, 'Menu'),
          ],
        ),
      ),
    );
  }
}
