import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListing {
  final String id;
  final String shipperUid;
  final String shipperName;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String location;
  final List<String> imageUrls;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int views;
  final int favorites;
  final Map<String, dynamic>? additionalData;

  ProductListing({
    required this.id,
    required this.shipperUid,
    required this.shipperName,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.location,
    this.imageUrls = const [],
    this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.views = 0,
    this.favorites = 0,
    this.additionalData,
  });

  // Factory constructor from Firestore document
  factory ProductListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductListing(
      id: doc.id,
      shipperUid: data['shipperUid'] ?? '',
      shipperName: data['shipperName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      condition: data['condition'] ?? 'New',
      location: data['location'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      views: data['views'] ?? 0,
      favorites: data['favorites'] ?? 0,
      additionalData: data['additionalData'],
    );
  }

  // Factory constructor from JSON
  factory ProductListing.fromJson(Map<String, dynamic> json) {
    return ProductListing(
      id: json['id'] ?? '',
      shipperUid: json['shipperUid'] ?? '',
      shipperName: json['shipperName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      condition: json['condition'] ?? 'New',
      location: json['location'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrl: json['videoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      views: json['views'] ?? 0,
      favorites: json['favorites'] ?? 0,
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
      'condition': condition,
      'location': location,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'favorites': favorites,
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
      'condition': condition,
      'location': location,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'views': views,
      'favorites': favorites,
      'additionalData': additionalData,
    };
  }

  // Copy with method for updates
  ProductListing copyWith({
    String? id,
    String? shipperUid,
    String? shipperName,
    String? title,
    String? description,
    double? price,
    String? condition,
    String? location,
    List<String>? imageUrls,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? views,
    int? favorites,
    Map<String, dynamic>? additionalData,
  }) {
    return ProductListing(
      id: id ?? this.id,
      shipperUid: shipperUid ?? this.shipperUid,
      shipperName: shipperName ?? this.shipperName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      favorites: favorites ?? this.favorites,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
