import 'dart:async' as async_timer;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
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

  void _search(String query) {
    context.read<CatalogProvider>().loadServices(
          categoryId: context.read<CatalogProvider>().selectedCategoryId,
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
              const Text(
                'FLASH SALE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE3D0BA),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '₹1 for 3 months',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Renew Gold now',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Color(0xFF1A1A1A), size: 12),
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
            child: const Text(
              'OFFERS',
              style: TextStyle(
                color: Color(0xFFE23744),
                fontWeight: FontWeight.w900,
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore',
            style: TextStyle(
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
                  // Zomato style location + actions bar
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.secondary, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Home',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_drop_down, color: AppTheme.secondary, size: 20),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.address ?? 'Detecting location...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Zomato style Gold Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3E5AB), Color(0xFFE3D0BA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFB8860B), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, color: Color(0xFFB8860B), size: 12),
                            SizedBox(width: 2),
                            Text(
                              'GOLD',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 8,
                                color: Color(0xFF5C4033),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Zomato style Wallet Icon
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 0.8),
                          ),
                          child: Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildProfileButton(context, auth.user),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Zomato style search bar with Express toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
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
                          hintText: _expressMode ? 'Search "express cleaning"...' : 'Search "spicy biryani" or services...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                          suffixIcon: const Icon(Icons.mic, color: AppTheme.primary, size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: _search,
                        onSubmitted: _search,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mock toggle switch representing Zomato's mode toggle
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 28,
                        child: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _expressMode,
                            activeColor: AppTheme.secondary,
                            onChanged: (val) {
                              setState(() {
                                _expressMode = val;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _expressMode ? 'EXPRESS' : 'NORMAL',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _expressMode ? AppTheme.secondary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ─── Gold Sale Banner ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildGoldFlashSaleBanner(),
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
                  _buildExploreOffersCard(),
                  CircularCategoryButton(
                    label: 'All',
                    icon: Icons.grid_view,
                    selected: catalog.selectedCategoryId == null,
                    onTap: () {
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
                    }
                    return CircularCategoryButton(
                      label: cat.name,
                      icon: iconData,
                      selected: catalog.selectedCategoryId == cat.id,
                      onTap: () {
                        catalog.loadServices(categoryId: cat.id, search: _searchCtrl.text);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 12),
          ),
          // ─── FILTER / SORT ROW (Zomato-style filter chips) ───
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ZomatoFilterChip(
                    label: 'Filters',
                    icon: const Icon(Icons.tune, size: 14, color: AppTheme.primary),
                    active: _sortBy != 'all',
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  ZomatoFilterChip(
                    label: 'Near & Fast',
                    icon: const Icon(Icons.flash_on, size: 14, color: Colors.green),
                    active: _sortBy == 'most_booked',
                    onTap: () {
                      setState(() {
                        _sortBy = _sortBy == 'most_booked' ? 'all' : 'most_booked';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ZomatoFilterChip(
                    label: 'Top Rated',
                    active: _sortBy == 'top_rated',
                    onTap: () {
                      setState(() {
                        _sortBy = _sortBy == 'top_rated' ? 'all' : 'top_rated';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ZomatoFilterChip(
                    label: 'Price ↑',
                    active: _sortBy == 'price_low',
                    onTap: () {
                      setState(() {
                        _sortBy = _sortBy == 'price_low' ? 'all' : 'price_low';
                      });
                    },
                  ),
                ],
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
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ServiceDetailScreen(serviceId: service.id),
                                    ),
                                  ),
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