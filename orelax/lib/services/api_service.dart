import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Server URL
  // - Web: localhost
  // - Android emulator: 10.0.2.2
  // - Physical device: replace with your computer IP
  static String get serverUrl => kIsWeb ? 'http://localhost:5001' : 'http://10.0.2.2:5001';
  static String get baseUrl => '$serverUrl/api';

  static MediaType _parseMediaType(String? mimeType) {
    if (mimeType == null || !mimeType.contains('/')) {
      return MediaType('application', 'octet-stream');
    }
    final parts = mimeType.split('/');
    return MediaType(parts[0], parts[1]);
  }
  
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
    String? residence,
    String? building,
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
        'residence': residence ?? null,
        'building': building ?? null,
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

  // Get list of residences (public endpoint)
  static Future<List<Map<String, dynamic>>> getResidences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/residences'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['residences'] ?? []);
    } else {
      throw Exception('Failed to load residences');
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
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed: ${response.statusCode}');
      } catch (e) {
        // If response body is not JSON or empty, include raw body for debugging
        final bodyPreview = (response.body ?? '').toString();
        throw Exception('Login failed: ${response.statusCode} - $bodyPreview');
      }
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
      try {
        return jsonDecode(response.body);
      } catch (_) {
        throw Exception('Failed to parse user response');
      }
    } else if (response.statusCode == 401) {
      // Token invalid/expired
      await removeToken();
      throw Exception('Not authenticated');
    } else {
      final body = response.body ?? '';
      throw Exception('Failed to get user: ${response.statusCode} - $body');
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

  // Update profile with photo upload (supports web and native platforms)
  static Future<Map<String, dynamic>> updateProfileWithPhoto({
    required String name,
    required String phone,
    required String apartment,
    dynamic photoFile, // Can be File (native) or Uint8List (web)
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/auth/profile'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['phone'] = phone;
    request.fields['apartment'] = apartment;

    // Add photo if provided
    if (photoFile != null) {
      if (kIsWeb) {
        // Web: handle Uint8List
        if (photoFile is Uint8List) {
          request.files.add(http.MultipartFile.fromBytes(
            'profileImage',
            photoFile,
            filename: 'profile_photo.jpg',
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      } else {
        // Native: assume an object with a `path` property (e.g., File)
        try {
          final path = (photoFile as dynamic).path as String;
          request.files.add(await http.MultipartFile.fromPath(
            'profileImage',
            path,
            contentType: MediaType('image', 'jpeg'),
          ));
        } catch (_) {
          // If path unavailable, skip attaching the file on native
        }
      }
    }

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Profile update error: $e');
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

  // ========== SECURITY NOTE METHODS ==========

  static Future<List<Map<String, dynamic>>> getSecurityNotes() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/security-notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }

    throw Exception('Failed to load security notes');
  }

  static Future<Map<String, dynamic>> createSecurityNote({
    required String title,
    required String content,
    DateTime? reminder,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/security-notes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'reminder': reminder?.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to create security note');
  }

  static Future<Map<String, dynamic>> updateSecurityNote({
    required String noteId,
    required String title,
    required String content,
    DateTime? reminder,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/security-notes/$noteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'reminder': reminder?.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to update security note');
  }

  static Future<void> deleteSecurityNote(String noteId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/security-notes/$noteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete security note');
    }
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
    final currentUserId = (currentUser['_id'] ?? currentUser['id'])?.toString();
    final currentUserName = (currentUser['name'] ?? '').toString();
    
    final response = await http.post(
      Uri.parse('$baseUrl/chat/chats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'currentUserId': currentUserId,
        'currentUserName': currentUserName,
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

  // Upload chat media (image/file). Returns { mediaUrl, type, originalName, ... }
  // `file` can be `File` (native) or `Uint8List` (web).
  static Future<Map<String, dynamic>> uploadChatMedia({
    required String chatId,
    required dynamic file,
    required String filename,
    String? mimeType,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/chat/chats/$chatId/media'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final contentType = _parseMediaType(mimeType);

    if (kIsWeb) {
      if (file is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file,
          filename: filename,
          contentType: contentType,
        ));
      } else {
        throw Exception('Invalid file type for web upload');
      }
    } else {
      if (file != null && file is! Uint8List && (file as dynamic).path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          (file as dynamic).path,
          filename: filename,
          contentType: contentType,
        ));
      } else {
        throw Exception('Invalid file type for native upload');
      }
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Upload failed');
    } catch (_) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> editChatMessage({
    required String messageId,
    required String content,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to edit message');
    } catch (_) {
      throw Exception('Failed to edit message: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> deleteChatMessage({
    required String messageId,
    bool forEveryone = true,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/messages/$messageId${forEveryone ? '?scope=everyone' : ''}');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'messageId': messageId};
      }
    }

    try {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete message');
    } catch (_) {
      throw Exception('Failed to delete message: ${response.statusCode}');
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

// Get reports for security/maintenance role
static Future<List<Map<String, dynamic>>> getReportsForRole() async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.get(
    Uri.parse('$baseUrl/reports/admin/all'),
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

// Update report status
static Future<void> updateReportStatus(String reportId, String status) async {
  final token = await getToken();
  if (token == null) throw Exception('Not authenticated');
  
  final response = await http.put(
    Uri.parse('$baseUrl/reports/$reportId/status'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'status': status}),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to update status');
  }
}

// ========== ENVIRONMENT METHODS ==========

  static Future<List<Map<String, dynamic>>> getEnvironmentCurrent() async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/environment/current'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load environment readings');
    }
  }
  // Get all guests (admin/security)
  static Future<List<Map<String, dynamic>>> getAllGuests() async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/guests/admin/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['guests'] ?? jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guests');
    }
  }

  // Get guests for a resident
  static Future<List<Map<String, dynamic>>> getGuestsForResident(String residentId) async {
    final token = await ApiService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/guests/resident/$residentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(json['guests'] ?? []);
    } else {
      throw Exception('Failed to load guest list');
    }
  }

  // Block a user in a chat
  static Future<Map<String, dynamic>> blockUserInChat(String chatId, String userId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/chat/chats/$chatId/block/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to block user');
    }
  }

  // Unblock a user in a chat
  static Future<Map<String, dynamic>> unblockUserInChat(String chatId, String userId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/chat/chats/$chatId/unblock/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to unblock user');
    }
  }

}