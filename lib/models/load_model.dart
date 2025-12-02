import 'package:cloud_firestore/cloud_firestore.dart';

class LoadModel {
  final String id;
  final String shipperUid;
  final String shipperName;
  final String title;
  final String description;
  final double price;
  final double distance;
  final String originAddress;
  final String originCity;
  final String originState;
  final String destinationAddress;
  final String destinationCity;
  final String destinationState;
  final double weight;
  final String equipmentNeeded;
  final String loadType;
  final DateTime pickupDate;
  final DateTime deliveryDate;
  final String status; // available, booked, in-transit, completed, cancelled
  final String? bookedByCarrierId;
  final DateTime? bookedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int views;
  final double? matchPercentage; // calculated client-side
  final Map<String, dynamic>? additionalData;

  LoadModel({
    required this.id,
    required this.shipperUid,
    required this.shipperName,
    required this.title,
    required this.description,
    required this.price,
    required this.distance,
    required this.originAddress,
    required this.originCity,
    required this.originState,
    required this.destinationAddress,
    required this.destinationCity,
    required this.destinationState,
    required this.weight,
    required this.equipmentNeeded,
    required this.loadType,
    required this.pickupDate,
    required this.deliveryDate,
    this.status = 'available',
    this.bookedByCarrierId,
    this.bookedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.views = 0,
    this.matchPercentage,
    this.additionalData,
  });

  // Factory constructor from Firestore document
  factory LoadModel.fromFirestore(DocumentSnapshot doc, {String? parentShipperUid}) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      // Use parentShipperUid if provided (from subcollection path), otherwise use data
      final shipperUid = parentShipperUid ?? data['shipperUid'] ?? '';
      
      // Get description - check multiple possible field names
      final description = data['description'] ?? 
                         data['loadDescription'] ?? 
                         data['notes'] ?? 
                         data['details'] ?? 
                         '';
      
      // Get shipperName - check multiple possible field names
      final shipperName = data['shipperName'] ?? 
                         data['shipper_name'] ?? 
                         data['companyName'] ?? 
                         data['displayName'] ?? 
                         '';
      
