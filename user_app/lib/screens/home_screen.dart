import 'dart:async' as async_timer;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_slider_banner_widget.dart';
import '../widgets/common_widgets.dart';
import 'location_picker_screen.dart';
import 'nearby_workers_screen.dart';
import 'profile_screen.dart';
import 'service_detail_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _sortBy = 'all';
  bool _expressMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final catalog = context.read<CatalogProvider>();
      catalog.loadBanners();
      catalog.loadCategories();
      catalog.loadServices();

      if (auth.latitude == null || auth.longitude == null) {
        _autoFetchGpsLocation(auth);
      }
    });
  }

  Future<void> _autoFetchGpsLocation(AuthProvider auth) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        await auth.saveLocationCoordinates(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint("Auto GPS Fetch error: $e");
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    final catalog = context.read<CatalogProvider>();
    catalog.loadServices(
      categoryId: catalog.selectedSubCategoryId ?? catalog.selectedCategoryId,
      search: query,
    );
  }

  List<ServiceItem> _getSortedServices(List<ServiceItem> services) {
    final sorted = List<ServiceItem>.from(services);
    switch (_sortBy) {
      case 'top_rated':
        sorted.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case 'most_booked':
        sorted.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
        break;
      case 'price_low':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      default:
        break;
    }
    return sorted;
  }

  Future<void> _navigateToService(BuildContext context, AuthProvider auth, ServiceItem service) async {
    if (auth.latitude != null && auth.longitude != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NearbyWorkersScreen(
            service: service,
            address: auth.user?.address ?? 'Current Location',
            latitude: auth.latitude!,
            longitude: auth.longitude!,
            userName: auth.user?.name,
          ),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(serviceType: service.categoryName),
      ),
    );
    if (result != null && mounted) {
      await auth.saveLocationCoordinates(result.latitude ?? 0, result.longitude ?? 0);
      if (auth.user?.address == null || auth.user!.address!.isEmpty) {
        await auth.updateUserProfile(address: result.address);
      }
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NearbyWorkersScreen(
              service: service,
              address: result.address,
              latitude: result.latitude ?? 0,
              longitude: result.longitude ?? 0,
              workers: result.workers,
              userName: auth.user?.name,
            ),
          ),
        );
      }
    }
  }

  Widget _buildProfileButton(BuildContext context, UserAccount? user) {
    final initial = (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Hero(
        tag: 'profile_avatar_hero_home',
        child: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE3D0BA),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A1A1A),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldFlashSaleBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F0C08), Color(0xFF261C14), Color(0xFF0F0C08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.auto_awesome, color: const Color(0xFFD4AF37), size: 100),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, color: const Color(0xFFD4AF37), size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'GOLD',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.translate('gold_flash_sale'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE3D0BA),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.translate('gold_price_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3D0BA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.translate('renew_gold'),
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Color(0xFF1A1A1A), size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreOffersCard() {
    return Container(
      width: 75,
      height: 82,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE23744), Color(0xFFC62833)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE23744).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              context.translate('offers'),
              style: const TextStyle(
                color: Color(0xFFE23744),
                fontWeight: FontWeight.w900,
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.translate('explore'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3), // Crisp Milk White
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Name, User Name, Location & Profile button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.translate('app_name'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                color: AppTheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.name != null && auth.user!.name.isNotEmpty
                                  ? '${context.translate('hey')}${auth.user!.name}'
                                  : context.translate('welcome_guest'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.of(context).push<LocationPickerResult>(
                                  MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                                );
                                if (result != null && mounted) {
                                  await auth.saveLocationCoordinates(result.latitude ?? 0, result.longitude ?? 0);
                                  await auth.updateUserProfile(address: result.address);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, color: AppTheme.secondary, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      auth.user?.address ?? context.translate('detecting_location'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: AppTheme.secondary, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildProfileButton(context, auth.user),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar below
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      cursorColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: context.translate('search_hint'),
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: _search,
                      onSubmitted: _search,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ─── Auto-sliding Banner Section ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AutoSliderBannerWidget(banners: catalog.banners),
            ),
          ),
          // ─── CATEGORY CHIPS (Zomato circular style) ───
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  CircularCategoryButton(
                    label: 'All',
                    icon: Icons.grid_view,
                    selected: catalog.selectedCategoryId == null,
                    onTap: () {
                      catalog.clearFilters();
                      catalog.loadServices(search: _searchCtrl.text);
                    },
                  ),
                  ...catalog.categories.map((cat) {
                    IconData iconData = Icons.home_repair_service;
                    if (cat.name.toLowerCase().contains('clean')) {
                      iconData = Icons.cleaning_services_outlined;
                    } else if (cat.name.toLowerCase().contains('plumb')) {
                      iconData = Icons.plumbing_outlined;
                    } else if (cat.name.toLowerCase().contains('elect')) {
                      iconData = Icons.electrical_services_outlined;
                    } else if (cat.name.toLowerCase().contains('repair')) {
                      iconData = Icons.build_outlined;
                    } else if (cat.name.toLowerCase().contains('paint')) {
                      iconData = Icons.format_paint_outlined;
                    } else if (cat.name.toLowerCase().contains('ac')) {
                      iconData = Icons.ac_unit_outlined;
                    } else if (cat.name.toLowerCase().contains('carp')) {
                      iconData = Icons.handyman_outlined;
                    } else if (cat.name.toLowerCase().contains('pest')) {
                      iconData = Icons.bug_report_outlined;
                    }
                    return CircularCategoryButton(
                      label: cat.name,
                      icon: iconData,
                      selected: catalog.selectedCategoryId == cat.id,
                      onTap: () {
                        catalog.selectCategory(cat.id, search: _searchCtrl.text);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          // ─── SUB-CATEGORY CHIPS (animated slide-in when category selected) ───
          if (catalog.selectedCategoryId != null)
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: catalog.loadingSubCategories
                    ? const SizedBox(
                        height: 44,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary),
                          ),
                        ),
                      )
                    : catalog.subCategories.isEmpty
                        ? const SizedBox.shrink()
                        : SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                // "All" sub-category chip
                                _SubCategoryChip(
                                  label: 'All',
                                  selected: catalog.selectedSubCategoryId == null,
                                  onTap: () => catalog.selectSubCategory(null, search: _searchCtrl.text),
                                ),
                                const SizedBox(width: 8),
                                ...catalog.subCategories.map((sub) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _SubCategoryChip(
                                    label: sub.name,
                                    selected: catalog.selectedSubCategoryId == sub.id,
                                    onTap: () => catalog.selectSubCategory(sub.id, search: _searchCtrl.text),
                                  ),
                                )),
                              ],
                            ),
                          ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: catalog.loadingServices
                ? const SliverFillRemaining(child: LoadingView(message: 'Loading services...'))
                : catalog.error != null
                    ? SliverFillRemaining(
                        child: ErrorView(
                          message: catalog.error!,
                          onRetry: () {
                            catalog.loadCategories();
                            catalog.loadServices();
                          },
                        ),
                      )
                    : catalog.services.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(child: Text('No services available')),
                          )
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final sorted = _getSortedServices(catalog.services);
                                final service = sorted[index];
                                return ServiceCard(
                                  service: service,
                                  onTap: () => _navigateToService(context, auth, service),
                                );
                              },
                              childCount: _getSortedServices(catalog.services).length,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final bool loading;

  const BannerCarousel({
    super.key,
    required this.banners,
    required this.loading,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  async_timer.Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92, initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = async_timer.Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.banners.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A5343)),
        ),
      );
    }

    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final imageUrl = ApiConfig.resolveImageUrl(banner.imageUrl);

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.08)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 160,
                      width: Curves.easeOut.transform(value) * MediaQuery.sizeOf(context).width,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.isNotEmpty
                            ? (imageUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(imageUrl.split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFE5E7EB),
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A5343)),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFFE5E7EB),
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ))
                            : Container(color: Colors.grey.shade200),
                        if (banner.title != null && banner.title!.isNotEmpty)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.0),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (banner.title != null && banner.title!.isNotEmpty)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Text(
                              banner.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF4A5343)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CircularCategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const CircularCategoryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected ? AppTheme.secondary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.secondary : const Color(0xFFE3D0BA),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? AppTheme.secondary : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ZomatoFilterChip extends StatelessWidget {
  final String label;
  final Widget? icon;
  final bool active;
  final VoidCallback onTap;

  const ZomatoFilterChip({
    super.key,
    required this.label,
    this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.secondary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppTheme.secondary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.secondary : AppTheme.primary,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}