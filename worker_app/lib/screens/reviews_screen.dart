import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key, this.workerId = 0});

  final int workerId;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _apiService = ApiService();
  bool _loading = true;
  String? _error;
  List<ReviewItem> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiService.init();
      final pagedResult = await _apiService.fetchReviews(workerId: widget.workerId);
      setState(() {
        _reviews = pagedResult.items;
      });
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    // Calculate average rating
    final avgRating = _reviews.isNotEmpty
        ? _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activity'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
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
                        ElevatedButton(onPressed: _loadReviews, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your reviews from customers will show up here',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      color: AppTheme.olive,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Rating Summary Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        final active = avgRating > starIdx;
                                        return Icon(
                                          active ? Icons.star : Icons.star_border,
                                          color: active ? Colors.amber : Colors.grey.shade300,
                                          size: 18,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_reviews.length} reviews',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Reviews List
                          ..._reviews.map((review) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                                    ),
                                    Text(
                                      dateFmt.format(review.createdAt),
                                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    final active = review.rating > starIdx;
                                    return Icon(
                                      active ? Icons.star : Icons.star_border,
                                      color: active ? Colors.amber : Colors.grey.shade300,
                                      size: 16,
                                    );
                                  }),
                                ),
                                if (review.comment != null && review.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    review.comment!,
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                                  ),
                                ],
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
    );
  }
}
