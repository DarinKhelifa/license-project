import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final Chatservice chatService = Chatservice();

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
      appBar: AppBar(
        title: Center(child: Text(widget.name)),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pop(context); // Optional safely pops chat screen
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [Expanded(child: _buildMessageList()), userInput()],
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildMessageList() {
    String senderId = firebaseAuth.currentUser!.uid;
    return StreamBuilder(
      stream: chatService.getMessages(senderId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text("Loading..."));
        }
        return ListView(
          children: snapshot.data!.docs
              .map((e) => _buildMessageItem(e, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool currentUser = data["senderId"] == firebaseAuth.currentUser?.uid;

    return GestureDetector(
      onDoubleTap: () {
        if (currentUser) {
          // Only allow actions if the current user is the sender
          _showEditDeleteDialog(context, data, doc.id);
        }
      },
      child: Container(
        child: Column(
          crossAxisAlignment:
              currentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: currentUser ? Colors.green : Colors.blue,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  data["message"],
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                // Update the message
                chatService.updateMessage(
                    messageId, editController.text, userId, widget.receiverId);
                editController.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Update"),
            ),
            TextButton(
              onPressed: () {
                // Delete the message
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
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: messageController,
              decoration: InputDecoration(
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                hintText: 'Message',
                contentPadding:
                    const EdgeInsets.only(left: 15, bottom: 8, top: 8),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(40)),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(
                Icons.send_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
