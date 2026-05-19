import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/facility_model.dart';

class FacilityApiService {
  static const String baseUrl = 'http://localhost:5001/api';
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

  // Get all facilities
  static Future<List<Facility>> getFacilities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/facilities'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Facility.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load facilities');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading facilities');
    }
  }

  // Get facility by ID
  static Future<Facility> getFacilityById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/facilities/$id'),
        headers: await _getHeaders(),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        return Facility.fromMap(jsonDecode(response.body));
      } else {
        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');
        
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Failed to load facility');
        } catch (e) {
          throw Exception('Failed to load facility: ${response.body}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading facility');
    } catch (e) {
      rethrow;
    }
  }

  // Create facility
  static Future<Facility> createFacility(Facility facility) async {
    try {
      final bodyData = jsonEncode(facility.toMap());
      debugPrint('Creating facility with data size: ${bodyData.length} bytes');
      
      final response = await http.post(
        Uri.parse('$baseUrl/facilities'),
        headers: await _getHeaders(),
        body: bodyData,
      ).timeout(httpTimeout);

      if (response.statusCode == 201) {
        return Facility.fromMap(jsonDecode(response.body));
      } else {
        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');
        
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Failed to create facility');
        } catch (e) {
          throw Exception('Failed to create facility: ${response.body}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timeout. Images may be too large. Please use smaller images.');
    } catch (e) {
      rethrow;
    }
  }

  // Update facility
  static Future<Facility> updateFacility(Facility facility) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/facilities/${facility.id}'),
        headers: await _getHeaders(),
        body: jsonEncode(facility.toMap()),
      ).timeout(httpTimeout);

      if (response.statusCode == 200) {
        return Facility.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update facility');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Images may be too large. Please compress images.');
    }
  }

  // Delete facility
  static Future<void> deleteFacility(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/facilities/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete facility');
    }
  }
}