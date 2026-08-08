import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ReportProfessionalScreen extends StatefulWidget {
  final BookingItem? booking;
  const ReportProfessionalScreen({super.key, this.booking});

  @override
  State<ReportProfessionalScreen> createState() => _ReportProfessionalScreenState();
}

class _ReportProfessionalScreenState extends State<ReportProfessionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  String _selectedReason = 'Rude behavior';
  bool _submitting = false;
  XFile? _selectedImage;
  Map<String, dynamic>? _submittedReport;

  final List<String> _reasons = [
    'Rude behavior',
    'Poor quality work',
    'Overcharged / Unofficial payment request',
    'Unprofessional conduct',
    'Late arrival without notice',
    'Damage to property',
    'Safety / Security concern',
    'Other'
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final apiService = context.read<ApiService>();
      final res = await apiService.reportProfessional(
        reason: _selectedReason,
        description: _descCtrl.text.trim(),
        bookingId: widget.booking?.id,
      );

      setState(() {
        _submittedReport = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedReport != null) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Report Professional',
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
              // Notice banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We take worker misconduct seriously. All reports trigger an immediate internal audit.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF991B1B), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Booking Card info if attached
              if (widget.booking != null) ...[
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
                        'REPORTING FOR BOOKING',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${widget.booking!.id} - ${widget.booking!.serviceName ?? "Service"}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      if (widget.booking!.workerName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Partner: ${widget.booking!.workerName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reason dropdown
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
                      'COMPLAINT REASON',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedReason,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                      items: _reasons.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Text Area
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
                      'DETAILS & EVIDENCE',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF0F172A)),
                      decoration: const InputDecoration(
                        hintText: 'Describe what happened during the service visit...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter complaint details' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Photo proof
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0F172A), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedImage != null ? 'Photo Evidence Attached' : 'Attach Photo Evidence (Optional)',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedImage != null ? _selectedImage!.name : 'Upload photos of property damage or bill',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedImage != null)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _submitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
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
                        'Lodge Complaint',
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
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Complaint Registered',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thank you for reporting. Our safety officers are investigating this issue and will contact you directly.',
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
                    'COMPLAINT NUMBER',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _submittedReport?['report_number'] ?? 'PR-XXXXXX',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0F172A), letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
