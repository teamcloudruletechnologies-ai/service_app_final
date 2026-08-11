import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerHelpSupportScreen extends StatelessWidget {
  const WorkerHelpSupportScreen({super.key});

  void _showHelpModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
            // ─── 1. TOP HERO ASSIST CARD (Matching Diagram) ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Soft Blue Hero Box
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headset_mic_rounded, size: 26, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'How can we help you?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'We are here to assist you.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── 2. OPTIONS MENU LIST CONTAINER (Matching Diagram) ───
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Option 1: FAQs
                  _buildOptionItem(
                    icon: Icons.quiz_outlined,
                    title: 'FAQs',
                    subtitle: 'Find answers to common questions',
                    onTap: () => _showHelpModal(
                      context,
                      'Frequently Asked Questions',
                      '1. How do I get paid?\nPayouts are deposited directly to your bank account weekly.\n\n2. How to accept orders?\nTurn on Online status on your dashboard to receive job alerts.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),

                  // Option 2: Contact Support
                  _buildOptionItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Contact Support',
                    subtitle: 'Chat or call with our support team',
                    onTap: () => _showHelpModal(
                      context,
                      'Contact Support',
                      'Call Us: +91 98765 43210\nEmail: support@urbanserve.com\nWhatsApp: +91 98765 43210',
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),

                  // Option 3: Raise a Ticket
                  _buildOptionItem(
                    icon: Icons.note_add_outlined,
                    title: 'Raise a Ticket',
                    subtitle: 'Report an issue or problem',
                    onTap: () => _showHelpModal(
                      context,
                      'Raise Support Ticket',
                      'Please contact admin via phone or email to file an urgent grievance or ticket.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20, color: Color(0xFFF1F5F9)),

                  // Option 4: My Tickets
                  _buildOptionItem(
                    icon: Icons.assignment_outlined,
                    title: 'My Tickets',
                    subtitle: 'View your previous tickets',
                    onTap: () => _showHelpModal(
                      context,
                      'My Tickets History',
                      'No active support tickets pending. Your account is in good standing!',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── 3. BOTTOM SUPPORT HOURS CARD (Matching Diagram) ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF2563EB)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Support Hours',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '9:00 AM - 9:00 PM (Mon - Sun)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF0F172A)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
