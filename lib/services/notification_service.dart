import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    print('Notification tapped: ${response.payload}');
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(message);
    }
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Got a message whilst in the background!');
    print('Message data: ${message.data}');
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'cargo_notifications',
      'Cargo Notifications',
      channelDescription: 'Notifications for cargo collection system',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Send notification to specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? requestId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification document
      AppNotification notification = AppNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        requestId: requestId,
        senderId: senderId,
        senderName: senderName,
        data: data,
      );

      DocumentReference docRef = await _firestore.collection('notifications').add(
        notification.toFirestore(),
      );

      // Update notification with ID
      await _firestore.collection('notifications').doc(docRef.id).update({
        'id': docRef.id,
      });

      // Send push notification via FCM
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        data: data ?? {},
      );

    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  // Send notification to all admins
  Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    required NotificationType type,
    String? requestId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? data,
  }) async {
    try {
      QuerySnapshot adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      for (DocumentSnapshot doc in adminSnapshot.docs) {
        UserModel admin = UserModel.fromFirestore(doc);
        await sendNotification(
          userId: admin.id,
          title: title,
          body: body,
          type: type,
          requestId: requestId,
          senderId: senderId,
          senderName: senderName,
          data: data,
        );
      }
    } catch (e) {
      print('Failed to send notification to admins: $e');
    }
  }

  // Send push notification via FCM
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token
      String? fcmToken = await _getUserFCMToken(userId);
      
      if (fcmToken != null) {
        // In a real app, you would send this to your backend server
        // which would then send the FCM message
        print('Would send FCM notification to token: $fcmToken');
        print('Title: $title, Body: $body, Data: $data');
      }
    } catch (e) {
      print('Failed to send push notification: $e');
    }
  }

  // Get user's FCM token
  Future<String?> _getUserFCMToken(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['fcmToken'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user's FCM token
  Future<void> updateUserFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      print('Failed to update FCM token: $e');
    }
  }

  // Get notifications for user
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': NotificationStatus.read.toString().split('.').last,
      });
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.toString().split('.').last)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.toString().split('.').last,
        });
      }
      await batch.commit();
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: NotificationStatus.unread.toString().split('.').last)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Failed to delete notification: $e');
    }
  }

  // Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Failed to clear all notifications: $e');
    }
  }
}
