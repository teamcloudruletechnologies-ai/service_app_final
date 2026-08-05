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
import 'profile_screen.dart';
import 'service_detail_screen.dart';
import 'nearby_workers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _servicesKey = GlobalKey();

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
      Future.wait([
        catalog.loadBanners(),
        catalog.loadCategories(),
        catalog.loadServices(),
      ]);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keyContext = _servicesKey.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
    });
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
              await Future.wait([
                catalog.loadBanners(),
                catalog.loadCategories(),
                catalog.loadServices(forceRefresh: true),
              ]);
            },
          color: AppTheme.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
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
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Notification Icon Button
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
                          const SizedBox(width: 8),

                          // Profile Initial Avatar Button (Opened from Top Header)
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (user?.name.trim().isNotEmpty == true) ? user!.name.trim()[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // SEARCH BAR (Mockup Screen 5 & 6)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Container(
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
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Icon(Icons.cancel_rounded, color: Color(0xFF94A3B8), size: 18),
                                ),
                              )
                            else
                              const SizedBox(width: 16),
                          ],
                        ),
                      ),
                      if (_searchCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSearchPopupOverlay(context, catalog),
                      ],
                    ],
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
                      TextButton(
                        onPressed: () {
                          catalog.selectCategory(null);
                        },
                        child: Text(
                          'Show All',
                          style: TextStyle(
                            color: catalog.selectedCategoryId != null ? const Color(0xFF0F172A) : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: catalog.categories.isEmpty && catalog.loadingCategories
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2),
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
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.88,
                              ),
                              itemBuilder: (context, index) {
                                final cat = catalog.categories[index];
                                final isSelected = catalog.selectedCategoryId == cat.id;
                                final imgUrl = ApiConfig.resolveImageUrl(cat.iconUrl);

                                 return InkWell(
                                  onTap: () {
                                    final isScrolledDown = _scrollController.hasClients && _scrollController.offset > 220.0;
                                    if (isSelected) {
                                      catalog.selectCategory(null);
                                    } else {
                                      catalog.selectCategory(cat.id);
                                      if (!isScrolledDown) {
                                        _scrollToServices();
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 82,
                                        height: 82,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                            width: isSelected ? 2.2 : 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? const Color(0xFF0F172A).withValues(alpha: 0.15)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              blurRadius: isSelected ? 14 : 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: imgUrl.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(18),
                                                child: CachedNetworkImage(
                                                  imageUrl: imgUrl,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => const Icon(Icons.category_rounded, color: Color(0xFF0F172A), size: 32),
                                                ),
                                              )
                                            : const Icon(Icons.category_rounded, color: Color(0xFF0F172A), size: 32),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.25,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                                          letterSpacing: -0.2,
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
                Padding(
                  key: _servicesKey,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Our Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: catalog.services.isEmpty && catalog.loadingServices
                      ? Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2)),
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
                                childAspectRatio: 0.90,
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
                                              color: Color(0xFFF1F5F9),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Text(
                                            s.name,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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

  Widget _buildSearchPopupOverlay(BuildContext context, CatalogProvider catalog) {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar in popup
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.manage_search_rounded, size: 18, color: Color(0xFF0F172A)),
                    const SizedBox(width: 6),
                    const Text(
                      'Matching Services',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (catalog.loadingServices)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${catalog.services.length} found',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),

          // Service items list inside popup
          Flexible(
            child: catalog.loadingServices
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                    ),
                  )
                : (catalog.services.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 8),
                            Text(
                              'No services matching "$query"',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: catalog.services.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final service = catalog.services[index];
                          final imgUrl = ApiConfig.resolveImageUrl(service.imageUrl);

                          return InkWell(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ServiceDetailScreen(service: service),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: imgUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: imgUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(Icons.handyman_rounded, color: Color(0xFF0F172A), size: 20),
                                            ),
                                          )
                                        : const Icon(Icons.handyman_rounded, color: Color(0xFF0F172A), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Book',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.chevron_right_rounded, color: Colors.white, size: 14),
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
    );
  }
}