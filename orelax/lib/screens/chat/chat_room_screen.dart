import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> otherUser;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  Timer? _typingTimer;
  
  // Store listener references
  late final Function(dynamic) _newMessageListener;
  late final Function(dynamic) _messageSentListener;
  late final Function(dynamic) _messageErrorListener;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    
    // Remove listeners
    ChatService.removeNewMessageListener(_newMessageListener);
    ChatService.removeMessageSentListener(_messageSentListener);
    ChatService.removeMessageErrorListener(_messageErrorListener);
    
    super.dispose();
  }

  void _setupSocketListeners() {
    _newMessageListener = (message) {
      if (message['chatId'] == widget.chatId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        ChatService.markAsRead(
          message['_id'],
          authProvider.user?['id'],
          widget.chatId,
        );
      }
    };
    
    _messageSentListener = (message) {
      if (message['chatId'] == widget.chatId) {
        setState(() {
          // Check if message already exists to avoid duplicates
          if (!_messages.any((m) => m['_id'] == message['_id'])) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
      }
    };
    
    _messageErrorListener = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${error['error'] ?? error}')),
        );
      }
    };
    
    ChatService.addNewMessageListener(_newMessageListener);
    ChatService.addMessageSentListener(_messageSentListener);
    ChatService.addMessageErrorListener(_messageErrorListener);
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getMessages(widget.chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final text = _messageController.text.trim();
    _messageController.clear();
    
    ChatService.sendMessage(
      chatId: widget.chatId,
      senderId: authProvider.user?['id'],
      senderName: authProvider.user?['name'] ?? 'User',
      text: text,
    );
    
    _stopTyping();
  }

  void _onTyping() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!_isTyping) {
      _isTyping = true;
      ChatService.sendTyping(widget.chatId, authProvider.user?['id'], true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      _stopTyping();
    });
  }
  
  void _stopTyping() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (_isTyping) {
      _isTyping = false;
      ChatService.sendTyping(widget.chatId, authProvider.user?['id'], false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?['id'];
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser['name']),
            const SizedBox(height: 2),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 5)),
              builder: (context, snapshot) {
                return Text(
                  'Online', // This would be connected to real online status
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No messages yet'),
                            Text('Say hello to your neighbor!'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderId'] == currentUserId;
                          
                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (_) => _onTyping(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF034808),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.parse(message['createdAt']);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF034808) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['text'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message['status'] == 'read' ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message['status'] == 'read' ? Colors.white70 : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}