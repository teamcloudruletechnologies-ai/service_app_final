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
      'title': 'New Job Request 🛠️',
      'message': 'You have received a new booking request for Service #104. Tap to review details.',
      'time': DateTime.now().subtract(const Duration(minutes: 2)),
      'read': false,
      'type': 'booking',
    },
    {
      'id': '2',
      'title': 'Payout Processed 💰',
      'message': 'Your weekly payout of ₹4,250 has been successfully credited to your bank account.',
      'time': DateTime.now().subtract(const Duration(hours: 3)),
      'read': false,
      'type': 'payout',
    },
    {
      'id': '3',
      'title': 'KYC Verified ✅',
      'message': 'Your documents verification is completed. You are now authorized to accept premium bookings.',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
      'type': 'kyc',
    },
    {
      'id': '4',
      'title': 'Tips for High Ratings 🌟',
      'message': 'Keep your response time under 15 minutes to increase customer satisfaction by 40%.',
      'time': DateTime.now().subtract(const Duration(days: 5)),
      'read': true,
      'type': 'tip',
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
        return Icons.event_note_outlined;
      case 'payout':
        return Icons.monetization_on_outlined;
      case 'kyc':
        return Icons.verified_user_outlined;
      case 'tip':
        return Icons.lightbulb_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue.shade50;
      case 'payout':
        return Colors.green.shade50;
      case 'kyc':
        return Colors.teal.shade50;
      case 'tip':
        return Colors.amber.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payout':
        return Colors.green;
      case 'kyc':
        return Colors.teal;
      case 'tip':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
