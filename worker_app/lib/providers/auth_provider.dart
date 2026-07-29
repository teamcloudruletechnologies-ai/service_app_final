import 'package:firebase_messaging/firebase_messaging.dart';
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
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null && token.isNotEmpty) {
            await _api.updateFcmToken(token);
          }
        } catch (_) {}
      } catch (_) {
        await _api.logout();
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> login(String login, String password, {String role = 'user'}) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.login(login, password, role: role);
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await _api.updateFcmToken(token);
        }
      } catch (_) {}
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

  Future<bool> registerWorker({
    required String name,
    String? email,
    required String phone,
    required String password,
    required String serviceType,
    required int experienceYears,
    required String city,
  }) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.registerWorker(
        name: name,
        email: email,
        phone: phone,
        password: password,
        serviceType: serviceType,
        experienceYears: experienceYears,
        city: city,
      );
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

  Future<bool> updateWorkerProfile({
    String? name,
    String? email,
    String? status,
    String? city,
    String? state,
    String? address,
    String? pincode,
    String? serviceType,
    int? experienceYears,
  }) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.updateWorkerProfile(
        name: name,
        email: email,
        status: status,
        city: city,
        state: state,
        address: address,
        pincode: pincode,
        serviceType: serviceType,
        experienceYears: experienceYears,
      );
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

  Future<Map<String, dynamic>?> phoneLoginOrRegister(String phone) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      final res = await _api.phoneLoginOrRegister(phone);
      loading = false;
      notifyListeners();
      return res;
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> reloadProfile() async {
    try {
      await _api.fetchProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateWorkerLocation(double lat, double lng, {String? pincode}) async {
    try {
      await _api.updateWorkerLocation(lat, lng, pincode: pincode);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _api.logout();
    notifyListeners();
  }
}
