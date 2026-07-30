import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider(this._api);

  final ApiService _api;

  List<BookingItem> bookings = [];
  bool loading = false;
  String? error;
  String? filterStatus;

  Future<void> loadBookings({String? status}) async {
    filterStatus = status;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.fetchBookings(status: status);
      bookings = result.items;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<BookingItem?> createBooking({
    required int serviceId,
    required String address,
    String? notes,
    DateTime? scheduledAt,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final booking = await _api.createBooking(
        serviceId: serviceId,
        address: address,
        notes: notes,
        scheduledAt: scheduledAt,
      );
      bookings = [booking, ...bookings];
      loading = false;
      notifyListeners();
      return booking;
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelBooking(int id) async {
    try {
      final updated = await _api.cancelBooking(id);
      bookings = bookings.map((b) => b.id == id ? updated : b).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBookingStatus(int id, String status, {String? otp}) async {
    try {
      final updated = await _api.updateBookingStatus(id, status, otp: otp);
      bookings = bookings.map((b) => b.id == id ? updated : b).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }
}
