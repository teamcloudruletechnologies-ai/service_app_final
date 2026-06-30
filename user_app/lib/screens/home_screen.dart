import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../widgets/common_widgets.dart';
import 'service_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

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

  void _search(String query) {
    context.read<CatalogProvider>().loadServices(
          categoryId: context.read<CatalogProvider>().selectedCategoryId,
          search: query,
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
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${auth.user?.name.split(' ').first ?? 'User'} 👋',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -1.0,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find trusted professionals near you',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  cursorColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4A5343)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: _search,
                ),
              ),
            ),
          ),
          if (catalog.loadingCategories)
            const SliverToBoxAdapter(child: SizedBox(height: 48, child: LoadingView()))
          else if (catalog.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: catalog.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final selected = catalog.selectedCategoryId == null;
                      return FilterChip(
                        label: const Text('All'),
                        selected: selected,
                        selectedColor: const Color(0xFF4A5343),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide(
                          color: selected ? Colors.transparent : const Color(0xFFE3D0BA),
                          width: 1.0,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        onSelected: (_) => catalog.loadServices(),
                      );
                    }
                    final cat = catalog.categories[index - 1];
                    final selected = catalog.selectedCategoryId == cat.id;
                    return FilterChip(
                      label: Text(cat.name),
                      selected: selected,
                      selectedColor: const Color(0xFF4A5343),
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: BorderSide(
                        color: selected ? Colors.transparent : const Color(0xFFE3D0BA),
                        width: 1.0,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      onSelected: (_) => catalog.loadServices(categoryId: cat.id),
                    );
                  },
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
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
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final service = catalog.services[index];
                                return ServiceCard(
                                  service: service,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ServiceDetailScreen(serviceId: service.id),
                                    ),
                                  ),
                                );
                              },
                              childCount: catalog.services.length,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
