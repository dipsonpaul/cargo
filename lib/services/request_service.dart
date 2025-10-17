import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/request_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Create a new cargo request
  Future<String> createRequest(CargoRequest request) async {
    try {
      DocumentReference docRef = await _firestore.collection('requests').add(
        request.toFirestore(),
      );
      
      // Send notification to admin
      await _notificationService.sendNotificationToAdmins(
        title: 'New Cargo Request',
        body: 'New request from ${request.customerName}',
        type: NotificationType.requestAssigned,
        requestId: docRef.id,
      );
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  // Get all requests
  Stream<List<CargoRequest>> getAllRequests() {
    return _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CargoRequest.fromFirestore(doc))
            .toList());
  }

  // Get requests by status
  Stream<List<CargoRequest>> getRequestsByStatus(RequestStatus status) {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CargoRequest.fromFirestore(doc))
            .toList());
  }

  // Get requests by customer ID
  Stream<List<CargoRequest>> getRequestsByCustomer(String customerId) {
    return _firestore
        .collection('requests')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CargoRequest.fromFirestore(doc))
            .toList());
  }

  // Get requests by driver ID
  Stream<List<CargoRequest>> getRequestsByDriver(String driverId) {
    return _firestore
        .collection('requests')
        .where('assignedDriverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CargoRequest.fromFirestore(doc))
            .toList());
  }

  // Assign request to driver
  Future<void> assignRequestToDriver(String requestId, String driverId, String driverName) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': RequestStatus.assigned.toString().split('.').last,
        'assignedDriverId': driverId,
        'assignedDriverName': driverName,
      });

      // Get request details for notification
      DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (requestDoc.exists) {
        CargoRequest request = CargoRequest.fromFirestore(requestDoc);
        
        // Send notification to driver
        await _notificationService.sendNotification(
          userId: driverId,
          title: 'New Request Assigned',
          body: 'You have been assigned a new cargo collection request',
          type: NotificationType.requestAssigned,
          requestId: requestId,
        );

        // Send notification to customer
        await _notificationService.sendNotification(
          userId: request.customerId,
          title: 'Request Assigned',
          body: 'Your request has been assigned to driver: $driverName',
          type: NotificationType.requestAssigned,
          requestId: requestId,
        );
      }
    } catch (e) {
      throw Exception('Failed to assign request: $e');
    }
  }

  // Driver accepts request
  Future<void> acceptRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': RequestStatus.accepted.toString().split('.').last,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Get request details for notification
      DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (requestDoc.exists) {
        CargoRequest request = CargoRequest.fromFirestore(requestDoc);
        
        // Send notifications
        await _notificationService.sendNotification(
          userId: request.customerId,
          title: 'Request Accepted',
          body: 'Your request has been accepted by ${request.assignedDriverName}',
          type: NotificationType.requestAccepted,
          requestId: requestId,
        );

        await _notificationService.sendNotificationToAdmins(
          title: 'Request Accepted',
          body: 'Request accepted by ${request.assignedDriverName}',
          type: NotificationType.requestAccepted,
          requestId: requestId,
        );
      }
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  // Driver declines request
  Future<void> declineRequest(String requestId, String reason) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': RequestStatus.declined.toString().split('.').last,
        'declineReason': reason,
        'assignedDriverId': null,
        'assignedDriverName': null,
      });

      // Get request details for notification
      DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (requestDoc.exists) {
        CargoRequest request = CargoRequest.fromFirestore(requestDoc);
        
        // Send notifications
        await _notificationService.sendNotification(
          userId: request.customerId,
          title: 'Request Declined',
          body: 'Your request was declined. Reason: $reason',
          type: NotificationType.requestDeclined,
          requestId: requestId,
        );

        await _notificationService.sendNotificationToAdmins(
          title: 'Request Declined',
          body: 'Request declined by driver. Reason: $reason',
          type: NotificationType.requestDeclined,
          requestId: requestId,
        );
      }
    } catch (e) {
      throw Exception('Failed to decline request: $e');
    }
  }

  // Update request status
  Future<void> updateRequestStatus(String requestId, RequestStatus status, {String? notes}) async {
    try {
      Map<String, dynamic> updates = {
        'status': status.toString().split('.').last,
      };

      if (notes != null) {
        updates['collectionNotes'] = notes;
      }

      if (status == RequestStatus.collected) {
        updates['collectedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore.collection('requests').doc(requestId).update(updates);

      // Send notifications based on status
      DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (requestDoc.exists) {
        CargoRequest request = CargoRequest.fromFirestore(requestDoc);
        
        String title = '';
        String body = '';
        NotificationType notificationType = NotificationType.requestStatusUpdate;

        switch (status) {
          case RequestStatus.outForCollection:
            title = 'Driver Out for Collection';
            body = '${request.assignedDriverName} is on the way to collect your cargo';
            notificationType = NotificationType.driverOutForCollection;
            break;
          case RequestStatus.collected:
            title = 'Cargo Collected';
            body = 'Your cargo has been successfully collected';
            notificationType = NotificationType.cargoCollected;
            break;
          case RequestStatus.customerNotAvailable:
            title = 'Customer Not Available';
            body = 'Driver was unable to collect cargo - customer not available';
            notificationType = NotificationType.customerNotAvailable;
            break;
          default:
            title = 'Status Update';
            body = 'Your request status has been updated';
        }

        // Send notification to customer
        await _notificationService.sendNotification(
          userId: request.customerId,
          title: title,
          body: body,
          type: notificationType,
          requestId: requestId,
        );

        // Send notification to admin
        await _notificationService.sendNotificationToAdmins(
          title: title,
          body: body,
          type: notificationType,
          requestId: requestId,
        );
      }
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }

  // Upload cargo photo
  Future<String> uploadCargoPhoto(String requestId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('cargo_photos/$requestId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('requests').doc(requestId).update({
        'cargoPhotoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload cargo photo: $e');
    }
  }

  // Upload door photo
  Future<String> uploadDoorPhoto(String requestId, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('door_photos/$requestId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('requests').doc(requestId).update({
        'doorPhotoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload door photo: $e');
    }
  }

  // Update request details
  Future<void> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('requests').doc(requestId).update(updates);
    } catch (e) {
      throw Exception('Failed to update request: $e');
    }
  }

  // Delete request
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete request: $e');
    }
  }

  // Get pending requests for reassignment
  Future<List<CargoRequest>> getPendingReassignmentRequests() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('status', isEqualTo: RequestStatus.declined.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CargoRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending reassignment requests: $e');
    }
  }

  // Get available drivers
  Future<List<UserModel>> getAvailableDrivers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get available drivers: $e');
    }
  }
}
