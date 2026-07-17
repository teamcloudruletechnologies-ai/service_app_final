import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'bookings_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'menu_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
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
    MenuScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Bookings'),
    NavigationDestination(icon: Icon(Icons.menu_outlined), selectedIcon: Icon(Icons.menu), label: 'Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F3),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: const Color(0xFFF5F5F3),
          indicatorColor: const Color(0xFFE3D0BA),
          elevation: 0,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
        ),
      ),
    );
  }
}
