import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, required this.service, this.initialAddress, this.initialNotes, this.selectedWorker});

  final ServiceItem service;
  final String? initialAddress;
  final String? initialNotes;
  final NearbyWorker? selectedWorker;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (widget.initialAddress != null && widget.initialAddress!.trim().isNotEmpty) {
      _addressCtrl.text = widget.initialAddress!;
    } else if (user?.address != null && user!.address!.trim().isNotEmpty) {
      _addressCtrl.text = user.address!;
    } else {
      _addressCtrl.text = 'Anna Nagar, Madurai, Tamil Nadu 625020';
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final finalNotes = 'Contact: $phone${notes.isNotEmpty ? '\nNotes: $notes' : ''}';

    final booking = await context.read<BookingProvider>().createBooking(
          serviceId: widget.service.id,
          address: _addressCtrl.text.trim(),
          notes: finalNotes,
          scheduledAt: _scheduledAt,
          workerId: widget.selectedWorker?.id,
        );

    if (!mounted) return;
    if (booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Booking submitted successfully!'),
          backgroundColor: AppTheme.primary,
        ),
      );
      // Navigate to Bookings Status Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainShell(initialTab: 1),
        ),
      );
    } else {
      final error = context.read<BookingProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Booking failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(context.translate('book_service'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.translate(widget.service.name), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.service.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.selectedWorker != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.grey.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (widget.selectedWorker!.photoUrl != null && widget.selectedWorker!.photoUrl!.isNotEmpty)
                          ? NetworkImage(widget.selectedWorker!.photoUrl!)
                          : null,
                      child: (widget.selectedWorker!.photoUrl == null || widget.selectedWorker!.photoUrl!.isEmpty)
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(widget.selectedWorker!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${context.translate("selected_pro")} (${widget.selectedWorker!.serviceType ?? "Service"})'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          widget.selectedWorker!.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.translate('service_address'),
                  hintText: context.translate('address_hint'),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? context.translate('address_required') : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.translate('preferred_date_time'),
                    prefixIcon: const Icon(Icons.schedule),
                  ),
                  child: Text(
                    _scheduledAt != null ? dateFmt.format(_scheduledAt!) : context.translate('tap_to_select'),
                    style: TextStyle(color: _scheduledAt != null ? Colors.black87 : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.translate('notes_optional'),
                  hintText: context.translate('notes_hint'),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter your contact number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Contact number is required';
                  }
                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                  if (cleaned.length < 10) {
                    return 'Enter a valid contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: booking.loading ? null : _submit,
                child: booking.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E293B)),
                      )
                    : Text(context.translate('confirm_booking')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
