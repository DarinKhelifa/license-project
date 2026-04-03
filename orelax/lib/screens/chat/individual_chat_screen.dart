import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class IndividualChatScreen extends StatefulWidget {
  final String name;
  final String receiverId;
  final String receiverEmail;

  const IndividualChatScreen({
    super.key,
    required this.name,
    required this.receiverId,
    required this.receiverEmail,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController messageController = TextEditingController();
  bool hasText = false;
  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final Chatservice chatService = Chatservice();

  @override
  void initState() {
    super.initState();
    messageController.addListener(() {
      if (!mounted) return;
      setState(() {
        hasText = messageController.text.trim().isNotEmpty;
      });
    });
  }

  void sendMessage() async {
    if (messageController.text.isNotEmpty) {
      await chatService.sendMessage(widget.receiverId, messageController.text);
      messageController.clear();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 16),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: Row(
          children: [
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          userInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderId = firebaseAuth.currentUser!.uid;
    return StreamBuilder(
      stream: chatService.getMessages(senderId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading messages'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...docs.asMap().entries.map((entry) {
              final index = entry.key;
              final doc = entry.value;
              final nextDoc = index < docs.length - 1 ? docs[index + 1] : null;
              final isTail = _isSentTail(doc, nextDoc);
              return _buildMessageItem(doc, context, isTail);
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildMessageItem(
      DocumentSnapshot doc, BuildContext context, bool isTail) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool currentUser = data["senderId"] == firebaseAuth.currentUser?.uid;
    final bubbleColor =
        currentUser ? const Color(0xFF4CAF50) : const Color(0xFFF1F1F1);
    final textColor = currentUser ? Colors.white : Colors.black87;
    final borderRadius = currentUser
        ? BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: const Radius.circular(15),
            bottomRight: Radius.circular(isTail ? 4 : 15),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(15),
          );

    return GestureDetector(
      onDoubleTap: () {
        if (currentUser) {
          _showEditDeleteDialog(context, data, doc.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment:
              currentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                data["message"],
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
                  currentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTimestamp(data['timestamp']),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isSentTail(DocumentSnapshot doc, DocumentSnapshot? nextDoc) {
    if (nextDoc == null) return true;
    final currentSender = (doc.data() as Map<String, dynamic>)["senderId"];
    final nextSender = (nextDoc.data() as Map<String, dynamic>)["senderId"];
    return currentSender != nextSender;
  }

  String _formatTimestamp(dynamic timestampValue) {
    if (timestampValue == null) return '';
    DateTime date;

    if (timestampValue is Timestamp) {
      date = timestampValue.toDate();
    } else if (timestampValue is DateTime) {
      date = timestampValue;
    } else if (timestampValue is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else {
      return '';
    }

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void _showEditDeleteDialog(
      BuildContext context, Map<String, dynamic> data, String messageId) {
    TextEditingController editController =
        TextEditingController(text: data["message"]);
    String userId = firebaseAuth.currentUser!.uid;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit or Delete Message"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: "Edit your message"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                chatService.updateMessage(
                    messageId, editController.text, userId, widget.receiverId);
                editController.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Update"),
            ),
            TextButton(
              onPressed: () {
                chatService.deleteMessage(messageId, userId, widget.receiverId);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget userInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: sendMessage,
              icon: Icon(
                hasText ? Icons.send : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}