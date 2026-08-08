import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'my_tickets_screen.dart';

class RaiseTicketScreen extends StatefulWidget {
  final int? prefilledBookingId;
  const RaiseTicketScreen({super.key, this.prefilledBookingId});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedCategory = 'General Inquiry';
  String _selectedPriority = 'Medium';
  int? _selectedBookingId;
  List<BookingItem> _userBookings = [];
  bool _loadingBookings = false;
  bool _submitting = false;
  XFile? _selectedImage;
  SupportTicket? _createdTicket;

  final List<String> _categories = [
    'General Inquiry',
    'Booking & Scheduling',
    'Payment & Refunds',
    'Service Quality',
    'Professional Behavior',
    'Account & Profile'
  ];

  @override
  void initState() {
    super.initState();
    _selectedBookingId = widget.prefilledBookingId;
    _fetchBookings();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() => _loadingBookings = true);
    try {
      final apiService = context.read<ApiService>();
      final res = await apiService.fetchBookings();
      setState(() {
        _userBookings = res.items;
      });
    } catch (_) {}
    setState(() => _loadingBookings = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      setState(() {
        _selectedImage = img;
      });
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final apiService = context.read<ApiService>();
      final ticket = await apiService.createSupportTicket(
        subject: _subjectCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        bookingId: _selectedBookingId,
        categoryName: _selectedCategory,
        priority: _selectedPriority,
      );

      setState(() {
        _createdTicket = ticket;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit ticket: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdTicket != null) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Raise Support Ticket',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Dropdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ISSUE CATEGORY',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Booking Picker (Optional)
              if (_userBookings.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RELATED BOOKING (OPTIONAL)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        value: _selectedBookingId,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        hint: const Text('None (General Ticket)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None (General Ticket)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B))),
                          ),
                          ..._userBookings.map((b) {
                            return DropdownMenuItem<int?>(
                              value: b.id,
                              child: Text(
                                '#${b.id} - ${b.serviceName ?? "Booking"} (₹${b.amount.toStringAsFixed(0)})',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedBookingId = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Subject Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUBJECT',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _subjectCtrl,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Service delayed by technician',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a subject' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'Please describe the issue in detail...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Attachment screenshot
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0F172A), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedImage != null ? 'Screenshot Attached' : 'Attach Screenshot (Optional)',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedImage != null ? _selectedImage!.name : 'Upload photos of the service issue',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedImage != null)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22)
                      else
                        const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF94A3B8), size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Ticket',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ticket Submitted Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our customer support team is investigating your issue and will reply within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text(
                    'TICKET REFERENCE NUMBER',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _createdTicket?.ticketNumber ?? 'SUP-XXXXXX',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0F172A), letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Category: ${_createdTicket?.categoryName ?? _selectedCategory}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('View My Tickets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Help Centre', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }
}
