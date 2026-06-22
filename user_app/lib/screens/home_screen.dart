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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFE5E7EB)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Hi, ${auth.user?.name.split(' ').first ?? 'User'} 👋',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              background: Container(color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: _search,
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
                        onSelected: (_) => catalog.loadServices(),
                      );
                    }
                    final cat = catalog.categories[index - 1];
                    final selected = catalog.selectedCategoryId == cat.id;
                    return FilterChip(
                      label: Text(cat.name),
                      selected: selected,
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
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
