import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiService.init();
      final data = await _apiService.fetchWorkerEarnings();
      setState(() {
        _stats = data['stats'] as Map<String, dynamic>? ?? {};
        _history = data['history'] as List? ?? [];
      });
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    // Filter today's earnings
    final today = DateTime.now();
    final todayHistory = _history.where((item) {
      final paidAtStr = item['paid_at'] as String?;
      if (paidAtStr == null) return false;
      final paidAt = DateTime.tryParse(paidAtStr);
      return paidAt != null &&
          paidAt.year == today.year &&
          paidAt.month == today.month &&
          paidAt.day == today.day;
    }).toList();

    final otherHistory = _history.where((item) {
      final paidAtStr = item['paid_at'] as String?;
      if (paidAtStr == null) return true;
      final paidAt = DateTime.tryParse(paidAtStr);
      return paidAt == null ||
          !(paidAt.year == today.year &&
              paidAt.month == today.month &&
              paidAt.day == today.day);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Earnings'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.zomatoRed),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.olive,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total Earnings Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TOTAL EARNINGS',
                                style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFmt.format(_stats['total_earnings'] ?? 0.0),
                                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Paid and Pending Stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Received',
                                amount: currencyFmt.format(_stats['paid_earnings'] ?? 0.0),
                                color: AppTheme.olive,
                                icon: Icons.check_circle_outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Pending',
                                amount: currencyFmt.format(_stats['pending_earnings'] ?? 0.0),
                                color: AppTheme.zomatoRed,
                                icon: Icons.schedule_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Today Section
                        if (todayHistory.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppTheme.olive,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Today',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...todayHistory.map((item) => _buildHistoryItem(item, currencyFmt, dateFmt)),
                          const SizedBox(height: 20),
                        ],

                        // Payout History
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Payout History',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        otherHistory.isEmpty && todayHistory.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text('No payout transactions yet', style: TextStyle(color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              )
                            : otherHistory.isEmpty
                                ? const SizedBox.shrink()
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: otherHistory.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = otherHistory[index] as Map<String, dynamic>;
                                      return _buildHistoryItem(item, currencyFmt, dateFmt);
                                    },
                                  ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, NumberFormat currencyFmt, DateFormat dateFmt) {
    final paidAtStr = item['paid_at'] as String?;
    final paidAt = paidAtStr != null ? DateTime.tryParse(paidAtStr) : null;
    final status = item['status'] as String? ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (status == 'paid' ? AppTheme.olive : AppTheme.zomatoRed).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == 'paid' ? Icons.check_circle_outline : Icons.schedule_outlined,
              color: status == 'paid' ? AppTheme.olive : AppTheme.zomatoRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['service_name'] ?? 'Home Service',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  paidAt != null ? dateFmt.format(paidAt) : 'Processing...',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFmt.format(item['worker_payout'] ?? 0.0),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
              ),
              const SizedBox(height: 2),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == 'paid' ? AppTheme.olive : AppTheme.zomatoRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
