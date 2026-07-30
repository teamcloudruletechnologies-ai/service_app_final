import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api) {
    _api.onUnauthorized = () {
      notifyListeners();
    };
  }

  final ApiService _api;
  bool loading = true;
  String? error;
  double? latitude;
  double? longitude;
  String? house;
  String? area;
  String? city;
  String? district;
  String? state;
  String? pincode;
  String? gender;
  String? fullAddress;

  bool get isLoggedIn => _api.isLoggedIn;
  UserAccount? get user => _api.account;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    await _api.init();
    final prefs = await SharedPreferences.getInstance();
    latitude = prefs.getDouble('user_lat');
    longitude = prefs.getDouble('user_lng');
    house = prefs.getString('user_house');
    area = prefs.getString('user_area');
    city = prefs.getString('user_city');
    district = prefs.getString('user_district');
    state = prefs.getString('user_state');
    pincode = prefs.getString('user_pincode');
    gender = prefs.getString('user_gender');
    fullAddress = prefs.getString('user_full_address');
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

  Future<void> saveLocationCoordinates(double lat, double lng) async {
    latitude = lat;
    longitude = lng;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_lat', lat);
    await prefs.setDouble('user_lng', lng);
    notifyListeners();
  }

  Future<void> saveFullProfileLocation({
    required double lat,
    required double lng,
    required String houseVal,
    required String areaVal,
    required String cityVal,
    required String districtVal,
    required String stateVal,
    required String pincodeVal,
    required String fullAddr,
    String? genderVal,
  }) async {
    latitude = lat;
    longitude = lng;
    house = houseVal;
    area = areaVal;
    city = cityVal;
    district = districtVal;
    state = stateVal;
    pincode = pincodeVal;
    fullAddress = fullAddr;
    gender = genderVal;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_lat', lat);
    await prefs.setDouble('user_lng', lng);
    await prefs.setString('user_house', houseVal);
    await prefs.setString('user_area', areaVal);
    await prefs.setString('user_city', cityVal);
    await prefs.setString('user_district', districtVal);
    await prefs.setString('user_state', stateVal);
    await prefs.setString('user_pincode', pincodeVal);
    await prefs.setString('user_full_address', fullAddr);
    if (genderVal != null) await prefs.setString('user_gender', genderVal);
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

  Future<Map<String, dynamic>?> phoneLogin(String phone, {String role = 'user'}) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      final res = await _api.phoneLogin(phone, role: role);
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

  Future<bool> registerWithoutPassword({
    required String name,
    String? email,
    String? phone,
  }) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.registerWithoutPassword(name: name, email: email, phone: phone);
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

  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? phone,
    String? state,
    String? address,
  }) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.updateUserProfile(
        name: name,
        email: email,
        phone: phone,
        state: state,
        address: address,
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
    String? status,
    String? city,
    String? pincode,
    String? serviceType,
    int? experienceYears,
  }) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      await _api.updateWorkerProfile(
        status: status,
        city: city,
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

  Future<void> reloadProfile() async {
    try {
      await _api.fetchProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await _api.logout();
    notifyListeners();
  }
}
