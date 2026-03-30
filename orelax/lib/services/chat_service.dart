import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Chatservice {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendMessage(String receiverId, message) async {
    final String currentUid = _auth.currentUser!.uid;
    final String? currentEmail = _auth.currentUser!.email;
    final Timestamp time = Timestamp.now();

    Message newmessage = Message(
        senderId: currentUid,
        senderEmail: currentEmail,
        receiverId: receiverId,
        message: message,
        time: time);
    List<String> ids = [currentUid, receiverId];
    ids.sort();

    String chatRoomId = ids.join('_');

    await _firestore
        .collection("chat_room")
        .doc(chatRoomId)
        .collection("Messages")
        .add(newmessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();

    String chatRoomId = ids.join('_');
    print("Generated chatRoomId: $chatRoomId");

    return _firestore
        .collection("chat_room")
        .doc(chatRoomId)
        .collection("Messages")
        .orderBy("time", descending: false)
        .snapshots();
  }

  Future<void> updateMessage(String messageId, String newMessage, String userId,
      String otherUserId) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();

    String chatRoomId = ids.join('_');

    await _firestore
        .collection("chat_room")
        .doc(chatRoomId)
        .collection("Messages")
        .doc(messageId)
        .update({
      "message": newMessage,
      "time": Timestamp.now(),
    });
  }

  void deleteMessage(String messageId, String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();

    String chatRoomId = ids.join('_');
    FirebaseFirestore.instance
        .collection("chat_room")
        .doc(chatRoomId)
        .collection("Messages")
        .doc(messageId)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getUserScreen() {
    return _firestore
        .collection("users")
        .where("role", isEqualTo: "resident") // This is the magic line!
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}

class Message {
  final String senderId;
  final String? senderEmail;
  final String receiverId;
  final String message;
  final Timestamp time;

  Message(
      {required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.time});

  Map<String, dynamic> toMap() {
    return {
      "senderEmail": senderEmail,
      "senderId": senderId,
      "message": message,
      "time": time,
      "receiverId": receiverId
    };
  }
}
