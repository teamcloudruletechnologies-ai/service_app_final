import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../providers/language_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final result = await api.fetchNotifications();
      setState(() {
        _notifications = result.items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notifications';
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      final api = context.read<ApiService>();
      await api.markAllNotificationsRead();
      setState(() {
        for (var n in _notifications) {
          n.read = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.read) return;
    setState(() => item.read = true);
    try {
      final api = context.read<ApiService>();
      await api.markNotificationRead(item.id);
    } catch (_) {
      // Revert on failure silently
      setState(() => item.read = false);
    }
  }

  Future<void> _deleteNotification(NotificationItem item, int index) async {
    // Optimistic delete
    setState(() {
      _notifications.removeAt(index);
    });
    try {
      final api = context.read<ApiService>();
      await api.deleteNotification(item.id);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _notifications.insert(index, item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm a');
    final dateFmt = DateFormat('dd MMM');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.translate('notifications')),
        actions: [
          if (_notifications.any((n) => !n.read))
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              onPressed: _markAllRead,
              tooltip: 'Mark all as read',
            )
        ],
      ),
      body: _buildBody(timeFmt, dateFmt),
    );
  }

  Widget _buildBody(DateFormat timeFmt, DateFormat dateFmt) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            TextButton(
              onPressed: _fetchNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No notifications yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final isRead = item.read;
        final time = item.createdAt;
        final isToday = DateTime.now().difference(time).inDays == 0;

        return Dismissible(
          key: Key('notif_${item.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _deleteNotification(item, index);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: InkWell(
            onTap: () => _markRead(item),
            child: Container(
              color: isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.04),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getIconBgColor(item.type ?? ''),
                    child: Icon(_getIcon(item.type ?? ''), color: _getIconColor(item.type ?? ''), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isToday ? timeFmt.format(time) : dateFmt.format(time),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(String type) {
    if (type.contains('booking')) return Icons.event_available;
    if (type.contains('payment')) return Icons.account_balance_wallet_outlined;
    if (type.contains('service')) return Icons.check_circle_outline;
    if (type.contains('promo')) return Icons.local_offer_outlined;
    return Icons.notifications;
  }

  Color _getIconBgColor(String type) {
    if (type.contains('booking')) return Colors.blue.shade50;
    if (type.contains('payment')) return Colors.green.shade50;
    if (type.contains('service')) return Colors.teal.shade50;
    if (type.contains('promo')) return Colors.orange.shade50;
    return Colors.grey.shade100;
  }

  Color _getIconColor(String type) {
    if (type.contains('booking')) return Colors.blue;
    if (type.contains('payment')) return Colors.green;
    if (type.contains('service')) return Colors.teal;
    if (type.contains('promo')) return Colors.orange;
    return Colors.grey;
  }
}
