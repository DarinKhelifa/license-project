import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';

class EmployeeApiService {
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

  // Get all employees
  static Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/employees'),
            headers: await _getHeaders(),
          )
          .timeout(httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final employees = (data['employees'] as List?)
                ?.map((json) => Employee.fromMap(json))
                .toList() ??
            [];
        return employees;
      } else {
        throw Exception('Failed to load employees');
      }
    } on TimeoutException {
      throw Exception('Request timeout while loading employees');
    } catch (e) {
      rethrow;
    }
  }

  // Create employee with file uploads
  static Future<Employee> createEmployee({
    required String firstName,
    required String lastName,
    required String cinId,
    required String address,
    required String phone,
    required String email,
    required String workCategory,
    required String experience,
    File? photo,
    File? casierJudiciaire,
  }) async {
    try {
      final token = await _getToken();
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/employees'));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['cinId'] = cinId;
      request.fields['address'] = address;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      request.fields['workCategory'] = workCategory;
      request.fields['experience'] = experience;

      // Add files
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType('image', photo.path.split('.').last),
        ));
      }

      if (casierJudiciaire != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'casierJudiciaire',
          casierJudiciaire.path,
          contentType: MediaType('application', 'pdf'),
        ));
      }

      final streamedResponse = await request.send().timeout(httpTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Employee.fromMap(data['employee']);
      } else {
        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');

        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to create employee');
        } catch (e) {
          throw Exception('Failed to create employee: ${response.body}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timeout while creating employee');
    } catch (e) {
      rethrow;
    }
  }

  // Delete employee
  static Future<void> deleteEmployee(String employeeId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/employees/$employeeId'),
            headers: await _getHeaders(),
          )
          .timeout(httpTimeout);

      if (response.statusCode != 200) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to delete employee');
        } catch (e) {
          throw Exception('Failed to delete employee: ${response.body}');
        }
      }
    } on TimeoutException {
      throw Exception('Request timeout while deleting employee');
    } catch (e) {
      rethrow;
    }
  }

  // Get image URL
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Replace localhost with internal IP if needed for physical devices
    return '$baseUrl/uploads/$path'.replaceAll('/api/uploads/', '/uploads/');
  }
}
