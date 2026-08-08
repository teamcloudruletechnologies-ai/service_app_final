import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  String? _error;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final pagedResult = await api.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = pagedResult.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    final deletedItem = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });

    try {
      final api = context.read<ApiService>();
      await api.deleteNotification(id);
    } catch (e) {
      // Revert if API fails
      if (mounted) {
        setState(() {
          _notifications.insert(index, deletedItem);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _buildBody(timeFmt, dateFmt),
    );
  }

  Widget _buildBody(DateFormat timeFmt, DateFormat dateFmt) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchNotifications,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
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

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final isToday = DateTime.now().difference(item.createdAt).inDays == 0;

          return Dismissible(
            key: Key('notification_${item.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) {
              _deleteNotification(item.id, index);
            },
            child: Container(
              color: item.isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.04),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getIconBgColor(item.title),
                    child: Icon(_getIcon(item.title), color: _getIconColor(item.title), size: 20),
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
                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isToday ? timeFmt.format(item.createdAt) : dateFmt.format(item.createdAt),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('booking') || lower.contains('job')) return Icons.event_note_outlined;
    if (lower.contains('payout') || lower.contains('earning')) return Icons.monetization_on_outlined;
    if (lower.contains('kyc') || lower.contains('verified')) return Icons.verified_user_outlined;
    if (lower.contains('tip')) return Icons.lightbulb_outline;
    return Icons.notifications;
  }

  Color _getIconBgColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('booking') || lower.contains('job')) return Colors.blue.shade50;
    if (lower.contains('payout') || lower.contains('earning')) return Colors.green.shade50;
    if (lower.contains('kyc') || lower.contains('verified')) return Colors.teal.shade50;
    if (lower.contains('tip')) return Colors.amber.shade50;
    return Colors.grey.shade100;
  }

  Color _getIconColor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('booking') || lower.contains('job')) return Colors.blue;
    if (lower.contains('payout') || lower.contains('earning')) return Colors.green;
    if (lower.contains('kyc') || lower.contains('verified')) return Colors.teal;
    if (lower.contains('tip')) return Colors.amber;
    return Colors.grey;
  }
}
