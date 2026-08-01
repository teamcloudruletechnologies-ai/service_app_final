import 'dart:async' as async_timer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_slider_banner_widget.dart';
import 'bookings_screen.dart';
import 'location_picker_screen.dart';
import 'notification_screen.dart';
import 'service_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  // 8 Categories for the 4x2 Grid (Screen 5 & 6 Mockup)
  final List<(String, IconData, Color)> _gridCategories = [
    ('Plumbing', Icons.plumbing_rounded, const Color(0xFFEBF8FF)),
    ('Electrical', Icons.electric_bolt_rounded, const Color(0xFFFEFCBF)),
    ('Cleaning', Icons.cleaning_services_rounded, const Color(0xFFE6FFFA)),
    ('Carpentry', Icons.carpenter_rounded, const Color(0xFFFEEBC8)),
    ('Appliance', Icons.kitchen_rounded, const Color(0xFFE9D8FD)),
    ('Painting', Icons.format_paint_rounded, const Color(0xFFFED7D7)),
    ('Pest Control', Icons.bug_report_rounded, const Color(0xFFC6F6D5)),
    ('More', Icons.grid_view_rounded, const Color(0xFFEDF2F7)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadCategories();
      catalog.loadServices();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final user = context.watch<AuthProvider>().user;
    final selectedLoc = (user?.address != null && user!.address!.trim().isNotEmpty)
        ? user.address!
        : 'Madurai, Tamil Nadu';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await catalog.loadCategories();
            await catalog.loadServices();
          },
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP HEADER: Pale Background Container (App Name + User Name + Location + Notification Bell)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFEF08A)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Urban Service',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Hello, ${user?.name.isNotEmpty == true ? user!.name : "User"} 👋',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                );
                              },
                              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1A1A), size: 26),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppTheme.primaryDark, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                selectedLoc.length > 28 ? '${selectedLoc.substring(0, 28)}...' : selectedLoc,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF1A1A1A)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // SEARCH BAR (Mockup Screen 5 & 6)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) {
                        catalog.setSearchQuery(val);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search for services...',
                        hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF718096)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // DYNAMIC AUTO-SLIDING PROMO BANNER WIDGET
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: AutoSliderBannerWidget(
                    banners: catalog.banners.isNotEmpty
                        ? catalog.banners
                        : const [
                            BannerItem(id: 1, title: 'Summer Offer - 20% OFF (Code: URBAN20)', imageUrl: '', status: 'active'),
                            BannerItem(id: 2, title: '30-Min Doorstep Service', imageUrl: '', status: 'active'),
                            BannerItem(id: 3, title: 'Deep Cleaning Special 30% OFF', imageUrl: '', status: 'active'),
                          ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4x2 CATEGORIES GRID (Screen 5 & 6 Mockup)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                      TextButton(
                        onPressed: () {
                          catalog.clearFilters();
                          catalog.loadServices();
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _gridCategories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final item = _gridCategories[index];
                      return InkWell(
                        onTap: () {
                          if (index == 7) {
                            catalog.clearFilters();
                            catalog.loadServices();
                          } else {
                            final matchedCat = catalog.categories.firstWhere(
                              (c) => c.name.toLowerCase().contains(item.$1.toLowerCase().substring(0, 3)),
                              orElse: () => catalog.categories.isNotEmpty ? catalog.categories[0] : ServiceCategory(id: 1, name: item.$1, status: 'active'),
                            );
                            catalog.selectCategory(matchedCat.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: item.$3,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: item.$3.withValues(alpha: 0.8)),
                              ),
                              child: Icon(item.$2, color: const Color(0xFF1A1A1A), size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.$1,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // OUR SERVICES 2-COLUMN GRID (Heading changed & 2 Columns Grid Layout)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Our Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: catalog.services.isEmpty
                      ? Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: catalog.services.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (context, idx) {
                            final s = catalog.services[idx];
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s)),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEDF2F7),
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: CachedNetworkImage(
                                            imageUrl: ApiConfig.getUploadUrl(s.imageUrl),
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => const Icon(Icons.build_rounded, size: 40, color: AppTheme.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A1A)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: const [
                                              Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                              SizedBox(width: 4),
                                              Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A))),
                                            ],
                                          ),
                                        ],
                                      ),
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
          ),
        ),
      ),
    );
  }
}