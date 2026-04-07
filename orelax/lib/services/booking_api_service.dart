import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

class BookingApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const Duration httpTimeout = Duration(seconds: 30);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create booking
  static Future<Booking> createBooking(Booking booking) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: await _getHeaders(),
        body: jsonEncode(booking.toMap()),
      ).timeout(httpTimeout);

      if (response.statusCode == 201) {
        return Booking.fromMap(jsonDecode(response.body));
      } else {
        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');
        
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Failed to create booking');
        } catch (e) {
          throw Exception('Failed to create booking: ${response.body}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timeout while creating booking');
    } catch (e) {
      rethrow;
    }
  }

  // Get user's bookings
  static Future<List<Booking>> getUserBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/my-bookings'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading bookings');
    } catch (e) {
      rethrow;
    }
  }

  // Cancel booking
  static Future<void> cancelBooking(String bookingId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel booking');
      }
    } on TimeoutException {
      throw Exception('Request timeout while cancelling booking');
    } catch (e) {
      rethrow;
    }
  }

  // Check available slots for a facility
  static Future<List<String>> getAvailableSlots(String facilityId, DateTime date) async {
    try {
      final dateStr = date.toString().split(' ')[0]; // Format: YYYY-MM-DD
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/availability/$facilityId?date=$dateStr'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final slots = (data['availableSlots'] as List?)?.cast<String>() ?? [];
        return slots;
      } else {
        throw Exception('Failed to load available slots');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading availability');
    } catch (e) {
      rethrow;
    }
  }
}
