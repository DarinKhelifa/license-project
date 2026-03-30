import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Chats')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: chatservice.getUserScreen(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error loading users'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter the list to only include 'resident' role
          final residents = snapshot.data!.where((userData) {
            return userData["role"] == "resident" &&
                userData["email"] != firebaseAuth.currentUser?.email;
          }).toList();

          if (residents.isEmpty) {
            return const Center(child: Text('No Residents Found'));
          }

          return ListView(
            children: residents
                .map<Widget>((userData) => userListitem(userData, context))
                .toList(),
          );
        },
      ),
    );
  }

  Widget userListitem(Map<String, dynamic> userData, BuildContext context) {
    if (userData["email"] != firebaseAuth.currentUser?.email) {
      return Usertile(
        name: userData["name"] ?? 'Unknown User',
        onTap: () {
          // Pass both name and receiverId to IndividualChatScreen
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
      return Container();
    }
  }
}

class Usertile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const Usertile({super.key, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(name),
      onTap: onTap,
    );
  }
}
