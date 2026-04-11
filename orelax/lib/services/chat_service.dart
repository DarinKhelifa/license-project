import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatService {
  static IO.Socket? socket;
  static String? currentUserId;
  static String? currentUserRole;
  
  // Listeners
  static final List<Function(dynamic)> _newMessageListeners = [];
  static final List<Function(dynamic)> _messageSentListeners = [];
  static final List<Function(dynamic)> _messageErrorListeners = [];
  static final List<Function(dynamic)> _usersOnlineListeners = [];
  static final List<Function(dynamic)> _messageReadListeners = [];
  static final List<Function(dynamic)> _userTypingListeners = [];
  static final List<Function(dynamic)> _newAlertListeners = [];
  static final List<Function(dynamic)> _alertStatusUpdateListeners = [];
  
  static bool _isConnecting = false;
  static int _reconnectAttempts = 0;

  static bool get isConnected => socket != null && socket!.connected;
  
  // Get the correct server URL based on platform
  static String get _serverUrl {
    if (kIsWeb) {
      // For web, use localhost (same as your backend)
      return 'http://localhost:5000';
    } else {
      // For mobile emulator
      return 'http://10.0.2.2:5000';
    }
  }

  // Alert listeners
  static void addNewAlertListener(Function(dynamic) listener) {
    if (!_newAlertListeners.contains(listener)) {
      _newAlertListeners.add(listener);
    }
  }
  
  static void removeNewAlertListener(Function(dynamic) listener) {
    _newAlertListeners.remove(listener);
  }
  
  static void addAlertStatusUpdateListener(Function(dynamic) listener) {
    if (!_alertStatusUpdateListeners.contains(listener)) {
      _alertStatusUpdateListeners.add(listener);
    }
  }
  
  static void removeAlertStatusUpdateListener(Function(dynamic) listener) {
    _alertStatusUpdateListeners.remove(listener);
  }

  // Existing listeners
  static void addNewMessageListener(Function(dynamic) listener) {
    if (!_newMessageListeners.contains(listener)) {
      _newMessageListeners.add(listener);
    }
  }
  
  static void removeNewMessageListener(Function(dynamic) listener) {
    _newMessageListeners.remove(listener);
  }
  
  static void addMessageSentListener(Function(dynamic) listener) {
    if (!_messageSentListeners.contains(listener)) {
      _messageSentListeners.add(listener);
    }
  }
  
  static void removeMessageSentListener(Function(dynamic) listener) {
    _messageSentListeners.remove(listener);
  }
  
  static void addMessageErrorListener(Function(dynamic) listener) {
    if (!_messageErrorListeners.contains(listener)) {
      _messageErrorListeners.add(listener);
    }
  }
  
  static void removeMessageErrorListener(Function(dynamic) listener) {
    _messageErrorListeners.remove(listener);
  }
  
  static void addMessageReadListener(Function(dynamic) listener) {
    if (!_messageReadListeners.contains(listener)) {
      _messageReadListeners.add(listener);
    }
  }
  
  static void removeMessageReadListener(Function(dynamic) listener) {
    _messageReadListeners.remove(listener);
  }
  
  static void addUserTypingListener(Function(dynamic) listener) {
    if (!_userTypingListeners.contains(listener)) {
      _userTypingListeners.add(listener);
    }
  }
  
  static void removeUserTypingListener(Function(dynamic) listener) {
    _userTypingListeners.remove(listener);
  }

  static Future<void> connect(String userId, {String? role}) async {
    if (currentUserId == userId && isConnected) {
      print('🔄 ChatService already connected for user $userId');
      return;
    }

    if (_isConnecting) {
      print('⏳ ChatService connection already in progress');
      return;
    }

    _isConnecting = true;
    _reconnectAttempts = 0;

    if (socket != null) {
      socket?.disconnect();
      socket?.clearListeners();
      socket = null;
    }

    currentUserId = userId;
    currentUserRole = role;
    
    print('🔌 Attempting to connect to $_serverUrl with role: $role');
    print('🔌 Platform: ${kIsWeb ? "Web" : "Mobile"}');
    
    try {
      // Configure socket options
      socket = IO.io(_serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 20,
        'timeout': 20000,
        'forceNew': true,  // Add this
        'multiplex': false, // Add this
      });
      
      socket?.on('connect', (_) {
        _isConnecting = false;
        _reconnectAttempts = 0;
        print('✅ Socket connected: ${socket?.id}');
        print('✅ Socket connected to $_serverUrl');
        socket?.emit('user-connected', { 'userId': userId, 'role': role });
        _sendPendingMessages();
      });
      
      socket?.on('new-message', (data) {
        print('📩 New message received: $data');
        for (var listener in _newMessageListeners) {
          listener(data);
        }
      });

      socket?.on('message-sent', (data) {
        print('✅ Message sent ack: $data');
        for (var listener in _messageSentListeners) {
          listener(data);
        }
      });

      socket?.on('message-error', (data) {
        print('❌ Message error: $data');
        for (var listener in _messageErrorListeners) {
          listener(data);
        }
      });

      socket?.on('users-online', (data) {
        print('👥 Users online: $data');
        for (var listener in _usersOnlineListeners) {
          listener(data);
        }
      });
      
      socket?.on('message-read', (data) {
        print('📖 Message read: $data');
        for (var listener in _messageReadListeners) {
          listener(data);
        }
      });
      
      socket?.on('user-typing', (data) {
        for (var listener in _userTypingListeners) {
          listener(data);
        }
      });
      
      // Alert listeners
      socket?.on('new-alert', (data) {
        print('🔔 New alert received: $data');
        for (var listener in _newAlertListeners) {
          listener(data);
        }
      });
      
      socket?.on('alert-status-updated', (data) {
        print('📢 Alert status updated: $data');
        for (var listener in _alertStatusUpdateListeners) {
          listener(data);
        }
      });
      
      socket?.on('disconnect', (reason) {
        print('🔌 Socket disconnected. Reason: $reason');
        _isConnecting = false;
      });
      
      socket?.on('connect_error', (error) {
        print('❌ Socket connection error: $error');
        _isConnecting = false;
        print('❌ Make sure your backend is running on $_serverUrl');
      });
      
      socket?.on('reconnect_attempt', (attempt) {
        print('🔄 Reconnection attempt #$attempt');
        _reconnectAttempts = attempt;
      });
      
      socket?.on('reconnect', (_) {
        print('🔄 Socket reconnected successfully');
        if (currentUserId != null) {
          socket?.emit('user-connected', { 'userId': currentUserId, 'role': currentUserRole });
        }
        _sendPendingMessages();
      });
      
      socket?.on('reconnect_failed', (_) {
        print('❌ Reconnection failed after all attempts');
        _isConnecting = false;
      });
      
    } catch (e) {
      print('❌ Error creating socket connection: $e');
      _isConnecting = false;
    }
  }
  
  static void sendMessage({
    required String chatId,
    required String? senderId,
    required String senderName,
    required String text,
    String type = 'text',
  }) async {
    if (senderId == null) {
      print('❌ Cannot send message: senderId is null');
      return;
    }
    
    if (!isConnected) {
      print('⚠️ Socket not connected, attempting to reconnect before sending...');
      
      if (!_isConnecting) {
        await connect(senderId, role: currentUserRole);
      }
      
      // Wait a bit for connection
      int attempts = 0;
      while (!isConnected && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
      
      if (!isConnected) {
        print('❌ Cannot send message: socket still not connected after waiting');
        _storePendingMessage(chatId, senderId, senderName, text, type);
        return;
      }
    }
    
    print('📤 Sending message to chat $chatId: $text');
    socket!.emit('send-message', {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
    });
  }
  
  static final List<Map<String, dynamic>> _pendingMessages = [];
  
  static void _storePendingMessage(String chatId, String senderId, String senderName, String text, String type) {
    _pendingMessages.add({
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
    });
    print('📦 Message stored for later delivery. Pending: ${_pendingMessages.length}');
  }
  
  static void _sendPendingMessages() {
    if (isConnected && _pendingMessages.isNotEmpty) {
      print('📤 Sending ${_pendingMessages.length} pending messages...');
      final messages = List<Map<String, dynamic>>.from(_pendingMessages);
      _pendingMessages.clear();
      
      for (var message in messages) {
        socket!.emit('send-message', message);
      }
    }
  }
  
  static void markAsRead(String messageId, String? userId, String chatId) {
    if (userId == null || !isConnected) return;
    
    socket?.emit('mark-read', {
      'messageId': messageId,
      'userId': userId,
      'chatId': chatId,
    });
  }
  
  static void sendTyping(String chatId, String? userId, bool isTyping) {
    if (userId == null || !isConnected) return;
    
    socket?.emit('typing', {
      'chatId': chatId,
      'userId': userId,
      'isTyping': isTyping,
    });
  }
  
  static void disconnect() {
    _newMessageListeners.clear();
    _messageSentListeners.clear();
    _messageErrorListeners.clear();
    _usersOnlineListeners.clear();
    _messageReadListeners.clear();
    _userTypingListeners.clear();
    _newAlertListeners.clear();
    _alertStatusUpdateListeners.clear();
    _pendingMessages.clear();
    
    if (socket != null) {
      socket?.disconnect();
      socket?.clearListeners();
      socket = null;
    }
    currentUserId = null;
    currentUserRole = null;
    _isConnecting = false;
    _reconnectAttempts = 0;
  }
}