      return LoadModel(
        id: doc.id,
        shipperUid: shipperUid,
        shipperName: shipperName,
        title: data['title'] ?? '',
        description: description,
        price: _parseDouble(data['price']) ?? _parseDouble(data['quoteBudget']) ?? 0.0,
        distance: _parseDouble(data['distance']) ?? 0.0,
        originAddress: data['originAddress'] ?? '',
        originCity: data['originCity'] ?? '',
        originState: data['originState'] ?? '',
        destinationAddress: data['destinationAddress'] ?? '',
        destinationCity: data['destinationCity'] ?? '',
        destinationState: data['destinationState'] ?? '',
        weight: _parseDouble(data['weight']) ?? 0.0,
        equipmentNeeded: data['equipmentNeeded'] ?? '',
        loadType: data['loadType'] ?? '',
        pickupDate: _parseDate(data['pickupDate']) ?? DateTime.now(),
        deliveryDate: _parseDate(data['deliveryDate']) ?? DateTime.now(),
        status: data['status'] ?? 'available',
        bookedByCarrierId: data['bookedByCarrierId'],
        bookedAt: data['bookedAt'] != null ? _parseDate(data['bookedAt']) : null,
        completedAt: data['completedAt'] != null ? _parseDate(data['completedAt']) : null,
        createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
        isActive: data['isActive'] ?? true,
        views: data['views'] ?? 0,
        matchPercentage: _parseDouble(data['matchPercentage']),
        additionalData: data['additionalData'],
      );
    } catch (e) {
      print('Error parsing LoadModel from Firestore document ${doc.id}: $e');
      print('Document data: ${doc.data()}');
      rethrow;
    }
  }

  // Factory constructor from JSON
  factory LoadModel.fromJson(Map<String, dynamic> json) {
    return LoadModel(
      id: json['id'] ?? '',
      shipperUid: json['shipperUid'] ?? '',
      shipperName: json['shipperName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      distance: _parseDouble(json['distance']) ?? 0.0,
      originAddress: json['originAddress'] ?? '',
      originCity: json['originCity'] ?? '',
      originState: json['originState'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
      destinationCity: json['destinationCity'] ?? '',
      destinationState: json['destinationState'] ?? '',
      weight: _parseDouble(json['weight']) ?? 0.0,
      equipmentNeeded: json['equipmentNeeded'] ?? '',
      loadType: json['loadType'] ?? '',
      pickupDate: DateTime.parse(json['pickupDate']),
      deliveryDate: DateTime.parse(json['deliveryDate']),
      status: json['status'] ?? 'available',
      bookedByCarrierId: json['bookedByCarrierId'],
      bookedAt: json['bookedAt'] != null
          ? DateTime.parse(json['bookedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      views: json['views'] ?? 0,
      matchPercentage: _parseDouble(json['matchPercentage']),
      additionalData: json['additionalData'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipperUid': shipperUid,
      'shipperName': shipperName,
      'title': title,
      'description': description,
      'price': price,
      'distance': distance,
      'originAddress': originAddress,
      'originCity': originCity,
      'originState': originState,
      'destinationAddress': destinationAddress,
      'destinationCity': destinationCity,
      'destinationState': destinationState,
      'weight': weight,
      'equipmentNeeded': equipmentNeeded,
      'loadType': loadType,
      'pickupDate': pickupDate.toIso8601String(),
      'deliveryDate': deliveryDate.toIso8601String(),
      'status': status,
      'bookedByCarrierId': bookedByCarrierId,
      'bookedAt': bookedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'matchPercentage': matchPercentage,
      'additionalData': additionalData,
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'shipperUid': shipperUid,
      'shipperName': shipperName,
      'title': title,
      'description': description,
      'price': price,
      'distance': distance,
      'originAddress': originAddress,
      'originCity': originCity,
      'originState': originState,
      'destinationAddress': destinationAddress,
      'destinationCity': destinationCity,
      'destinationState': destinationState,
      'weight': weight,
      'equipmentNeeded': equipmentNeeded,
      'loadType': loadType,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'status': status,
      'bookedByCarrierId': bookedByCarrierId,
      'bookedAt': bookedAt != null ? Timestamp.fromDate(bookedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'views': views,
      'matchPercentage': matchPercentage,
      'additionalData': additionalData,
    };
  }

  // Copy with method for updates
  LoadModel copyWith({
    String? id,
    String? shipperUid,
    String? shipperName,
    String? title,
    String? description,
    double? price,
    double? distance,
    String? originAddress,
    String? originCity,
    String? originState,
    String? destinationAddress,
    String? destinationCity,
    String? destinationState,
    double? weight,
    String? equipmentNeeded,
    String? loadType,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    String? status,
    String? bookedByCarrierId,
    DateTime? bookedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? views,
    double? matchPercentage,
    Map<String, dynamic>? additionalData,
  }) {
    return LoadModel(
      id: id ?? this.id,
      shipperUid: shipperUid ?? this.shipperUid,
      shipperName: shipperName ?? this.shipperName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      originAddress: originAddress ?? this.originAddress,
      originCity: originCity ?? this.originCity,
      originState: originState ?? this.originState,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationState: destinationState ?? this.destinationState,
      weight: weight ?? this.weight,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
      loadType: loadType ?? this.loadType,
      pickupDate: pickupDate ?? this.pickupDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      bookedByCarrierId: bookedByCarrierId ?? this.bookedByCarrierId,
      bookedAt: bookedAt ?? this.bookedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper method to parse dates from various formats
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

  // Helper method to parse double values from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    
    try {
      // If it's already a number, convert it
      if (value is num) {
        return value.toDouble();
      }
      
      // If it's a string, try to parse it
      if (value is String) {
        // Remove whitespace
        String cleaned = value.trim();
        
        // Try direct parsing first
        try {
          return double.parse(cleaned);
        } catch (e) {
          // If that fails, try to extract the number from strings like "10tons", "100 lbs", etc.
          // Use regex to extract the first number (including decimals and optional negative sign)
          final RegExp numberPattern = RegExp(r'-?\d+(\.\d+)?');
          final Match? match = numberPattern.firstMatch(cleaned);
          
          if (match != null) {
            return double.parse(match.group(0)!);
          }
        }
      }
    } catch (e) {
      print('Error parsing double: $value, error: $e');
    }
    
    return null;
  }

  @override
  String toString() {
    return 'LoadModel(id: $id, title: $title, status: $status, matchPercentage: $matchPercentage)';
  }
}
