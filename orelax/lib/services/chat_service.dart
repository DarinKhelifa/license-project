import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  static IO.Socket? socket;
  static String? currentUserId;
  
  // Change to lists of listeners
  static final List<Function(dynamic)> _newMessageListeners = [];
  static final List<Function(dynamic)> _messageSentListeners = [];
  static final List<Function(dynamic)> _messageErrorListeners = [];
  static final List<Function(dynamic)> _usersOnlineListeners = [];
  static final List<Function(dynamic)> _messageReadListeners = [];
  static final List<Function(dynamic)> _userTypingListeners = [];
  
  static bool _isConnecting = false;
  static bool _isReconnecting = false;

  static bool get isConnected => socket != null && socket!.connected;

  // Add listener methods
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

  static Future<void> connect(String userId) async {
    if (currentUserId == userId && isConnected) {
      print('🔄 ChatService already connected for user $userId');
      return;
    }

    if (_isConnecting) {
      print('⏳ ChatService connection already in progress');
      return;
    }

    _isConnecting = true;

    if (socket != null) {
      socket?.disconnect();
      socket?.clearListeners();
      socket = null;
    }

    currentUserId = userId;
    
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 10,
    });
    
    socket?.on('connect', (_) {
      _isConnecting = false;
      _isReconnecting = false;
      print('✅ Socket connected: ${socket?.id}');
      socket?.emit('user-connected', userId);
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
    
    socket?.on('disconnect', (_) {
      print('🔌 Socket disconnected');
      _isConnecting = false;
      _isReconnecting = true;
      
      // Attempt to reconnect
      Future.delayed(const Duration(seconds: 2), () {
        if (currentUserId != null && !isConnected) {
          print('🔄 Attempting to reconnect...');
          _reconnect();
        }
      });
    });
    
    socket?.on('connect_error', (error) {
      print('❌ Socket connection error: $error');
      _isConnecting = false;
    });
    
    socket?.on('reconnect', (_) {
      print('🔄 Socket reconnected');
      if (currentUserId != null) {
        socket?.emit('user-connected', currentUserId);
      }
    });
  }
  
  static Future<void> _reconnect() async {
    if (currentUserId != null && !isConnected && !_isConnecting) {
      await connect(currentUserId!);
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
    
    // Try to reconnect if not connected
    if (!isConnected) {
      print('⚠️ Socket not connected, attempting to reconnect...');
      await _reconnect();
      
      // Wait a bit for connection
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!isConnected) {
        print('❌ Cannot send message: socket still not connected');
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
    
    socket?.disconnect();
    socket = null;
    currentUserId = null;
    _isConnecting = false;
    _isReconnecting = false;
  }
}