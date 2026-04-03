import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import 'individual_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Chatservice chatservice = Chatservice();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _filterResidents(
      List<Map<String, dynamic>> residents) async {
    final filtered = <Map<String, dynamic>>[];
    for (var resident in residents) {
      final uid = resident["uid"] as String?;
      if (uid == null) continue;

      final hasMessage = resident.containsKey("lastMessage") &&
          resident["lastMessage"] != null &&
          resident["lastMessage"].toString().isNotEmpty;

      if (hasMessage) {
        filtered.add(resident);
        continue;
      }

      // Fallback: Check if a chat room with messages physically exists
      final currentUid = firebaseAuth.currentUser?.uid;
      if (currentUid == null) continue;

      List<String> ids = [currentUid, uid];
      ids.sort();
      String chatRoomId = ids.join('_');

      try {
        final snap = await FirebaseFirestore.instance
            .collection("chat_room")
            .doc(chatRoomId)
            .collection("Messages")
            .orderBy("time", descending: true)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          final docData = snap.docs.first.data();
          resident["lastMessage"] = docData["message"];
          resident["lastMessageTimestamp"] = docData["time"];
          filtered.add(resident);
        }
      } catch (e) {
        // ignore errors
      }
    }
    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no-message.png',
            height: 150,
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Chat!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Feel free to start a new conversation\nby tapping the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              searchFocusNode.requestFocus();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Start New Chat',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF388E3C),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
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
        title: const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Text(
            'Chat ',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Inter',
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
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
                focusNode: searchFocusNode,
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

                  var allResidents = snapshot.data!.where((userData) {
                    return userData["role"] == "resident" &&
                        userData["email"] != firebaseAuth.currentUser?.email;
                  }).toList();

                  if (searchText.isNotEmpty) {
                    allResidents = allResidents.where((userData) {
                      final name = (userData["name"] ?? '').toString();
                      return name
                          .toLowerCase()
                          .startsWith(searchText.toLowerCase());
                    }).toList();
                  }

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: searchText.isNotEmpty
                        ? Future.value(allResidents)
                        : _filterResidents(allResidents),
                    builder: (context, filterSnapshot) {
                      if (filterSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final filteredResidents = filterSnapshot.data ?? [];

                      if (filteredResidents.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        itemCount: filteredResidents.length,
                        itemBuilder: (context, index) {
                          return userListitem(filteredResidents[index], context);
                        },
                      );
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Inter',
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
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