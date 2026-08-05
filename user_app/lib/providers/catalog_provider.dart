import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);

  final ApiService _api;

  List<ServiceCategory> categories = [];
  List<ServiceCategory> subCategories = [];
  List<ServiceItem> services = [];
  List<BannerItem> banners = [];

  bool loadingCategories = false;
  bool loadingSubCategories = false;
  bool loadingServices = false;
  bool loadingBanners = false;
  String? error;

  int? selectedCategoryId;
  int? selectedSubCategoryId;

  Future<void> loadCategories() async {
    if (categories.isEmpty) {
      loadingCategories = true;
      error = null;
      notifyListeners();
    }
    try {
      final result = await _api.fetchCategories();
      categories = result.items;
    } on ApiException catch (e) {
      if (categories.isEmpty) error = e.message;
    } finally {
      loadingCategories = false;
      notifyListeners();
    }
  }

  /// Called when user taps a top-level category chip.
  /// Loads sub-categories for that category and filters services.
  Future<void> selectCategory(int? categoryId, {String? search}) async {
    selectedCategoryId = categoryId;
    selectedSubCategoryId = null;
    subCategories = [];
    notifyListeners();

    if (categoryId != null) {
      // Load sub-categories in background
      _loadSubCategories(categoryId);
    }

    // Load services filtered by this category
    await loadServices(categoryId: categoryId, search: search);
  }

  Future<void> setSearchQuery(String query) async {
    await loadServices(search: query.trim().isEmpty ? null : query.trim());
  }

  Future<void> _loadSubCategories(int categoryId) async {
    loadingSubCategories = true;
    notifyListeners();
    try {
      subCategories = await _api.fetchSubCategories(categoryId);
    } catch (_) {
      subCategories = [];
    } finally {
      loadingSubCategories = false;
      notifyListeners();
    }
  }

  /// Called when user taps a sub-category chip.
  Future<void> selectSubCategory(int? subCategoryId, {String? search}) async {
    selectedSubCategoryId = subCategoryId;
    notifyListeners();
    // Filter services by sub-category (sub-categories are stored as category_id in services)
    await loadServices(categoryId: subCategoryId ?? selectedCategoryId, search: search);
  }

  Future<void> loadBanners() async {
    if (banners.isEmpty) {
      loadingBanners = true;
      error = null;
      notifyListeners();
    }
    try {
      final result = await _api.fetchBanners();
      banners = result.items;
    } on ApiException catch (e) {
      if (banners.isEmpty) error = e.message;
    } finally {
      loadingBanners = false;
      notifyListeners();
    }
  }

  List<ServiceItem> _allServices = [];

  Future<void> loadServices({int? categoryId, String? search, bool forceRefresh = false}) async {
    selectedCategoryId = categoryId;

    final isSearching = search != null && search.trim().isNotEmpty;

    // Instant 0ms local filtering when full catalog is cached (Zero network call on category tap)
    if (_allServices.isNotEmpty && !isSearching && !forceRefresh) {
      if (categoryId != null) {
        services = _allServices.where((s) => s.categoryId == categoryId).toList();
      } else {
        services = List.from(_allServices);
      }
      loadingServices = false;
      notifyListeners();
      return;
    }

    if (services.isEmpty) {
      loadingServices = true;
      error = null;
      notifyListeners();
    }

    try {
      final result = await _api.fetchServices(categoryId: isSearching ? null : categoryId, search: search);

      if (!isSearching && (categoryId == null || forceRefresh)) {
        _allServices = List.from(result.items);
        if (categoryId != null) {
          services = _allServices.where((s) => s.categoryId == categoryId).toList();
        } else {
          services = List.from(result.items);
        }
      } else {
        services = result.items;
      }
    } on ApiException catch (e) {
      if (services.isEmpty) {
        error = e.message;
      }
    } finally {
      loadingServices = false;
      notifyListeners();
    }
  }

  void clearFilters() {
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
    notifyListeners();
  }
}
