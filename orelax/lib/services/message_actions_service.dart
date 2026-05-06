import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class MessageActionsService {
  static Future<Map<String, dynamic>> editMessage({
    required String messageId,
    required String content,
  }) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/messages/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    final decoded = jsonDecode(response.body);
    throw Exception(decoded['message'] ?? 'Failed to edit message');
  }

  static Future<Map<String, dynamic>> deleteMessageForEveryone({
    required String messageId,
  }) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/messages/$messageId?scope=everyone'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    final decoded = jsonDecode(response.body);
    throw Exception(decoded['message'] ?? 'Failed to delete message');
  }
}