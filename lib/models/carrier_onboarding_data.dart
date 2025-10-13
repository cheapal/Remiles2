import 'package:cloud_firestore/cloud_firestore.dart';

class CarrierOnboardingData {
  final bool isCompleted;
  final DateTime? completedAt;
  final Map<String, dynamic> responses;
  final List<String> completedScreens;
  final DateTime? lastUpdated;

  CarrierOnboardingData({
    this.isCompleted = false,
    this.completedAt,
    this.responses = const {},
    this.completedScreens = const [],
    this.lastUpdated,
  });

  // Factory constructor from Firestore document
  factory CarrierOnboardingData.fromFirestore(Map<String, dynamic> data) {
    return CarrierOnboardingData(
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      responses: Map<String, dynamic>.from(data['responses'] ?? {}),
      completedScreens: List<String>.from(data['completedScreens'] ?? []),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  // Factory constructor from JSON
  factory CarrierOnboardingData.fromJson(Map<String, dynamic> json) {
    return CarrierOnboardingData(
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      responses: Map<String, dynamic>.from(json['responses'] ?? {}),
      completedScreens: List<String>.from(json['completedScreens'] ?? []),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'responses': responses,
      'completedScreens': completedScreens,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'responses': responses,
      'completedScreens': completedScreens,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  // Copy with method for updates
  CarrierOnboardingData copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    Map<String, dynamic>? responses,
    List<String>? completedScreens,
    DateTime? lastUpdated,
  }) {
    return CarrierOnboardingData(
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      responses: responses ?? this.responses,
      completedScreens: completedScreens ?? this.completedScreens,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Helper method to add a response for a specific screen
  CarrierOnboardingData addResponse(String screenName, Map<String, dynamic> response) {
    final updatedResponses = Map<String, dynamic>.from(responses);
    updatedResponses[screenName] = response;
    
    final updatedCompletedScreens = List<String>.from(completedScreens);
    if (!updatedCompletedScreens.contains(screenName)) {
      updatedCompletedScreens.add(screenName);
    }
    
    return copyWith(
      responses: updatedResponses,
      completedScreens: updatedCompletedScreens,
      lastUpdated: DateTime.now(),
    );
  }

  // Helper method to mark onboarding as complete
  CarrierOnboardingData markComplete() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  // Helper method to check if a specific screen is completed
  bool isScreenCompleted(String screenName) {
    return completedScreens.contains(screenName);
  }

  // Helper method to get response for a specific screen
  Map<String, dynamic>? getResponse(String screenName) {
    return responses[screenName];
  }

  @override
  String toString() {
    return 'CarrierOnboardingData(isCompleted: $isCompleted, completedScreens: $completedScreens, responses: $responses)';
  }
}
