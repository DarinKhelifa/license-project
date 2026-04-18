import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isUploadingMedia = false;
  Timer? _typingTimer;
  
  // Store listener references
  late final Function(dynamic) _newMessageListener;
  late final Function(dynamic) _messageSentListener;
  late final Function(dynamic) _messageErrorListener;
  late final Function(dynamic) _messageReadListener;

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
    ChatService.removeMessageReadListener(_messageReadListener);
    
    super.dispose();
  }

  void _setupSocketListeners() {
    _newMessageListener = (message) {
      if (message['chatId'] == widget.chatId) {
        setState(() {
          if (!_messages.any((m) => m['_id'] == message['_id'])) {
            _messages.add(Map<String, dynamic>.from(message));
          }
        });
        _scrollToBottom();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        ChatService.markAsRead(
          message['_id'],
          authProvider.userId,
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

    _messageReadListener = (data) {
      try {
        final messageId = (data is Map ? data['messageId'] : null)?.toString();
        if (messageId == null) return;

        final index = _messages.indexWhere((m) => m['_id']?.toString() == messageId);
        if (index == -1) return;

        setState(() {
          final updated = Map<String, dynamic>.from(_messages[index]);
          updated['status'] = 'read';
          _messages[index] = updated;
        });
      } catch (_) {
        // ignore
      }
    };
    
    ChatService.addNewMessageListener(_newMessageListener);
    ChatService.addMessageSentListener(_messageSentListener);
    ChatService.addMessageErrorListener(_messageErrorListener);
    ChatService.addMessageReadListener(_messageReadListener);
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getMessages(widget.chatId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _markUnreadMessagesAsRead();
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  void _markUnreadMessagesAsRead() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;
    if (currentUserId == null) return;

    for (final message in _messages) {
      final senderId = message['senderId']?.toString();
      if (senderId == null || senderId == currentUserId) continue;

      final readBy = (message['readBy'] is List) ? List<dynamic>.from(message['readBy']) : const <dynamic>[];
      final isRead = readBy.map((e) => e.toString()).contains(currentUserId);
      if (!isRead && message['_id'] != null) {
        ChatService.markAsRead(message['_id'].toString(), currentUserId, widget.chatId);
      }
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
      senderId: authProvider.userId,
      senderName: authProvider.user?['name'] ?? 'User',
      text: text,
    );
    
    _stopTyping();
  }

  String _guessMimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingMedia) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final senderId = authProvider.userId;
    if (senderId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingMedia = true);
    try {
      final filename = picked.name;
      final mimeType = _guessMimeTypeFromName(filename);
      final dynamic file = kIsWeb ? await picked.readAsBytes() : File(picked.path);

      final uploaded = await ApiService.uploadChatMedia(
        chatId: widget.chatId,
        file: file,
        filename: filename,
        mimeType: mimeType,
      );

      ChatService.sendMessage(
        chatId: widget.chatId,
        senderId: senderId,
        senderName: authProvider.userName ?? 'User',
        text: '',
        type: (uploaded['type'] ?? 'image').toString(),
        mediaUrl: uploaded['mediaUrl']?.toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_isUploadingMedia) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final senderId = authProvider.userId;
    if (senderId == null) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    if (!kIsWeb && picked.path == null) return;
    if (kIsWeb && picked.bytes == null) return;

    setState(() => _isUploadingMedia = true);
    try {
      final filename = picked.name;
      final mimeType = _guessMimeTypeFromName(filename);
      final dynamic file = kIsWeb ? picked.bytes! : File(picked.path!);

      final uploaded = await ApiService.uploadChatMedia(
        chatId: widget.chatId,
        file: file,
        filename: filename,
        mimeType: mimeType,
      );

      ChatService.sendMessage(
        chatId: widget.chatId,
        senderId: senderId,
        senderName: authProvider.userName ?? 'User',
        text: filename,
        type: (uploaded['type'] ?? 'file').toString(),
        mediaUrl: uploaded['mediaUrl']?.toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  void _onTyping() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!_isTyping) {
      _isTyping = true;
      ChatService.sendTyping(widget.chatId, authProvider.userId, true);
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
      ChatService.sendTyping(widget.chatId, authProvider.userId, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userId;
    final otherUserId = widget.otherUser['id']?.toString();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: Text(
                    (widget.otherUser['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder(
                    valueListenable: ChatService.onlineUserIdsListenable,
                    builder: (context, onlineIds, _) {
                      final isOnline = otherUserId != null && onlineIds.contains(otherUserId);
                      return Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.greenAccent : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF034808), width: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser['name'] ?? 'User', maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  ValueListenableBuilder(
                    valueListenable: ChatService.onlineUserIdsListenable,
                    builder: (context, onlineIds, _) {
                      final isOnline = otherUserId != null && onlineIds.contains(otherUserId);
                      return Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      );
                    },
                  ),
                ],
              ),
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
          IconButton(
            onPressed: _isUploadingMedia ? null : _pickAndSendImage,
            icon: const Icon(Icons.photo, color: Color(0xFF034808)),
            tooltip: 'Send image',
          ),
          IconButton(
            onPressed: _isUploadingMedia ? null : _pickAndSendFile,
            icon: const Icon(Icons.attach_file, color: Color(0xFF034808)),
            tooltip: 'Send file',
          ),
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
              onPressed: _isUploadingMedia ? null : _sendMessage,
              icon: _isUploadingMedia
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white),
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
    final type = (message['type'] ?? 'text').toString();
    final mediaUrl = message['mediaUrl']?.toString();
    
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
            if (type == 'image' && mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaUrl,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 220,
                      height: 140,
                      color: isMe ? Colors.white.withOpacity(0.12) : Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image, color: isMe ? Colors.white70 : Colors.grey.shade700),
                    );
                  },
                ),
              )
            else if (type == 'file' && mediaUrl != null)
              InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(mediaUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file, size: 16, color: isMe ? Colors.white : Colors.black87),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        (message['text'] ?? 'Attachment').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                (message['text'] ?? '').toString(),
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
                  if (message['status'] == 'read') ...[
                    const SizedBox(width: 4),
                    const Text(
                      'Vu',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}