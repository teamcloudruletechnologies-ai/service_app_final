import 'package:flutter/material.dart';
import 'booking_form_screen.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class NearbyWorkersScreen extends StatelessWidget {
  const NearbyWorkersScreen({
    super.key,
    required this.service,
    required this.address,
    required this.workers,
  });

  final ServiceItem service;
  final String address;
  final List<NearbyWorker> workers;

  IconData _getServiceIcon(String? serviceType) {
    if (serviceType == null) return Icons.person;
    switch (serviceType.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'electrical':
        return Icons.electrical_services;
      case 'ac service':
        return Icons.ac_unit;
      case 'others':
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3), // Crisp Milk White
      appBar: AppBar(
        title: const Text('Select a Worker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address details card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Service Location',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Available ${service.categoryName ?? service.name}s Nearby',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),

          // Worker list
          Expanded(
            child: workers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No nearby workers found for this service.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You can still book, and we will assign the next available worker.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final w = workers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Photo Avatar
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primary.withOpacity(0.1),
                                backgroundImage: (w.photoUrl != null && w.photoUrl!.isNotEmpty)
                                    ? NetworkImage(w.photoUrl!)
                                    : null,
                                child: (w.photoUrl == null || w.photoUrl!.isEmpty)
                                    ? Icon(_getServiceIcon(w.serviceType), color: AppTheme.primary, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Info Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${w.experienceYears} Years Experience',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 2),
                                        Text(
                                          w.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.location_on, color: Colors.grey.shade400, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${w.distance?.toStringAsFixed(1) ?? "0.0"} km away',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Book button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BookingFormScreen(
                                        service: service,
                                        initialAddress: address,
                                        selectedWorker: w,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingFormScreen(
                    service: service,
                    initialAddress: address,
                    selectedWorker: null,
                  ),
                ),
              );
            },
            child: const Text(
              'Book Any Available Worker',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
