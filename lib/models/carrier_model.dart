import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';
import 'carrier_onboarding_data.dart';

class CarrierModel extends UserModel {
  final String? companyName;
  final String? businessType;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? licenseNumber;
  final String? insuranceNumber;
  final bool isVerified;
  final List<String>? vehicleTypes;
  final List<String>? serviceAreas;
  final Map<String, dynamic>? carrierPreferences;
  final int? totalDeliveries;
  final double? rating;
  final DateTime? verificationDate;
  final bool isAvailable;
  final String? currentLocation;
  final bool isOnboardingComplete;
  final CarrierOnboardingData? onboardingData;

  CarrierModel({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    required DateTime createdAt,
    DateTime? lastLoginAt,
    bool isEmailVerified = false,
    bool isPhoneVerified = false,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
    this.companyName,
    this.businessType,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.licenseNumber,
    this.insuranceNumber,
    this.isVerified = false,
    this.vehicleTypes,
    this.serviceAreas,
    this.carrierPreferences,
    this.totalDeliveries = 0,
    this.rating,
    this.verificationDate,
    this.isAvailable = true,
    this.currentLocation,
    this.isOnboardingComplete = false,
    this.onboardingData,
  }) : super(
          uid: uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          role: UserRole.carrier,
          createdAt: createdAt,
          lastLoginAt: lastLoginAt,
          isEmailVerified: isEmailVerified,
          isPhoneVerified: isPhoneVerified,
          profileImageUrl: profileImageUrl,
          additionalData: additionalData,
        );

  // Factory constructor from Firestore document
  factory CarrierModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CarrierModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      profileImageUrl: data['profileImageUrl'],
      additionalData: data['additionalData'],
      companyName: data['companyName'],
      businessType: data['businessType'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      country: data['country'],
      licenseNumber: data['licenseNumber'],
      insuranceNumber: data['insuranceNumber'],
      isVerified: data['isVerified'] ?? false,
      vehicleTypes: data['vehicleTypes'] != null
          ? List<String>.from(data['vehicleTypes'])
          : null,
      serviceAreas: data['serviceAreas'] != null
          ? List<String>.from(data['serviceAreas'])
          : null,
      carrierPreferences: data['carrierPreferences'],
      totalDeliveries: data['totalDeliveries'] ?? 0,
      rating: data['rating']?.toDouble(),
      verificationDate: data['verificationDate'] != null
          ? (data['verificationDate'] as Timestamp).toDate()
          : null,
      isAvailable: data['isAvailable'] ?? true,
      currentLocation: data['currentLocation'],
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      onboardingData: data['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(data['onboardingData'])
          : null,
    );
  }

  // Factory constructor from JSON
  factory CarrierModel.fromJson(Map<String, dynamic> json) {
    return CarrierModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      profileImageUrl: json['profileImageUrl'],
      additionalData: json['additionalData'],
      companyName: json['companyName'],
      businessType: json['businessType'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
      licenseNumber: json['licenseNumber'],
      insuranceNumber: json['insuranceNumber'],
      isVerified: json['isVerified'] ?? false,
      vehicleTypes: json['vehicleTypes'] != null
          ? List<String>.from(json['vehicleTypes'])
          : null,
      serviceAreas: json['serviceAreas'] != null
          ? List<String>.from(json['serviceAreas'])
          : null,
      carrierPreferences: json['carrierPreferences'],
      totalDeliveries: json['totalDeliveries'] ?? 0,
      rating: json['rating']?.toDouble(),
      verificationDate: json['verificationDate'] != null
          ? DateTime.parse(json['verificationDate'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      currentLocation: json['currentLocation'],
      isOnboardingComplete: json['isOnboardingComplete'] ?? false,
      onboardingData: json['onboardingData'] != null
          ? CarrierOnboardingData.fromJson(json['onboardingData'])
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
      'licenseNumber': licenseNumber,
      'insuranceNumber': insuranceNumber,
      'isVerified': isVerified,
      'vehicleTypes': vehicleTypes,
      'serviceAreas': serviceAreas,
      'carrierPreferences': carrierPreferences,
      'totalDeliveries': totalDeliveries,
      'rating': rating,
      'verificationDate': verificationDate?.toIso8601String(),
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
      'isOnboardingComplete': isOnboardingComplete,
      'onboardingData': onboardingData?.toJson(),
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
      'licenseNumber': licenseNumber,
      'insuranceNumber': insuranceNumber,
      'isVerified': isVerified,
      'vehicleTypes': vehicleTypes,
      'serviceAreas': serviceAreas,
      'carrierPreferences': carrierPreferences,
      'totalDeliveries': totalDeliveries,
      'rating': rating,
      'verificationDate': verificationDate != null 
          ? Timestamp.fromDate(verificationDate!) 
          : null,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
      'isOnboardingComplete': isOnboardingComplete,
      'onboardingData': onboardingData?.toFirestore(),
    });
    return firestore;
  }

  // Copy with method for updates
  CarrierModel copyWithCarrier({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
    String? companyName,
    String? businessType,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? licenseNumber,
    String? insuranceNumber,
    bool? isVerified,
    List<String>? vehicleTypes,
    List<String>? serviceAreas,
    Map<String, dynamic>? carrierPreferences,
    int? totalDeliveries,
    double? rating,
    DateTime? verificationDate,
    bool? isAvailable,
    String? currentLocation,
    bool? isOnboardingComplete,
    CarrierOnboardingData? onboardingData,
  }) {
    return CarrierModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      additionalData: additionalData ?? this.additionalData,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      isVerified: isVerified ?? this.isVerified,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      carrierPreferences: carrierPreferences ?? this.carrierPreferences,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      rating: rating ?? this.rating,
      verificationDate: verificationDate ?? this.verificationDate,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      onboardingData: onboardingData ?? this.onboardingData,
    );
  }

  @override
  String toString() {
    return 'CarrierModel(uid: $uid, email: $email, companyName: $companyName, isVerified: $isVerified)';
  }
}
