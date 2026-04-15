import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnergyService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> getCurrentReadings() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/energy/current'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load energy data');
    }
  }

  static Future<Map<String, dynamic>> getHistoricalData({
    String? deviceId,
    int days = 7,
  }) async {
    final token = await getToken();
    final url = '$baseUrl/energy/historical?days=$days${deviceId != null ? '&deviceId=$deviceId' : ''}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load historical data');
    }
  }
}