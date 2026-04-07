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
    final currentUserId = authProvider.user?['id'];
    
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
    final currentUserId = authProvider.user?['id'];
    
    final otherParticipantIndex = chat['participants'][0] == currentUserId ? 1 : 0;
    final otherUser = {
      'id': chat['participants'][otherParticipantIndex],
      'name': chat['participantNames'][otherParticipantIndex],
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
    final currentUserId = authProvider.user?['id'];
    
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
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final otherParticipantIndex = chat['participants'][0] == currentUserId ? 1 : 0;
                    final otherName = chat['participantNames'][otherParticipantIndex];
                    final unreadCount = chat['unreadCount']?[currentUserId] ?? 0;
                    final isFromMe = chat['lastMessageSenderId'] == currentUserId;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF034808),
                        child: Text(otherName[0].toUpperCase()),
                      ),
                      title: Text(
                        otherName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isFromMe ? 'You: ${chat['lastMessage']}' : chat['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(chat['lastMessageTime']),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF034808),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
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