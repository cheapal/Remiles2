import 'package:cloud_firestore/cloud_firestore.dart';

class ShipperOnboardingData {
  final bool isCompleted;
  final DateTime? completedAt;
  final List<String> completedScreens;
  final Map<String, dynamic> responses;
  final DateTime? lastUpdated;

  const ShipperOnboardingData({
    this.isCompleted = false,
    this.completedAt,
    this.completedScreens = const [],
    this.responses = const {},
    this.lastUpdated,
  });

  factory ShipperOnboardingData.fromFirestore(Map<String, dynamic> data) {
    return ShipperOnboardingData(
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedScreens: List<String>.from(data['completedScreens'] ?? []),
      responses: Map<String, dynamic>.from(data['responses'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedScreens': completedScreens,
      'responses': responses,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
    };
  }

  ShipperOnboardingData addResponse(String screenName, Map<String, dynamic> response) {
    final updatedResponses = Map<String, dynamic>.from(responses);
    updatedResponses[screenName] = response;

    final updatedCompletedScreens = Set<String>.from(completedScreens)..add(screenName);

    return ShipperOnboardingData(
      isCompleted: isCompleted,
      completedAt: completedAt,
      completedScreens: updatedCompletedScreens.toList(),
      responses: updatedResponses,
      lastUpdated: DateTime.now(),
    );
  }

  ShipperOnboardingData markComplete() {
    return ShipperOnboardingData(
      isCompleted: true,
      completedAt: DateTime.now(),
      completedScreens: completedScreens,
      responses: responses,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic>? getResponse(String screenName) => responses[screenName] as Map<String, dynamic>?;
}


