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
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isUsersLoading = true;
  
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
    await Future.wait([
      _loadChats(),
      _loadUsers(),
    ]);
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

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getAllUsers();
      setState(() {
        _users = users;
        _isUsersLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isUsersLoading = false);
    }
  }

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.serverUrl}$trimmed';
    return trimmed;
  }

  Widget _chatAvatar({
    required String? userId,
    required String displayName,
    String? avatarUrl,
  }) {
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final resolvedUrl = _resolveAvatarUrl(avatarUrl);
    final imageProvider = (resolvedUrl != null)
        ? NetworkImage(resolvedUrl)
        : null;

    return Stack(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF034808),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder(
            valueListenable: ChatService.onlineUserIdsListenable,
            builder: (context, onlineIds, _) {
              final isOnline = userId != null && onlineIds.contains(userId);
              return Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.greenAccent : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
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

  Future<void> _openOrCreateChatWithUser(Map<String, dynamic> user) async {
    try {
      final otherUserId = (user['id'] ?? user['_id'])?.toString();
      final otherUserName = (user['name'] ?? 'User').toString();
      if (otherUserId == null || otherUserId.isEmpty) return;

      final chat = await ApiService.createChat(
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      );
      await _loadChats();
      if (!mounted) return;
      _openChat(chat);
    } catch (e) {
      print('Failed to open chat with user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open chat. Please try again.')),
        );
      }
    }
  }

  Widget _availableUsersRow() {
    if (_isUsersLoading) {
      return const SizedBox(
        height: 92,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_users.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 98,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: _users.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return InkWell(
              onTap: _startNewChat,
              borderRadius: BorderRadius.circular(999),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF034808),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text('New', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            );
          }

          final user = _users[index];
          final userId = (user['id'] ?? user['_id'])?.toString();
          final name = (user['name'] ?? 'User').toString();
          final avatarUrl = _resolveAvatarUrl(user['profileImage']?.toString());

          return InkWell(
            onTap: () => _openOrCreateChatWithUser(user),
            borderRadius: BorderRadius.circular(999),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chatAvatar(
                  userId: userId,
                  displayName: name,
                  avatarUrl: avatarUrl,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 62,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _availableUsersRow(),
                const Divider(height: 1),
                Expanded(
                  child: _chats.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No messages yet'),
                              SizedBox(height: 8),
                              Text('Tap a user above to start chatting'),
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
                            final participantAvatars = List<String>.from(chat['participantAvatars'] ?? const <String>[]);
                            final otherParticipantIndex = (currentUserId != null && participants.isNotEmpty && participants[0] == currentUserId) ? 1 : 0;
                            final otherName = participantNames.isNotEmpty ? participantNames[otherParticipantIndex] : 'User';
                            final otherUserId = participants.isNotEmpty ? participants[otherParticipantIndex] : null;
                            final otherAvatarUrl = participantAvatars.isNotEmpty && participantAvatars.length > otherParticipantIndex
                                ? participantAvatars[otherParticipantIndex]
                                : null;

                            final unreadMap = (chat['unreadCount'] is Map)
                                ? (chat['unreadCount'] as Map).cast<String, dynamic>()
                                : <String, dynamic>{};
                            final dynamic unreadValue = currentUserId == null ? 0 : unreadMap[currentUserId] ?? 0;
                            final unreadCount = (unreadValue is num) ? unreadValue.toInt() : 0;
                            final isFromMe = currentUserId != null && chat['lastMessageSenderId'] == currentUserId;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: _chatAvatar(
                                userId: otherUserId,
                                displayName: otherName,
                                avatarUrl: otherAvatarUrl,
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
                ),
              ],
            ),
    );
  }
}