import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use your computer's IP for Android emulator, or localhost for Chrome
  static const String baseUrl = 'http://localhost:5000/api';
  
  // For Android emulator, use: 'http://10.0.2.2:5000/api'
  // For physical device, use: 'http://YOUR_COMPUTER_IP:5000/api'
  
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String apartment,
    String role = 'resident',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'apartment': apartment,
        'role': role,
      }),
    );
    
    print('Register response status: ${response.statusCode}');
    print('Register response body: ${response.body}');
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }
  
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user');
    }
  }
  
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String apartment,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'apartment': apartment,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }
  
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to change password');
    }
  }
  
  static Future<void> logout() async {
    await removeToken();
  }

  // ========== CHAT METHODS ==========
  
  // Get all chats for current user
  static Future<List<Map<String, dynamic>>> getChats() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('$baseUrl/chat/chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load chats');
    }
  }
  
  // Get messages for a specific chat
  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('$baseUrl/chat/chats/$chatId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load messages');
    }
  }
  
  // Create a new private chat
  static Future<Map<String, dynamic>> createChat({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final currentUser = await getCurrentUser();
    
    final response = await http.post(
      Uri.parse('$baseUrl/chat/chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'currentUserId': currentUser['id'],
        'currentUserName': currentUser['name'],
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create chat');
    }
  }
  
  // Get chat users for starting a new private conversation
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('$baseUrl/chat/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load users');
    }
  }

  // ========== EVENT METHODS ==========

// Get all approved events
static Future<List<Map<String, dynamic>>> getEvents() async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.get(
    Uri.parse('$baseUrl/events'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load events');
  }
}

// Get user's own events
static Future<List<Map<String, dynamic>>> getMyEvents() async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.get(
    Uri.parse('$baseUrl/events/my-events'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load my events');
  }
}

// Get event by ID
static Future<Map<String, dynamic>> getEventById(String id) async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.get(
    Uri.parse('$baseUrl/events/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load event');
  }
}

// Create new event
static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.post(
    Uri.parse('$baseUrl/events'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(eventData),
  );
  
  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to create event');
  }
}

// Update event
static Future<Map<String, dynamic>> updateEvent(String id, Map<String, dynamic> eventData) async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.put(
    Uri.parse('$baseUrl/events/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(eventData),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to update event');
  }
}

// Cancel event
static Future<void> cancelEvent(String id) async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.delete(
    Uri.parse('$baseUrl/events/$id'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to cancel event');
  }
}
// ========== REPORT METHODS ==========

// Create a new report
static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.post(
    Uri.parse('$baseUrl/reports'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(reportData),
  );
  
  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to submit report');
  }
}

// Get user's own reports
static Future<List<Map<String, dynamic>>> getMyReports() async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.get(
    Uri.parse('$baseUrl/reports/my-reports'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load reports');
  }
}
}