import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class WorkerKycScreen extends StatefulWidget {
  const WorkerKycScreen({super.key});

  @override
  State<WorkerKycScreen> createState() => _WorkerKycScreenState();
}

class _WorkerKycScreenState extends State<WorkerKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarNumCtrl = TextEditingController();
  final _panNumCtrl = TextEditingController();
  final _bankAccCtrl = TextEditingController();

  String? _aadhaarUrl;
  String? _panUrl;
  String? _bankPassbookUrl;
  String? _selfieUrl;

  bool _uploadingAadhaar = false;
  bool _uploadingPan = false;
  bool _uploadingPassbook = false;
  bool _uploadingSelfie = false;
  bool _submitting = false;

  @override
  void dispose() {
    _aadhaarNumCtrl.dispose();
    _panNumCtrl.dispose();
    _bankAccCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulateUpload(String docType) async {
    setState(() {
      if (docType == 'aadhaar') _uploadingAadhaar = true;
      if (docType == 'pan') _uploadingPan = true;
      if (docType == 'passbook') _uploadingPassbook = true;
      if (docType == 'selfie') _uploadingSelfie = true;
    });

    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      final mockUrl = '/uploads/kyc/mock_${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (docType == 'aadhaar') {
        _uploadingAadhaar = false;
        _aadhaarUrl = mockUrl;
      }
      if (docType == 'pan') {
        _uploadingPan = false;
        _panUrl = mockUrl;
      }
      if (docType == 'passbook') {
        _uploadingPassbook = false;
        _bankPassbookUrl = mockUrl;
      }
      if (docType == 'selfie') {
        _uploadingSelfie = false;
        _selfieUrl = mockUrl;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${docType.toUpperCase()} document uploaded successfully (simulated)')),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_aadhaarUrl == null || _panUrl == null || _bankPassbookUrl == null || _selfieUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents/selfie')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final api = context.read<ApiService>();
      await api.submitKyc(
        aadhaarNumber: _aadhaarNumCtrl.text.trim(),
        aadhaarUrl: _aadhaarUrl!,
        panNumber: _panNumCtrl.text.trim().toUpperCase(),
        panUrl: _panUrl!,
        bankAccountNumber: _bankAccCtrl.text.trim(),
        bankPassbookUrl: _bankPassbookUrl!,
        selfieUrl: _selfieUrl!,
      );

      // Reload auth profile to update KYC status locally
      await context.read<AuthProvider>().reloadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC documents submitted successfully. Status is now pending review.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KYC Submission Failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('KYC Onboarding Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Verify Identity',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please provide your legal numbers and photos to get verified and start receiving jobs.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Aadhaar Section
                const Text('1. Aadhaar Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _aadhaarNumCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'Aadhaar Number (12 digits)',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 12 || int.tryParse(v) == null) {
                      return 'Enter valid 12-digit Aadhaar number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _UploadButton(
                  label: 'Aadhaar Front & Back Photo',
                  hasFile: _aadhaarUrl != null,
                  loading: _uploadingAadhaar,
                  onTap: () => _simulateUpload('aadhaar'),
                ),
                const SizedBox(height: 24),

                // PAN Card Section
                const Text('2. PAN Card Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _panNumCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 10,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'PAN Card Number',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 10) {
                      return 'Enter valid 10-character PAN number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _UploadButton(
                  label: 'PAN Card Front Photo',
                  hasFile: _panUrl != null,
                  loading: _uploadingPan,
                  onTap: () => _simulateUpload('pan'),
                ),
                const SizedBox(height: 24),

                // Bank Account Section
                const Text('3. Payout Bank Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bankAccCtrl,
                  keyboardType: TextInputType.number,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account Number',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Bank Account Number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _UploadButton(
                  label: 'Bank Passbook / Cancelled Cheque Photo',
                  hasFile: _bankPassbookUrl != null,
                  loading: _uploadingPassbook,
                  onTap: () => _simulateUpload('passbook'),
                ),
                const SizedBox(height: 24),

                // Selfie Section
                const Text('4. Profile Selfie Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _UploadButton(
                  label: 'Take Selfie Live Photo',
                  hasFile: _selfieUrl != null,
                  loading: _uploadingSelfie,
                  onTap: () => _simulateUpload('selfie'),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Verification'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.label,
    required this.hasFile,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool hasFile;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFF3F4F6) : Colors.white,
          border: Border.all(
            color: hasFile ? Colors.black : Colors.grey.shade300,
            width: hasFile ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
              color: hasFile ? Colors.black : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: hasFile ? Colors.black : Colors.grey.shade600,
                  fontWeight: hasFile ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            else if (hasFile)
              const Text(
                'Uploaded',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}
