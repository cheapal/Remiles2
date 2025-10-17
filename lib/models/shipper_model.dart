import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';
import 'shipper_onboarding_data.dart';

class ShipperModel extends UserModel {
  final String companyName;
  final String? businessType;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? taxId;
  final bool isVerified;
  final List<String>? preferredCarrierTypes;
  final Map<String, dynamic>? shippingPreferences;
  final int totalShipments;
  final double? rating;
  final DateTime? verificationDate;
  final bool isOnboardingComplete;
  final ShipperOnboardingData? onboardingData;

  ShipperModel({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    required DateTime createdAt,
    DateTime? lastLoginAt,
    bool isEmailVerified = false,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
    required this.companyName,
    this.businessType,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.taxId,
    this.isVerified = false,
    this.preferredCarrierTypes,
    this.shippingPreferences,
    this.totalShipments = 0,
    this.rating,
    this.verificationDate,
    this.isOnboardingComplete = false,
    this.onboardingData,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          role: UserRole.shipper,
          createdAt: createdAt,
          lastLoginAt: lastLoginAt,
          isEmailVerified: isEmailVerified,
          profileImageUrl: profileImageUrl,
          additionalData: additionalData,
        );

  // Factory constructor from Firestore document
  factory ShipperModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShipperModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isEmailVerified: data['isEmailVerified'] ?? false,
      profileImageUrl: data['profileImageUrl'],
      additionalData: data['additionalData'],
      companyName: data['companyName'] ?? '',
      businessType: data['businessType'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      country: data['country'],
      taxId: data['taxId'],
      isVerified: data['isVerified'] ?? false,
      preferredCarrierTypes: data['preferredCarrierTypes'] != null
          ? List<String>.from(data['preferredCarrierTypes'])
          : null,
      shippingPreferences: data['shippingPreferences'],
      totalShipments: data['totalShipments'] ?? 0,
      rating: data['rating']?.toDouble(),
      verificationDate: data['verificationDate'] != null
          ? (data['verificationDate'] as Timestamp).toDate()
          : null,
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      onboardingData: data['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(data['onboardingData'])
          : null,
    );
  }

  // Factory constructor from JSON
  factory ShipperModel.fromJson(Map<String, dynamic> json) {
    return ShipperModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      additionalData: json['additionalData'],
      companyName: json['companyName'] ?? '',
      businessType: json['businessType'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
      taxId: json['taxId'],
      isVerified: json['isVerified'] ?? false,
      preferredCarrierTypes: json['preferredCarrierTypes'] != null
          ? List<String>.from(json['preferredCarrierTypes'])
          : null,
      shippingPreferences: json['shippingPreferences'],
      totalShipments: json['totalShipments'] ?? 0,
      rating: json['rating']?.toDouble(),
      verificationDate: json['verificationDate'] != null
          ? DateTime.parse(json['verificationDate'])
          : null,
    );
  }

  // Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'companyName': companyName,
      'businessType': businessType,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'taxId': taxId,
      'isVerified': isVerified,
      'preferredCarrierTypes': preferredCarrierTypes,
      'shippingPreferences': shippingPreferences,
      'totalShipments': totalShipments,
      'rating': rating,
      'verificationDate': verificationDate?.toIso8601String(),
      'isOnboardingComplete': isOnboardingComplete,
      'onboardingData': onboardingData?.toFirestore(),
    });
    return json;
  }

  // Convert to Firestore document
  @override
  Map<String, dynamic> toFirestore() {
    final firestore = super.toFirestore();
    firestore.addAll({
      'companyName': companyName,
      'businessType': businessType,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'taxId': taxId,
      'isVerified': isVerified,
      'preferredCarrierTypes': preferredCarrierTypes,
      'shippingPreferences': shippingPreferences,
      'totalShipments': totalShipments,
      'rating': rating,
      'verificationDate': verificationDate != null 
          ? Timestamp.fromDate(verificationDate!) 
          : null,
      'isOnboardingComplete': isOnboardingComplete,
      'onboardingData': onboardingData?.toFirestore(),
    });
    return firestore;
  }

  // Copy with method for updates
  ShipperModel copyWithShipper({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
    String? companyName,
    String? businessType,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? taxId,
    bool? isVerified,
    List<String>? preferredCarrierTypes,
    Map<String, dynamic>? shippingPreferences,
    int? totalShipments,
    double? rating,
    DateTime? verificationDate,
    bool? isOnboardingComplete,
    ShipperOnboardingData? onboardingData,
  }) {
    return ShipperModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      additionalData: additionalData ?? this.additionalData,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      taxId: taxId ?? this.taxId,
      isVerified: isVerified ?? this.isVerified,
      preferredCarrierTypes: preferredCarrierTypes ?? this.preferredCarrierTypes,
      shippingPreferences: shippingPreferences ?? this.shippingPreferences,
      totalShipments: totalShipments ?? this.totalShipments,
      rating: rating ?? this.rating,
      verificationDate: verificationDate ?? this.verificationDate,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      onboardingData: onboardingData ?? this.onboardingData,
    );
  }

  @override
  String toString() {
    return 'ShipperModel(uid: $uid, email: $email, companyName: $companyName, isVerified: $isVerified)';
  }
}
