import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../screens/payment_screen.dart';
import '../screens/rating_screen.dart';
import '../screens/invoice_screen.dart';
import '../screens/worker_tracking_map_screen.dart';
import '../providers/language_provider.dart';

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
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: Size.zero),
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
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
    final discountText = service.price > 500 ? '₹100 OFF' : '20% OFF';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
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
                    // Top-Left Discount Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary, // Matte Black
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discountText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                    // Bottom-Left Rating Badge (Zomato-style green)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E5226), // Zomato green
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              service.avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 10),
                          ],
                        ),
                      ),
                    ),
                    // Verified badge at bottom-right of image
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                          ],
                        ),
                        child: const Text(
                          'Inspection Based',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: AppTheme.primary,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Category & Delivery Time Row
                  Row(
                    children: [
                      if (service.categoryName != null) ...[
                        Text(
                          service.categoryName!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(Icons.flash_on, color: AppTheme.secondary, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${service.estimatedTime} mins',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
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
      color: AppTheme.primary.withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.home_repair_service, size: 36, color: AppTheme.primary),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.onTap, this.onCancel, this.onRebook});

  final BookingItem booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRebook;

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

    final timelineChildren = <Widget>[];
    for (int i = 0; i < steps.length * 2 - 1; i++) {
      if (i.isOdd) {
        final stepBefore = (i - 1) ~/ 2;
        final filled = !isCancelled && stepBefore < currentStep;
        timelineChildren.add(
          Expanded(
            child: Container(
              height: 2,
              color: filled ? AppTheme.secondary : Colors.grey.shade300,
            ),
          ),
        );
      } else {
        final step = i ~/ 2;
        final filled = !isCancelled && step <= currentStep;
        timelineChildren.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppTheme.secondary : Colors.grey.shade300,
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
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: timelineChildren,
        ),
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
                      _getFormattedStatus(booking.status),
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
                      booking.workerName ?? '',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateFmt.format(booking.scheduledAt ?? booking.createdAt),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (booking.status == 'completed' && booking.amount > 0)
                        ? '₹${booking.amount.toStringAsFixed(0)}'
                        : 'Price after inspection',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (booking.status == 'completed' && booking.amount > 0) ? AppTheme.primary : AppTheme.secondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              // OTP Start/Completion Verification Card (Rapido/Uber style)
              if ((booking.status == 'pending' || booking.status == 'confirmed' || booking.status == 'in_progress') && booking.otp != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: booking.status == 'in_progress'
                        ? Colors.purple.shade50
                        : AppTheme.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: booking.status == 'in_progress'
                          ? Colors.purple.shade200
                          : AppTheme.secondary.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: booking.status == 'in_progress' ? Colors.purple : AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.key, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.status == 'in_progress' ? 'JOB COMPLETION OTP' : 'JOB START OTP',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                color: booking.status == 'in_progress' ? Colors.purple.shade900 : AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.status == 'in_progress'
                                  ? 'Share with worker when work finishes'
                                  : 'Share with worker when they arrive',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: booking.status == 'in_progress' ? Colors.purple : AppTheme.secondary,
                          ),
                        ),
                        child: Text(
                          booking.otp ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: booking.status == 'in_progress' ? Colors.purple.shade900 : AppTheme.primary,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Progress timeline
              _buildTimeline(),
              // Action buttons
              if (booking.canCancel && onCancel != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ],
              if (booking.status == 'confirmed' || booking.status == 'in_progress') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkerTrackingMapScreen(bookingId: booking.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 14),
                      label: const Text('Track Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
              if (booking.status == 'completed') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.amount > 0) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PaymentScreen(booking: booking)),
                          );
                        },
                        icon: const Icon(Icons.payment, size: 14),
                        label: Text('Pay Now (₹${booking.amount.toStringAsFixed(0)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (onRebook != null) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: onRebook,
                        child: Text(context.translate('rebook'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InvoiceScreen(booking: booking)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Invoice', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
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

String _getFormattedStatus(String status) {
  switch (status) {
    case 'pending':
      return 'SEARCHING FOR WORKER';
    case 'assigned':
      return 'WORKER ASSIGNED';
    case 'confirmed':
      return 'WORKER ACCEPTED';
    case 'on_the_way':
      return 'WORKER ON THE WAY';
    case 'reached':
      return 'WORKER REACHED';
    case 'otp_pending':
      return 'OTP VERIFICATION PENDING';
    case 'in_progress':
      return 'WORK STARTED';
    case 'invoice_ready':
      return 'INVOICE READY';
    case 'payment_pending':
      return 'PAYMENT PENDING';
    case 'completed':
      return 'BOOKING COMPLETED';
    case 'cancelled':
      return 'CANCELLED';
    default:
      return status.replaceAll('_', ' ').toUpperCase();
  }
}
