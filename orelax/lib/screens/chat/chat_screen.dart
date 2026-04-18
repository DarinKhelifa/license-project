import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/api_service.dart';
import 'chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  
  // Store listener reference for cleanup
  late final Function(dynamic) _newMessageListener;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    ChatService.removeNewMessageListener(_newMessageListener);
    super.dispose();
  }

  Future<void> _initChat() async {
    _setupSocketListeners();
    await _loadChats();
  }

  void _setupSocketListeners() {
    // Create the listener
    _newMessageListener = (message) {
      _loadChats(); // Refresh chat list when new message arrives

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userId;
      final senderId = message is Map ? message['senderId']?.toString() : null;

      if (currentUserId != null && senderId != null && senderId != currentUserId) {
        final preview = (message['text'] ?? 'New message').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    };
    
    // Add listener instead of replacing
    ChatService.addNewMessageListener(_newMessageListener);
  }

  Future<void> _loadChats() async {
    try {
      final chats = await ApiService.getChats();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startNewChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;
    
    // Get all users except current user
    final users = await ApiService.getAllUsers();
    final otherUsers = users.where((u) => u['id'] != currentUserId).toList();
    
    final selectedUser = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF034808),
                  child: Text(user['name'][0].toUpperCase()),
                ),
                title: Text(user['name']),
                subtitle: Text(user['role'] ?? 'Resident'),
                onTap: () => Navigator.pop(context, user),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (selectedUser != null) {
      try {
        final otherUserId = selectedUser['id'] ?? selectedUser['_id'];
        final chat = await ApiService.createChat(
          otherUserId: otherUserId,
          otherUserName: selectedUser['name'],
        );
        await _loadChats();
        _openChat(chat);
      } catch (e) {
        print('Failed to start new chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start chat. Please try again.')),
          );
        }
      }
    }
  }

  void _openChat(Map<String, dynamic> chat) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;
    
    if (currentUserId == null) return;

    final participants = List<String>.from(chat['participants'] ?? const <String>[]);
    final participantNames = List<String>.from(chat['participantNames'] ?? const <String>[]);

    final otherParticipantIndex = participants.isNotEmpty && participants[0] == currentUserId ? 1 : 0;
    final otherUser = {
      'id': participants[otherParticipantIndex],
      'name': participantNames[otherParticipantIndex],
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatId: chat['_id'],
          otherUser: otherUser,
        ),
      ),
    ).then((_) => _loadChats());
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return '';
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}d';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.userId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF034808),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _startNewChat,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No messages yet'),
                      SizedBox(height: 8),
                      Text('Start a conversation with your neighbors'),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final participants = List<String>.from(chat['participants'] ?? const <String>[]);
                    final participantNames = List<String>.from(chat['participantNames'] ?? const <String>[]);
                    final otherParticipantIndex = (currentUserId != null && participants.isNotEmpty && participants[0] == currentUserId) ? 1 : 0;
                    final otherName = participantNames.isNotEmpty ? participantNames[otherParticipantIndex] : 'User';

                    final unreadMap = (chat['unreadCount'] is Map)
                        ? (chat['unreadCount'] as Map).cast<String, dynamic>()
                        : <String, dynamic>{};
                    final dynamic unreadValue = currentUserId == null ? 0 : unreadMap[currentUserId] ?? 0;
                    final unreadCount = (unreadValue is num) ? unreadValue.toInt() : 0;
                    final isFromMe = currentUserId != null && chat['lastMessageSenderId'] == currentUserId;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF034808),
                        child: Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?'),
                      ),
                      title: Text(
                        otherName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isFromMe ? 'You: ${chat['lastMessage'] ?? ''}' : (chat['lastMessage'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(chat['lastMessageTime']?.toString()),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF034808),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      onTap: () => _openChat(chat),
                    );
                  },
                ),
    );
  }
}