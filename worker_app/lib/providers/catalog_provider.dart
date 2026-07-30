import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);

  final ApiService _api;

  List<ServiceCategory> categories = [];
  List<ServiceItem> services = [];
  bool loadingCategories = false;
  bool loadingServices = false;
  String? error;
  int? selectedCategoryId;

  Future<void> loadCategories() async {
    loadingCategories = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.fetchCategories();
      categories = result.items;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadServices({int? categoryId, String? search}) async {
    selectedCategoryId = categoryId;
    loadingServices = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.fetchServices(categoryId: categoryId, search: search);
      services = result.items;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loadingServices = false;
      notifyListeners();
    }
  }
}
