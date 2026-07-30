import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': '1',
      'title': 'Booking Confirmed 🎉',
      'message': 'Your plumber booking has been successfully confirmed. Professional Sailesh is on the way.',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'read': false,
      'type': 'booking',
    },
    {
      'id': '2',
      'title': 'Payment Successful 💳',
      'message': 'Payment of ₹499 for Service #12 was received successfully. Invoice is ready to view.',
      'time': DateTime.now().subtract(const Duration(hours: 1)),
      'read': false,
      'type': 'payment',
    },
    {
      'id': '3',
      'title': 'Service Completed ✨',
      'message': 'Your cleaning service has been marked complete. Please rate your experience with professional Harish.',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
      'type': 'service',
    },
    {
      'id': '4',
      'title': 'Welcome to Urban Service! 🏡',
      'message': 'Get 20% off on your first home cleaning booking using code: CLEAN20.',
      'time': DateTime.now().subtract(const Duration(days: 3)),
      'read': true,
      'type': 'promo',
    }
  ];

  void _markAllRead() {
    setState(() {
      for (var n in _mockNotifications) {
        n['read'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm a');
    final dateFmt = DateFormat('dd MMM');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_chat_read_outlined),
            onPressed: _markAllRead,
            tooltip: 'Mark all as read',
          )
        ],
      ),
      body: _mockNotifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _mockNotifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final item = _mockNotifications[index];
                final isRead = item['read'] as bool;
                final time = item['time'] as DateTime;
                final isToday = DateTime.now().difference(time).inDays == 0;

                return Container(
                  color: isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.04),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getIconBgColor(item['type'] as String),
                        child: Icon(_getIcon(item['type'] as String), color: _getIconColor(item['type'] as String), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  isToday ? timeFmt.format(time) : dateFmt.format(time),
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['message'] as String,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_available;
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'service':
        return Icons.check_circle_outline;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue.shade50;
      case 'payment':
        return Colors.green.shade50;
      case 'service':
        return Colors.teal.shade50;
      case 'promo':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'service':
        return Colors.teal;
      case 'promo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
