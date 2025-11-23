import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderStatus,
  paymentReceived,
  paymentFailed,
  offerAccepted,
  offerRejected,
  message,
  system,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedId; // e.g., loadId, paymentId, etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.relatedId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseNotificationType(data['type'] ?? 'system'),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedId: data['relatedId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedId': relatedId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'orderStatus':
        return NotificationType.orderStatus;
      case 'paymentReceived':
        return NotificationType.paymentReceived;
      case 'paymentFailed':
        return NotificationType.paymentFailed;
      case 'offerAccepted':
        return NotificationType.offerAccepted;
      case 'offerRejected':
        return NotificationType.offerRejected;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.system;
    }
  }
}
