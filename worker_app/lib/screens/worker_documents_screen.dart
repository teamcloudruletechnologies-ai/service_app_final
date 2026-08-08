import 'package:flutter/material.dart';

import 'worker_kyc_screen.dart';

class WorkerDocumentsScreen extends StatelessWidget {
  const WorkerDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = [
      {
        'title': 'Aadhaar Card',
        'status': 'Verified',
        'statusColor': const Color(0xFF15803D),
        'bgColor': const Color(0xFFDCFCE7),
        'icon': Icons.badge_outlined,
      },
      {
        'title': 'PAN Card',
        'status': 'Verified',
        'statusColor': const Color(0xFF15803D),
        'bgColor': const Color(0xFFDCFCE7),
        'icon': Icons.credit_card_outlined,
      },
      {
        'title': 'Driving License',
        'status': 'Verified',
        'statusColor': const Color(0xFF15803D),
        'bgColor': const Color(0xFFDCFCE7),
        'icon': Icons.drive_eta_outlined,
      },
      {
        'title': 'Profile Photo',
        'status': 'Verified',
        'statusColor': const Color(0xFF15803D),
        'bgColor': const Color(0xFFDCFCE7),
        'icon': Icons.portrait_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Documents',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ─── 1. UPLOADED DOCUMENTS SECTION ───
            const Text(
              'Uploaded Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: documents.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final doc = entry.value;
                  final isLast = idx == documents.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WorkerKycScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(doc['icon'] as IconData, size: 20, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  doc['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: doc['bgColor'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  doc['status'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: doc['statusColor'] as Color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(height: 1, indent: 60, endIndent: 20, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // ─── 2. BOTTOM BLACK ACTION BUTTON ───
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkerKycScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // Black Primary Theme Button
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Upload Document',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
