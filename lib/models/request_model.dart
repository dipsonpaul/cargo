import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  assigned,
  accepted,
  declined,
  outForCollection,
  collected,
  customerNotAvailable,
  completed,
  cancelled
}

class CargoRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String? pickupInstructions;
  final DateTime preferredPickupTime;
  final DateTime createdAt;
  final RequestStatus status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? declineReason;
  final int? packageCount;
  final String? cargoPhotoUrl;
  final String? doorPhotoUrl;
  final String? collectionNotes;
  final DateTime? acceptedAt;
  final DateTime? collectedAt;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  CargoRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    this.pickupInstructions,
    required this.preferredPickupTime,
    required this.createdAt,
    this.status = RequestStatus.pending,
    this.assignedDriverId,
    this.assignedDriverName,
    this.declineReason,
    this.packageCount,
    this.cargoPhotoUrl,
    this.doorPhotoUrl,
    this.collectionNotes,
    this.acceptedAt,
    this.collectedAt,
    this.latitude,
    this.longitude,
    this.locationAddress,
  });

  factory CargoRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CargoRequest(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      pickupInstructions: data['pickupInstructions'],
      preferredPickupTime: (data['preferredPickupTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == 'RequestStatus.${data['status']}',
        orElse: () => RequestStatus.pending,
      ),
      assignedDriverId: data['assignedDriverId'],
      assignedDriverName: data['assignedDriverName'],
      declineReason: data['declineReason'],
      packageCount: data['packageCount'],
      cargoPhotoUrl: data['cargoPhotoUrl'],
      doorPhotoUrl: data['doorPhotoUrl'],
      collectionNotes: data['collectionNotes'],
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      collectedAt: data['collectedAt'] != null
          ? (data['collectedAt'] as Timestamp).toDate()
          : null,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationAddress: data['locationAddress'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupAddress': pickupAddress,
      'pickupInstructions': pickupInstructions,
      'preferredPickupTime': Timestamp.fromDate(preferredPickupTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'declineReason': declineReason,
      'packageCount': packageCount,
      'cargoPhotoUrl': cargoPhotoUrl,
      'doorPhotoUrl': doorPhotoUrl,
      'collectionNotes': collectionNotes,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'collectedAt': collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
    };
  }

  CargoRequest copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? pickupAddress,
    String? pickupInstructions,
    DateTime? preferredPickupTime,
    DateTime? createdAt,
    RequestStatus? status,
    String? assignedDriverId,
    String? assignedDriverName,
    String? declineReason,
    int? packageCount,
    String? cargoPhotoUrl,
    String? doorPhotoUrl,
    String? collectionNotes,
    DateTime? acceptedAt,
    DateTime? collectedAt,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) {
    return CargoRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      preferredPickupTime: preferredPickupTime ?? this.preferredPickupTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      declineReason: declineReason ?? this.declineReason,
      packageCount: packageCount ?? this.packageCount,
      cargoPhotoUrl: cargoPhotoUrl ?? this.cargoPhotoUrl,
      doorPhotoUrl: doorPhotoUrl ?? this.doorPhotoUrl,
      collectionNotes: collectionNotes ?? this.collectionNotes,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      collectedAt: collectedAt ?? this.collectedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.assigned:
        return 'Assigned';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.declined:
        return 'Declined';
      case RequestStatus.outForCollection:
        return 'Out for Collection';
      case RequestStatus.collected:
        return 'Collected';
      case RequestStatus.customerNotAvailable:
        return 'Customer Not Available';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}
