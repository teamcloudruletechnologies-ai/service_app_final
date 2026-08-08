import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../providers/language_provider.dart';
import 'raise_ticket_screen.dart';
import 'my_tickets_screen.dart';
import 'report_professional_screen.dart';
import 'account_help_screen.dart';
import 'policies_screen.dart';
import 'bookings_screen.dart';

class HelpCentreScreen extends StatefulWidget {
  const HelpCentreScreen({super.key});

  @override
  State<HelpCentreScreen> createState() => _HelpCentreScreenState();
}

class _HelpCentreScreenState extends State<HelpCentreScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<SupportFaq> _dynamicFaqs = [];
  bool _loadingFaqs = false;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() => _loadingFaqs = true);
    try {
      final apiService = context.read<ApiService>();
      final faqs = await apiService.fetchDynamicFaqs();
      if (faqs.isNotEmpty) {
        setState(() {
          _dynamicFaqs = faqs;
        });
      }
    } catch (_) {}
    setState(() => _loadingFaqs = false);
  }

  @override
  Widget build(BuildContext context) {
    // Fallback static FAQs if backend dynamic FAQs fail or empty
    final fallbackFaqs = [
      {
        'q': 'How do I book a service on Urban Serve?',
        'a': 'Select a service category from the home screen, select your location, pick a scheduled time, and confirm your booking.',
      },
      {
        'q': 'How are professional service charges calculated?',
        'a': 'Service partners perform an initial inspection upon arrival. Final pricing depends on spare parts and labor scope agreed before work starts.',
      },
      {
        'q': 'What is the job start OTP?',
        'a': 'The start OTP is a 4-digit code shown in your booking card. Share it with your assigned professional only when they arrive at your location.',
      },
      {
        'q': 'How can I report poor service quality or rude behavior?',
        'a': 'Go to Help Centre -> Report Professional or tap Need Help on your booking card to lodge a formal safety report.',
      },
    ];

    List<Map<String, String>> displayedFaqs = [];

    if (_dynamicFaqs.isNotEmpty) {
      displayedFaqs = _dynamicFaqs.map((f) => {'q': f.question, 'a': f.answer}).toList();
    } else {
      displayedFaqs = fallbackFaqs;
    }

    final filteredFaqs = displayedFaqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      return faq['q']!.toLowerCase().contains(query) ||
          faq['a']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          context.translate('help_centre'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.3),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── SEARCH BAR ───
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  cursorColor: const Color(0xFF0F172A),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: context.translate('search_hint'),
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── SUPPORT SERVICES GRID/CARDS ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'SUPPORT SERVICES',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceOptionCard(
                          icon: Icons.confirmation_number_rounded,
                          title: 'Raise a Ticket',
                          subtitle: 'Create a new support request',
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RaiseTicketScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceOptionCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'My Support Tickets',
                          subtitle: 'View active ticket history',
                          iconBg: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceOptionCard(
                          icon: Icons.build_circle_rounded,
                          title: 'Booking Help',
                          subtitle: 'Issues with active booking',
                          iconBg: const Color(0xFFFFF7ED),
                          iconColor: const Color(0xFFD97706),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceOptionCard(
                          icon: Icons.report_problem_rounded,
                          title: 'Report Professional',
                          subtitle: 'Complain about partner behavior',
                          iconBg: const Color(0xFFFEF2F2),
                          iconColor: const Color(0xFFDC2626),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReportProfessionalScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceOptionCard(
                          icon: Icons.manage_accounts_rounded,
                          title: 'Account Help',
                          subtitle: 'Mobile, password & deletion',
                          iconBg: const Color(0xFFF3E8FF),
                          iconColor: const Color(0xFF7C3AED),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AccountHelpScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceOptionCard(
                          icon: Icons.gavel_rounded,
                          title: 'Policies & Legal',
                          subtitle: 'Privacy, terms & refunds',
                          iconBg: const Color(0xFFF1F5F9),
                          iconColor: const Color(0xFF475569),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── FAQS SECTION TITLE ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
            ),

            // ─── FAQS ACCORDION LIST ───
            if (filteredFaqs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Text(
                    'No matching FAQs found.',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: filteredFaqs.length,
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          faq['q']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedAlignment: Alignment.topLeft,
                        iconColor: const Color(0xFF0F172A),
                        collapsedIconColor: const Color(0xFF94A3B8),
                        children: [
                          Text(
                            faq['a']!,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // ─── CONTACT SUPPORT SECTION ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'DIRECT CHANNELS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                ),
              ),
            ),

            // ─── CONTACT OPTIONS GRID ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.phone_rounded,
                      title: context.translate('call_us'),
                      value: '+91 98765 43210',
                      bgColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFFDBEAFE),
                      titleColor: const Color(0xFF1E40AF),
                      valueColor: const Color(0xFF0F172A),
                      iconColor: const Color(0xFF2563EB),
                      onTap: () => _copyToClipboard(context, '+919876543210', 'Phone number copied to clipboard!'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.email_rounded,
                      title: context.translate('email_us'),
                      value: 'support@urbanserve.com',
                      bgColor: const Color(0xFFFFF7ED),
                      borderColor: const Color(0xFFFFEDD5),
                      titleColor: const Color(0xFF92400E),
                      valueColor: const Color(0xFF0F172A),
                      iconColor: const Color(0xFFD97706),
                      onTap: () => _copyToClipboard(context, 'support@urbanserve.com', 'Email copied to clipboard!'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ContactCard(
                icon: Icons.chat_bubble_rounded,
                title: context.translate('chat_whatsapp'),
                value: 'Connect instantly with support team',
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                titleColor: const Color(0xFF065F46),
                valueColor: const Color(0xFF0F172A),
                iconColor: const Color(0xFF059669),
                fullWidth: true,
                onTap: () => _copyToClipboard(context, 'https://wa.me/919876543210', 'Support link copied to clipboard!'),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ServiceOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ServiceOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color bgColor;
  final Color borderColor;
  final Color titleColor;
  final Color valueColor;
  final Color iconColor;
  final bool fullWidth;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.titleColor,
    required this.valueColor,
    required this.iconColor,
    this.fullWidth = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: valueColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
