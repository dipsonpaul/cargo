import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Create or get conversation between two users
  Future<String> createOrGetConversation(String userId1, String userId2, String userName1, String userName2) async {
    try {
      // Check if conversation already exists
      QuerySnapshot existingConversations = await _firestore
          .collection('conversations')
          .where('participant1Id', whereIn: [userId1, userId2])
          .where('participant2Id', whereIn: [userId1, userId2])
          .limit(1)
          .get();

      if (existingConversations.docs.isNotEmpty) {
        return existingConversations.docs.first.id;
      }

      // Create new conversation
      ChatConversation conversation = ChatConversation(
        id: '', // Will be set by Firestore
        participant1Id: userId1,
        participant1Name: userName1,
        participant2Id: userId2,
        participant2Name: userName2,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore.collection('conversations').add(
        conversation.toFirestore(),
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? requestId,
  }) async {
    try {
      // Create message
      ChatMessage message = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        requestId: requestId,
      );

      // Add message to conversation
      DocumentReference messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toFirestore());

      // Update message with ID
      await messageRef.update({'id': messageRef.id});

      // Update conversation with last message info
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': content,
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': senderId,
      });

      // Update unread count
      String unreadField = senderId == 
          await _getConversationParticipant1Id(conversationId) 
          ? 'unreadCount2' 
          : 'unreadCount1';
      
      await _firestore.collection('conversations').doc(conversationId).update({
        unreadField: FieldValue.increment(1),
      });

      // Send notification to receiver
      await _notificationService.sendNotification(
        userId: receiverId,
        title: 'New Message from $senderName',
        body: content,
        type: NotificationType.newMessage,
        senderId: senderId,
        senderName: senderName,
      );

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a conversation
  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Get conversations for a user
  Stream<List<ChatConversation>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participant1Id', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromFirestore(doc))
            .toList())
        .asyncExpand((conversations1) async* {
      // Also get conversations where user is participant 2
      Stream<List<ChatConversation>> conversations2 = _firestore
          .collection('conversations')
          .where('participant2Id', isEqualTo: userId)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChatConversation.fromFirestore(doc))
              .toList());

      List<ChatConversation> allConversations = conversations1;
      await for (List<ChatConversation> convs in conversations2) {
        allConversations.addAll(convs);
        allConversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        yield allConversations;
      }
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Get conversation to determine which unread count to reset
      DocumentSnapshot conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        ChatConversation conversation = ChatConversation.fromFirestore(conversationDoc);
        String unreadField = userId == conversation.participant1Id 
            ? 'unreadCount1' 
            : 'unreadCount2';

        await _firestore.collection('conversations').doc(conversationId).update({
          unreadField: 0,
        });
      }
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  // Upload image for chat
  Future<String> uploadChatImage(File imageFile) async {
    try {
      Reference ref = _storage.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload chat image: $e');
    }
  }

  // Send system message (for request status updates)
  Future<void> sendSystemMessage({
    required String conversationId,
    required String content,
    String? requestId,
  }) async {
    try {
      // Get conversation details
      DocumentSnapshot conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        ChatConversation conversation = ChatConversation.fromFirestore(conversationDoc);

        // Create system message
        ChatMessage systemMessage = ChatMessage(
          id: '',
          senderId: 'system',
          senderName: 'System',
          receiverId: conversation.participant1Id,
          receiverName: conversation.participant1Name,
          content: content,
          type: MessageType.system,
          timestamp: DateTime.now(),
          requestId: requestId,
          isSystemMessage: true,
        );

        // Add system message
        DocumentReference messageRef = await _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .add(systemMessage.toFirestore());

        await messageRef.update({'id': messageRef.id});

        // Update conversation
        await _firestore.collection('conversations').doc(conversationId).update({
          'lastMessage': content,
          'lastMessageAt': Timestamp.fromDate(DateTime.now()),
          'lastMessageSenderId': 'system',
        });
      }
    } catch (e) {
      print('Failed to send system message: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      QuerySnapshot messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation itself
      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Get unread message count for user
  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('conversations')
        .where('participant1Id', isEqualTo: userId)
        .snapshots()
        .asyncExpand((snapshot1) async* {
      Stream<QuerySnapshot> snapshot2 = _firestore
          .collection('conversations')
          .where('participant2Id', isEqualTo: userId)
          .snapshots();

      int totalUnread = 0;
      for (DocumentSnapshot doc in snapshot1.docs) {
        ChatConversation conversation = ChatConversation.fromFirestore(doc);
        totalUnread += conversation.unreadCount1;
      }

      await for (QuerySnapshot snapshot in snapshot2) {
        for (DocumentSnapshot doc in snapshot.docs) {
          ChatConversation conversation = ChatConversation.fromFirestore(doc);
          totalUnread += conversation.unreadCount2;
        }
        yield totalUnread;
      }
    });
  }

  // Helper method to get participant 1 ID from conversation
  Future<String> _getConversationParticipant1Id(String conversationId) async {
    DocumentSnapshot doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['participant1Id'] ?? '';
    }
    return '';
  }

  // Start chat between admin and user (for request-related communication)
  Future<String> startAdminChat(String adminId, String adminName, String userId, String userName, String requestId) async {
    try {
      String conversationId = await createOrGetConversation(adminId, userId, adminName, userName);
      
      // Send initial system message
      await sendSystemMessage(
        conversationId: conversationId,
        content: 'Chat started for request #$requestId',
        requestId: requestId,
      );

      return conversationId;
    } catch (e) {
      throw Exception('Failed to start admin chat: $e');
    }
  }

  // Start chat between driver and customer (triggered by admin)
  Future<String> startDriverCustomerChat(String driverId, String driverName, String customerId, String customerName, String requestId) async {
    try {
      String conversationId = await createOrGetConversation(driverId, customerId, driverName, customerName);
      
      // Send initial system message
      await sendSystemMessage(
        conversationId: conversationId,
        content: 'Direct communication enabled for request #$requestId',
        requestId: requestId,
      );

      return conversationId;
    } catch (e) {
      throw Exception('Failed to start driver-customer chat: $e');
    }
  }
}
