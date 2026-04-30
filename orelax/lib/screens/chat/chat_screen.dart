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

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  bool _isUsersLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  
  late AnimationController _searchAnimationController;
  late Animation<double> _searchFadeAnimation;
  late Animation<Offset> _searchSlideAnimation;
  
  // Store listener reference for cleanup
  late final Function(dynamic) _newMessageListener;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );

    _searchSlideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );

    _initChat();
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
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
        _filteredUsers = users;
        _isUsersLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isUsersLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _users.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          // Match by first letter or full name
          return name.startsWith(lowerQuery) || name.contains(lowerQuery);
        }).toList();
      }
    });
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
    int unreadCount = 0,
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
        // Unread badge on top-right
        if (unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF0B7A3D),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
        title: const Text(
          'New Message',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.separated(
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              final userInitial = (user['name'] as String).isNotEmpty
                  ? (user['name'] as String)[0].toUpperCase()
                  : '?';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0B7A3D),
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  user['name'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final usersToShow = _isSearching ? _filteredUsers : _users;
    
    if (usersToShow.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            _isSearching ? 'No users found' : '',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          scrollDirection: Axis.horizontal,
          itemCount: usersToShow.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            if (index == usersToShow.length) {
              return HoverAvatarButton(
                onTap: _startNewChat,
                isAddButton: true,
              );
            }

            final user = usersToShow[index];
            final userId = (user['id'] ?? user['_id'])?.toString();
            final name = (user['name'] ?? 'User').toString();
            final avatarUrl = _resolveAvatarUrl(user['profileImage']?.toString());
            final displayName = name.length > 10 ? '${name.substring(0, 10)}...' : name;

            return HoverAvatarButton(
              userId: userId,
              displayName: displayName,
              avatarUrl: avatarUrl,
              fullName: name,
              onTap: () => _openOrCreateChatWithUser(user),
            );
          },
        ),
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isSearching)
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.0).animate(
                CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
              ),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() => _isSearching = true);
                  _searchAnimationController.forward();
                },
              ),
            )
          else
            SlideTransition(
              position: _searchSlideAnimation,
              child: FadeTransition(
                opacity: _searchFadeAnimation,
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _filteredUsers = _users;
                            });
                            _searchAnimationController.reverse();
                          },
                        ),
                      ),
                      onChanged: _filterUsers,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Available users horizontal scroll
                _availableUsersRow(),
                
                // Chats header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                // Chat list
                Expanded(
                  child: _chats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/no-message.png',
                                height: 180,
                                width: 180,
                              ),
                              const SizedBox(height: 40),
                              const Text(
                                'Welcome to Chat!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'Feel free to start a new conversation\nby tapping the button below.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _startNewChat,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text(
                                  'Start New Chat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8B4A8),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _chats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                            final lastMessage = chat['lastMessage'] ?? '';
                            final displayMessage = isFromMe ? '✓ $lastMessage' : lastMessage;
                            
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openChat(chat),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      _chatAvatar(
                                        userId: otherUserId,
                                        displayName: otherName,
                                        avatarUrl: otherAvatarUrl,
                                        unreadCount: unreadCount,
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Name and message
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              otherName,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              displayMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: unreadCount > 0 ? Colors.black54 : Colors.grey.shade600,
                                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Time and unread badge
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatTime(chat['lastMessageTime']?.toString()),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (unreadCount > 0) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0B7A3D),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _chats.isNotEmpty
          ? FloatingActionButton(
              onPressed: _startNewChat,
              backgroundColor: const Color(0xFF0B7A3D),
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
    );
  }
}

// Hover Avatar Button Widget with animation
class HoverAvatarButton extends StatefulWidget {
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
  final String? fullName;
  final VoidCallback onTap;
  final bool isAddButton;

  const HoverAvatarButton({
    super.key,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.fullName,
    required this.onTap,
    this.isAddButton = false,
  });

  @override
  State<HoverAvatarButton> createState() => _HoverAvatarButtonState();
}

class _HoverAvatarButtonState extends State<HoverAvatarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _shadowAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isAddButton)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.grey,
                      size: 28,
                    ),
                  )
                else
                  _buildAvatar(),
                const SizedBox(height: 8),
                SizedBox(
                  width: 56,
                  child: Text(
                    widget.displayName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = (widget.fullName?.isNotEmpty ?? false)
        ? widget.fullName![0].toUpperCase()
        : '?';

    final resolvedUrl = _resolveAvatarUrl(widget.avatarUrl);
    final imageProvider =
        (resolvedUrl != null) ? NetworkImage(resolvedUrl) : null;

    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF0B7A3D),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ))
              : null,
        ),
      ],
    );
  }

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
      return trimmed;
    if (trimmed.startsWith('/'))
      return '${ApiService.serverUrl}$trimmed';
    return trimmed;
  }
}