import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import 'individual_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Chatservice chatservice = Chatservice();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 10,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.maybePop(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        title: const Text(
          'messages',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[100],
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value.trim();
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  hintText: 'Search here...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Inter',
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: chatservice.getUserScreen(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading users'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var residents = snapshot.data!.where((userData) {
                    return userData["role"] == "resident" &&
                        userData["email"] != firebaseAuth.currentUser?.email;
                  }).toList();

                  if (searchText.isNotEmpty) {
                    residents = residents.where((userData) {
                      final name = (userData["name"] ?? '').toString();
                      return name
                          .toLowerCase()
                          .startsWith(searchText.toLowerCase());
                    }).toList();
                  }

                  if (residents.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    itemCount: residents.length,
                    itemBuilder: (context, index) {
                      return userListitem(residents[index], context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userListitem(Map<String, dynamic> userData, BuildContext context) {
    if (userData["email"] != firebaseAuth.currentUser?.email) {
      final preview = userData["lastMessage"] as String? ?? 'Tap to chat';
      final timestamp = _formatTimestamp(
        userData["lastSeen"] ?? userData["lastMessageTimestamp"],
      );
      final unreadCount = userData["unreadCount"] as int? ?? 0;
      final isRead = userData["isRead"] as bool? ?? true;

      return Usertile(
        name: userData["name"] ?? 'Unknown User',
        preview: preview,
        timestamp: timestamp,
        unreadCount: unreadCount,
        isRead: isRead,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualChatScreen(
                name: userData["name"] ?? 'Unknown User',
                receiverId: userData["uid"],
                receiverEmail: userData["email"] ?? '',
              ),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  String _formatTimestamp(dynamic timestampValue) {
    if (timestampValue == null) return '';
    if (timestampValue is String) return timestampValue;
    if (timestampValue is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestampValue);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }
}

class Usertile extends StatelessWidget {
  final String name;
  final String preview;
  final String timestamp;
  final int unreadCount;
  final bool isRead;
  final VoidCallback onTap;

  const Usertile({
    super.key,
    required this.name,
    required this.preview,
    required this.timestamp,
    required this.unreadCount,
    required this.isRead,
    required this.onTap,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.done_all,
                      size: 18,
                      color: Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
