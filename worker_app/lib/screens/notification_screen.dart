import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedTab = 'All';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New job request received',
      'subtitle': 'Plumbing Service',
      'timeAgo': 'Just now',
      'read': false,
      'type': 'request',
    },
    {
      'id': '2',
      'title': 'Your booking has been confirmed',
      'subtitle': 'AC Service',
      'timeAgo': '10 min ago',
      'read': false,
      'type': 'confirmed',
    },
    {
      'id': '3',
      'title': 'Payment of ₹299 received',
      'subtitle': 'Plumbing Service',
      'timeAgo': '1 hour ago',
      'read': false,
      'type': 'payment',
    },
    {
      'id': '4',
      'title': 'Customer has rated you',
      'subtitle': '5.0 rating received',
      'timeAgo': '3 hours ago',
      'read': true,
      'type': 'rating',
    },
    {
      'id': '5',
      'title': 'Weekly payout of ₹2,350 successful',
      'subtitle': 'Direct bank deposit',
      'timeAgo': '1 day ago',
      'read': true,
      'type': 'payout',
    },
  ];

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_selectedTab == 'Unread') {
      return _notifications.where((n) => n['read'] == false).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
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
      body: Column(
        children: [
          // ─── 1. TOP CATEGORY TABS (All / Unread) WITH YELLOW UNDERLINE INDICATOR ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem('All'),
                _buildTabItem('Unread'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── 2. NOTIFICATIONS LIST ───
          Expanded(
            child: _filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No $_selectedTab notifications',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filteredList.length,
                    itemBuilder: (context, index) {
                      final item = _filteredList[index];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),

          // ─── 3. MARK ALL AS READ BOTTOM BUTTON ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TextButton(
                  onPressed: _markAllRead,
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB BUTTON COMPONENT ───
  Widget _buildTabItem(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFFACC15) : Colors.transparent, // Yellow Underline Indicator
              width: 3.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ─── NOTIFICATION CARD ITEM COMPONENT (Matching Screenshot 8) ───
  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final isRead = item['read'] as bool;

    Color iconBg;
    Color iconColor;
    IconData icon;

    switch (type) {
      case 'request':
        iconBg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF0F172A);
        icon = Icons.home_repair_service_rounded;
        break;
      case 'confirmed':
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF15803D);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'payment':
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF15803D);
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'rating':
        iconBg = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        icon = Icons.star_rounded;
        break;
      case 'payout':
        iconBg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF0F172A);
        icon = Icons.payments_rounded;
        break;
      default:
        iconBg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF0F172A);
        icon = Icons.notifications_rounded;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          item['read'] = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['subtitle'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item['timeAgo'] as String,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
