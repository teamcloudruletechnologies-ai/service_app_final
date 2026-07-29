import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'user_token';
  static const _accountKey = 'user_account';

  String? _token;
  UserAccount? _account;
  void Function()? onUnauthorized;

  String? get token => _token;
  UserAccount? get account => _account;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final accountJson = prefs.getString(_accountKey);
    if (accountJson != null) {
      _account = UserAccount.fromJson(jsonDecode(accountJson));
    }
  }

  Future<void> _saveSession(String token, UserAccount account) async {
    _token = token;
    _account = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_accountKey, jsonEncode({
      'id': account.id,
      'role': account.role,
      'name': account.name,
      'email': account.email,
      'phone': account.phone,
      'status': account.status,
      'kyc_status': account.kycStatus,
      'service_type': account.serviceType,
      'experience_years': account.experienceYears,
      'city': account.city,
      'pincode': account.pincode,
      'state': account.state,
      'address': account.address,
    }));
  }

  Future<void> logout() async {
    _token = null;
    _account = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accountKey);
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401) {
      final reqPath = response.request?.url.path ?? '';
      if (reqPath.contains('/auth/me') || reqPath.contains('/user/fcm-token') || reqPath.contains('/profile')) {
        logout();
        onUnauthorized?.call();
      }
    }
    final message = body is Map ? (body['message'] as String? ?? 'Request failed') : 'Request failed';
    throw ApiException(message, statusCode: response.statusCode);
  }

  PagedResult<T> _parsePaged<T>(Map<String, dynamic> payload, T Function(Map<String, dynamic>) fromJson) {
    final rows = (payload['rows'] as List? ?? [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = payload['meta'] as Map<String, dynamic>? ?? {};
    return PagedResult(
      items: rows,
      total: meta['total'] as int? ?? rows.length,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 50,
    );
  }

  Future<Map<String, dynamic>> login(String login, String password, {String role = 'user'}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers(),
      body: jsonEncode({'login': login, 'password': password, 'role': role}),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>;
    final account = UserAccount.fromJson(payload['account']);
    await _saveSession(payload['token'] as String, account);
    return payload;
  }

  Future<void> updateFcmToken(String token) async {
    if (_token == null) return;
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/fcm-token'),
        headers: _headers(),
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/app/addresses'),
        headers: _headers(),
      );
      final data = _decode(response);
      if (data['success'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> createAddress(Map<String, dynamic> body) async {
    if (_token == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/app/addresses'),
        headers: _headers(),
        body: jsonEncode(body),
      );
      final data = _decode(response);
      if (data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> phoneLogin(String phone, {String role = 'user'}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/phone-login'),
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'role': role}),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>;
    final account = UserAccount.fromJson(payload['account']);
    await _saveSession(payload['token'] as String, account);
    return payload;
  }

  Future<UserAccount> register({
    required String name,
    String? email,
    String? phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/user/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'password': password,
      }),
    );
    _decode(response);
    await login(email ?? phone ?? '', password, role: 'user');
    return _account!;
  }

  Future<UserAccount> registerWithoutPassword({
    required String name,
    String? email,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/user/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    _decode(response);
    await phoneLogin(phone ?? email ?? '', role: 'user');
    return _account!;
  }

  Future<UserAccount> registerWorker({
    required String name,
    String? email,
    required String phone,
    required String password,
    required String serviceType,
    required int experienceYears,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/worker/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        'phone': phone,
        'password': password,
        'serviceType': serviceType,
        'experienceYears': experienceYears,
        'city': city,
      }),
    );
    _decode(response);
    await login(phone, password, role: 'worker');
    return _account!;
  }

  Future<UserAccount> fetchProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: _headers(auth: true),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final account = UserAccount.fromJson(data['data']);
    _account = account;
    // Persist updated account to SharedPreferences so next launch has fresh data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountKey, jsonEncode({
      'id': account.id,
      'role': account.role,
      'name': account.name,
      'email': account.email,
      'phone': account.phone,
      'status': account.status,
      'kyc_status': account.kycStatus,
      'service_type': account.serviceType,
      'experience_years': account.experienceYears,
      'city': account.city,
      'pincode': account.pincode,
      'state': account.state,
      'address': account.address,
    }));
    return account;
  }

  Future<PagedResult<ServiceCategory>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/services/categories?limit=50'),
      headers: _headers(),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return _parsePaged(data['data'] as Map<String, dynamic>, ServiceCategory.fromJson);
  }

  Future<List<ServiceCategory>> fetchSubCategories(int categoryId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/services/categories/$categoryId/subcategories'),
      headers: _headers(),
    );
    final data = _decode(response) as Map<String, dynamic>;
    // Response is paged, extract rows
    final payload = data['data'] as Map<String, dynamic>;
    final rows = (payload['rows'] as List? ?? [])
        .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return rows;
  }

  Future<PagedResult<BannerItem>> fetchBanners() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/banners?limit=10'),
      headers: _headers(),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return _parsePaged(data['data'] as Map<String, dynamic>, BannerItem.fromJson);
  }

  Future<PagedResult<ServiceItem>> fetchServices({int? categoryId, String? search}) async {
    final params = <String, String>{'limit': '50', 'status': 'active'};
    if (categoryId != null) params['category_id'] = '$categoryId';
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/app/services').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers());
    final data = _decode(response) as Map<String, dynamic>;
    return _parsePaged(data['data'] as Map<String, dynamic>, ServiceItem.fromJson);
  }

  Future<ServiceItem> fetchService(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/services/$id'),
      headers: _headers(),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return ServiceItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<BookingItem> createBooking({
    required int serviceId,
    required String address,
    String? notes,
    DateTime? scheduledAt,
    int? workerId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/bookings'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'service_id': serviceId,
        'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        if (workerId != null) 'worker_id': workerId,
      }),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return BookingItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PagedResult<BookingItem>> fetchBookings({String? status}) async {
    final params = <String, String>{'limit': '50'};
    if (status != null) params['status'] = status;

    final uri = Uri.parse('${ApiConfig.baseUrl}/app/bookings').replace(queryParameters: params);
    debugPrint("--------------------------------------------------");
    debugPrint("FETCH BOOKINGS URI: $uri");
    debugPrint("FETCH BOOKINGS TOKEN: $_token");
    final response = await http.get(uri, headers: _headers(auth: true));
    debugPrint("FETCH BOOKINGS STATUS CODE: ${response.statusCode}");
    debugPrint("FETCH BOOKINGS BODY: ${response.body}");
    debugPrint("--------------------------------------------------");
    final data = _decode(response) as Map<String, dynamic>;
    return _parsePaged(data['data'] as Map<String, dynamic>, BookingItem.fromJson);
  }

  Future<BookingItem> fetchBooking(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/bookings/$id'),
      headers: _headers(auth: true),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return BookingItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<BookingItem> cancelBooking(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/app/bookings/$id/cancel'),
      headers: _headers(auth: true),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return BookingItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  // --- WORKER SERVICES ---

  Future<Map<String, dynamic>> submitKyc({
    required String aadhaarNumber,
    required String aadhaarUrl,
    required String panNumber,
    required String panUrl,
    required String bankAccountNumber,
    required String bankPassbookUrl,
    required String selfieUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/kyc'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'aadhaarNumber': aadhaarNumber,
        'aadhaarUrl': aadhaarUrl,
        'panNumber': panNumber,
        'panUrl': panUrl,
        'bankAccountNumber': bankAccountNumber,
        'bankPassbookUrl': bankPassbookUrl,
        'selfieUrl': selfieUrl,
      }),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return data;
  }

  Future<Map<String, dynamic>?> fetchMyKyc() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kyc'),
      headers: _headers(auth: true),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final rows = data['data']?['rows'] as List?;
    if (rows != null && rows.isNotEmpty) {
      return rows.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<UserAccount> updateUserProfile({
    String? name,
    String? email,
    String? phone,
    String? state,
    String? address,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/app/user/profile'),
      headers: _headers(auth: true),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (state != null) 'state': state,
        if (address != null) 'address': address,
      }),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final account = UserAccount.fromJson(data['data']);
    _account = account;
    // Update local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountKey, jsonEncode({
      'id': account.id,
      'role': account.role,
      'name': account.name,
      'email': account.email,
      'phone': account.phone,
      'status': account.status,
      'kyc_status': account.kycStatus,
      'service_type': account.serviceType,
      'experience_years': account.experienceYears,
      'city': account.city,
      'pincode': account.pincode,
      'state': account.state,
      'address': account.address,
    }));
    return account;
  }

  Future<UserAccount> updateWorkerProfile({
    String? status,
    String? city,
    String? pincode,
    String? serviceType,
    int? experienceYears,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/app/worker/profile'),
      headers: _headers(auth: true),
      body: jsonEncode({
        if (status != null) 'status': status,
        if (city != null) 'city': city,
        if (pincode != null) 'pincode': pincode,
        if (serviceType != null) 'serviceType': serviceType,
        if (experienceYears != null) 'experienceYears': experienceYears,
      }),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final account = UserAccount.fromJson(data['data']);
    _account = account;
    // Update local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountKey, jsonEncode({
      'id': account.id,
      'role': account.role,
      'name': account.name,
      'email': account.email,
      'phone': account.phone,
      'status': account.status,
      'kyc_status': account.kycStatus,
      'service_type': account.serviceType,
      'experience_years': account.experienceYears,
      'city': account.city,
      'pincode': account.pincode,
    }));
    return account;
  }

  Future<BookingItem> updateBookingStatus(int bookingId, String status) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/app/bookings/$bookingId/status'),
      headers: _headers(auth: true),
      body: jsonEncode({'status': status}),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return BookingItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> updateWorkerLocation(double lat, double lng, {String? pincode}) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/locations/update-my-location'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'lat': lat,
        'lng': lng,
        if (pincode != null) 'pincode': pincode,
      }),
    );
  }

  /// Fetches active serviceable pincodes & cities (no auth required).
  /// Used to show service availability areas to users.
  Future<List<Map<String, dynamic>>> fetchServiceableLocations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/locations/serviceable'),
      headers: _headers(),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final rows = data['data'] as List? ?? [];
    return rows.cast<Map<String, dynamic>>();
  }

  /// Fetches workers within a specified radius (default 10km) of target coordinates
  Future<List<NearbyWorker>> fetchNearbyWorkers(double lat, double lng, {String? serviceType, double? radius}) async {
    final params = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
      if (radius != null) 'radius': '$radius',
      if (serviceType != null) 'service_type': serviceType,
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/app/locations/nearby').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers(auth: true));
    final data = _decode(response) as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    return list.map((e) => NearbyWorker.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- PAYMENTS ---

  Future<Map<String, dynamic>> createPaymentOrder(int bookingId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/payments/order'),
      headers: _headers(auth: true),
      body: jsonEncode({'bookingId': bookingId}),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required int bookingId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String razorpayOrderId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/payments/verify'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'bookingId': bookingId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'razorpayOrderId': razorpayOrderId,
      }),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  // --- REVIEWS ---

  Future<Map<String, dynamic>> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/app/reviews'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      }),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<PagedResult<ReviewItem>> fetchReviews({int? workerId, int? rating}) async {
    final params = <String, String>{'limit': '50'};
    if (workerId != null) params['workerId'] = '$workerId';
    if (rating != null) params['rating'] = '$rating';

    final uri = Uri.parse('${ApiConfig.baseUrl}/app/reviews').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers(auth: true));
    final data = _decode(response) as Map<String, dynamic>;
    return _parsePaged(data['data'] as Map<String, dynamic>, ReviewItem.fromJson);
  }

  // --- WORKER EARNINGS ---

  Future<Map<String, dynamic>> fetchWorkerEarnings() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/app/worker/earnings'),
      headers: _headers(auth: true),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }
}
