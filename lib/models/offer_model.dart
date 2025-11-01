import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus {
  pending,
  accepted,
  rejected,
  counterOffered,
  expired
}

class OfferModel {
  final String id;
  final String loadId;
  final String conversationId;
  final String carrierId;
  final String carrierName;
  final String shipperId;
  final double offerAmount;
  final OfferStatus status;
  final double? originalOfferAmount; // If this is a counter-offer
  final double? counterOfferAmount; // Shipper's counter-offer amount
  final DateTime negotiationStartTime; // When first offer was sent (starts timer)
  final DateTime expiresAt; // 30 minutes from negotiationStartTime
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfferModel({
    required this.id,
    required this.loadId,
    required this.conversationId,
    required this.carrierId,
    required this.carrierName,
    required this.shipperId,
    required this.offerAmount,
    required this.status,
    this.originalOfferAmount,
    this.counterOfferAmount,
    required this.negotiationStartTime,
    required this.expiresAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      loadId: data['loadId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      carrierId: data['carrierId'] ?? '',
      carrierName: data['carrierName'] ?? '',
      shipperId: data['shipperId'] ?? '',
      offerAmount: (data['offerAmount'] ?? 0.0).toDouble(),
      status: _parseOfferStatus(data['status']),
      originalOfferAmount: data['originalOfferAmount'] != null
          ? (data['originalOfferAmount'] as num).toDouble()
          : null,
      counterOfferAmount: data['counterOfferAmount'] != null
          ? (data['counterOfferAmount'] as num).toDouble()
          : null,
      negotiationStartTime: _parseDate(data['negotiationStartTime']) ?? DateTime.now(),
      expiresAt: _parseDate(data['expiresAt']) ?? DateTime.now(),
      acceptedAt: data['acceptedAt'] != null
          ? _parseDate(data['acceptedAt'])
          : null,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  factory OfferModel.fromMap(Map<String, dynamic> data) {
    return OfferModel(
      id: data['id'] ?? '',
      loadId: data['loadId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      carrierId: data['carrierId'] ?? '',
      carrierName: data['carrierName'] ?? '',
      shipperId: data['shipperId'] ?? '',
      offerAmount: (data['offerAmount'] ?? 0.0).toDouble(),
      status: _parseOfferStatus(data['status']),
      originalOfferAmount: data['originalOfferAmount'] != null
          ? (data['originalOfferAmount'] as num).toDouble()
          : null,
      counterOfferAmount: data['counterOfferAmount'] != null
          ? (data['counterOfferAmount'] as num).toDouble()
          : null,
      negotiationStartTime: _parseDate(data['negotiationStartTime']) ?? DateTime.now(),
      expiresAt: _parseDate(data['expiresAt']) ?? DateTime.now(),
      acceptedAt: data['acceptedAt'] != null
          ? _parseDate(data['acceptedAt'])
          : null,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'loadId': loadId,
      'conversationId': conversationId,
      'carrierId': carrierId,
      'carrierName': carrierName,
      'shipperId': shipperId,
      'offerAmount': offerAmount,
      'status': status.toString().split('.').last,
      'originalOfferAmount': originalOfferAmount,
      'counterOfferAmount': counterOfferAmount,
      'negotiationStartTime': Timestamp.fromDate(negotiationStartTime),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  OfferModel copyWith({
    String? id,
    String? loadId,
    String? conversationId,
    String? carrierId,
    String? carrierName,
    String? shipperId,
    double? offerAmount,
    OfferStatus? status,
    double? originalOfferAmount,
    double? counterOfferAmount,
    DateTime? negotiationStartTime,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      loadId: loadId ?? this.loadId,
      conversationId: conversationId ?? this.conversationId,
      carrierId: carrierId ?? this.carrierId,
      carrierName: carrierName ?? this.carrierName,
      shipperId: shipperId ?? this.shipperId,
      offerAmount: offerAmount ?? this.offerAmount,
      status: status ?? this.status,
      originalOfferAmount: originalOfferAmount ?? this.originalOfferAmount,
      counterOfferAmount: counterOfferAmount ?? this.counterOfferAmount,
      negotiationStartTime: negotiationStartTime ?? this.negotiationStartTime,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == OfferStatus.pending || status == OfferStatus.counterOffered;
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  static OfferStatus _parseOfferStatus(dynamic status) {
    if (status == null) return OfferStatus.pending;
    final statusString = status.toString().toLowerCase();
    if (statusString.contains('pending')) return OfferStatus.pending;
    if (statusString.contains('accepted')) return OfferStatus.accepted;
    if (statusString.contains('rejected')) return OfferStatus.rejected;
    if (statusString.contains('counter')) return OfferStatus.counterOffered;
    if (statusString.contains('expired')) return OfferStatus.expired;
    return OfferStatus.pending;
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
    }
    
    return null;
  }

  @override
  String toString() {
    return 'OfferModel(id: $id, loadId: $loadId, offerAmount: $offerAmount, status: $status)';
  }
}

