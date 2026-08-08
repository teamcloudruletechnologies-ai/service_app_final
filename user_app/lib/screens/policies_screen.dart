import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class PoliciesScreen extends StatefulWidget {
  final String initialSlug;
  const PoliciesScreen({super.key, this.initialSlug = 'privacy'});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<SupportPolicy> _policies = [];

  final List<Map<String, String>> _tabItems = [
    {'slug': 'privacy', 'title': 'Privacy Policy'},
    {'slug': 'terms', 'title': 'Terms of Service'},
    {'slug': 'cancellation', 'title': 'Cancellation'},
    {'slug': 'refund', 'title': 'Refund Policy'},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = _tabItems.indexWhere((t) => t['slug'] == widget.initialSlug);
    if (initialIndex < 0) initialIndex = 0;
    _tabController = TabController(length: _tabItems.length, vsync: this, initialIndex: initialIndex);
    _fetchPolicies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPolicies() async {
    setState(() => _loading = true);
    try {
      final apiService = context.read<ApiService>();
      final res = await apiService.fetchDynamicPolicies();
      setState(() {
        _policies = res;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  SupportPolicy? _getPolicyForSlug(String slug) {
    try {
      return _policies.firstWhere((p) => p.slug == slug);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Policies & Legal',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          indicatorColor: const Color(0xFF0F172A),
          indicatorWeight: 3,
          tabs: _tabItems.map((item) => Tab(text: item['title'])).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : TabBarView(
              controller: _tabController,
              children: _tabItems.map((item) {
                final slug = item['slug']!;
                final policy = _getPolicyForSlug(slug);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policy?.title ?? item['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          policy?.content ?? 'Policy information is currently being updated.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF334155),
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
