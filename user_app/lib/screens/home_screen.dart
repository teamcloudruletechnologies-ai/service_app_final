import 'dart:async' as async_timer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // 8 Categories with real image thumbnails for the 4x2 Grid
  final List<(String, String, IconData, Color)> _gridCategories = [
    ('Plumbing', 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400', Icons.plumbing_rounded, const Color(0xFFEBF8FF)),
    ('Electrical', 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400', Icons.electric_bolt_rounded, const Color(0xFFFEFCBF)),
    ('Cleaning', 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400', Icons.cleaning_services_rounded, const Color(0xFFE6FFFA)),
    ('Carpentry', 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=400', Icons.carpenter_rounded, const Color(0xFFFEEBC8)),
    ('Appliance', 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=400', Icons.kitchen_rounded, const Color(0xFFE9D8FD)),
    ('Painting', 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400', Icons.format_paint_rounded, const Color(0xFFFED7D7)),
    ('Pest Control', 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400', Icons.bug_report_rounded, const Color(0xFFC6F6D5)),
    ('More', '', Icons.grid_view_rounded, const Color(0xFFEDF2F7)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalog = context.read<CatalogProvider>();
      catalog.loadBanners();
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFC),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await catalog.loadBanners();
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
                // TOP HEADER: Clean Unboxed Header (Greeting + Location + Notification Bell)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hello, ${user?.name.isNotEmpty == true ? user!.name : "User"} 👋',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppTheme.primaryDark, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      selectedLoc,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationScreen()),
                            );
                          },
                          icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 22),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                // SEARCH BAR (Mockup Screen 5 & 6)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (val) {
                              catalog.setSearchQuery(val);
                              setState(() {});
                            },
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search for services...',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              catalog.setSearchQuery('');
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Color(0xFF475569), size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // DYNAMIC AUTO-SLIDING PROMO BANNER WIDGET (Renders exclusively Admin Panel uploaded banners)
                Padding(
                  padding: EdgeInsets.zero,
                  child: AutoSliderBannerWidget(
                    banners: catalog.banners,
                  ),
                ),
                const SizedBox(height: 24),

                // DYNAMIC CATEGORIES GRID (Loaded from Backend / Admin Panel)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                      if (catalog.selectedCategoryId != null)
                        TextButton(
                          onPressed: () {
                            catalog.selectCategory(null);
                          },
                          child: const Text(
                            'Show All',
                            style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: catalog.loadingCategories
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                          ),
                        )
                      : (catalog.categories.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.primary, size: 28),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Categories Coming Soon 🚀',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Service categories configured in Admin Panel will appear here.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: catalog.categories.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.70,
                              ),
                              itemBuilder: (context, index) {
                                final cat = catalog.categories[index];
                                final isSelected = catalog.selectedCategoryId == cat.id;
                                final imgUrl = ApiConfig.resolveImageUrl(cat.iconUrl);

                                return InkWell(
                                  onTap: () {
                                    if (isSelected) {
                                      catalog.selectCategory(null);
                                    } else {
                                      catalog.selectCategory(cat.id);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 68,
                                        height: 68,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2.0 : 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              blurRadius: isSelected ? 12 : 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: imgUrl.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: CachedNetworkImage(
                                                  imageUrl: imgUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => const Icon(Icons.category_rounded, color: Color(0xFF1E293B), size: 28),
                                                ),
                                              )
                                            : const Icon(Icons.category_rounded, color: Color(0xFF1E293B), size: 28),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.2,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                          color: isSelected ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )),
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
                  child: catalog.loadingServices
                      ? Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
                        )
                      : (catalog.services.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.handyman_rounded, color: AppTheme.primary, size: 28),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Services Coming Soon 🛠️',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Services configured in Admin Panel will appear here.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
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
                                                imageUrl: ApiConfig.resolveImageUrl(s.imageUrl),
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
                            )),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}