import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  requestAssigned,
  requestAccepted,
  requestDeclined,
  requestStatusUpdate,
  newMessage,
  driverOutForCollection,
  cargoCollected,
  customerNotAvailable,
  systemAlert
}

enum NotificationStatus { unread, read }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationStatus status;
  final DateTime createdAt;
  final String? requestId;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic>? data; // Additional data payload

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.requestId,
    this.senderId,
    this.senderName,
    this.data,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: docData['userId'] ?? '',
      title: docData['title'] ?? '',
      body: docData['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${docData['type']}',
        orElse: () => NotificationType.systemAlert,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == 'NotificationStatus.${docData['status']}',
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: (docData['createdAt'] as Timestamp).toDate(),
      requestId: docData['requestId'],
      senderId: docData['senderId'],
      senderName: docData['senderName'],
      data: docData['data'] != null 
          ? Map<String, dynamic>.from(docData['data']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationStatus? status,
    DateTime? createdAt,
    String? requestId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      requestId: requestId ?? this.requestId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      data: data ?? this.data,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.requestAssigned:
        return 'Request Assigned';
      case NotificationType.requestAccepted:
        return 'Request Accepted';
      case NotificationType.requestDeclined:
        return 'Request Declined';
      case NotificationType.requestStatusUpdate:
        return 'Status Update';
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.driverOutForCollection:
        return 'Driver Out for Collection';
      case NotificationType.cargoCollected:
        return 'Cargo Collected';
      case NotificationType.customerNotAvailable:
        return 'Customer Not Available';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }
}
