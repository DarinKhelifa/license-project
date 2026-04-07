import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch user's bookings
  Future<void> fetchBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await BookingApiService.getUserBookings();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create booking
  Future<bool> createBooking(Booking booking) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newBooking = await BookingApiService.createBooking(booking);
      _bookings.insert(0, newBooking);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await BookingApiService.cancelBooking(bookingId);
      _bookings.removeWhere((b) => b.id == bookingId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error cancelling booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get available slots
  Future<List<String>> getAvailableSlots(String facilityId, DateTime date) async {
    try {
      return await BookingApiService.getAvailableSlots(facilityId, date);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching available slots: $e');
      return [];
    }
  }
}
