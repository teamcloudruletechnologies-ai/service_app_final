import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiService _api;
  bool loading = true;
  String? error;

  bool get isLoggedIn => _api.isLoggedIn;
  UserAccount? get user => _api.account;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    await _api.init();
    if (_api.isLoggedIn) {
      try {
        await _api.fetchProfile();
      } catch (_) {
        await _api.logout();
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> login(String login, String password) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.login(login, password);
      loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    String? email,
    String? phone,
    required String password,
  }) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.register(name: name, email: email, phone: phone, password: password);
      loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    notifyListeners();
  }
}
