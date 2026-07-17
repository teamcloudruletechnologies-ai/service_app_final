import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../screens/payment_screen.dart';
import '../screens/rating_screen.dart';
import '../screens/invoice_screen.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, this.onTap});

  final ServiceItem service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveImageUrl(service.imageUrl);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image at top
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                    // Price badge at bottom-right of image
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          '₹${service.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info below image
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  if (service.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.categoryName!,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (service.categoryName != null) const SizedBox(height: 4),
                  // Service name
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating row
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                      const SizedBox(width: 2),
                      Text(
                        service.avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      if (service.totalReviews > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          '(${service.totalReviews})',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Estimated time badge
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        '⏱ ${service.estimatedTime} min',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.home_repair_service, size: 36, color: AppTheme.primary),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.onTap, this.onCancel});

  final BookingItem booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.purple;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  int _statusStep(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  Widget _buildTimeline() {
    final currentStep = _statusStep(booking.status);
    final steps = ['Booked', 'Confirmed', 'In Progress', 'Completed'];
    final isCancelled = booking.status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = (index - 1) ~/ 2;
            final filled = !isCancelled && stepBefore < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: filled ? const Color(0xFFE23744) : Colors.grey.shade300,
              ),
            );
          }
          final step = index ~/ 2;
          final filled = !isCancelled && step <= currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? const Color(0xFFE23744) : Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[step],
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: filled ? FontWeight.bold : FontWeight.w500,
                  color: filled ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName ?? 'Service #${booking.serviceId}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(booking.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(booking.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (booking.workerName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      booking.workerName!,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        dateFmt.format(booking.scheduledAt ?? booking.createdAt),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '₹${booking.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE23744),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // Progress timeline
              _buildTimeline(),
              // Action buttons
              if (booking.canCancel && onCancel != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.status == 'pending') ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE23744),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
                          );
                        },
                        child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ],
              if (booking.status == 'completed') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InvoiceScreen(booking: booking)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE23744)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Invoice', style: TextStyle(color: Color(0xFFE23744), fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RatingScreen(booking: booking)),
                        );
                      },
                      child: const Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
