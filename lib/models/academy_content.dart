import 'package:cloud_firestore/cloud_firestore.dart';

class AcademyContent {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? documentUrl;
  final String contentType; // 'video' or 'document'
  final List<String> tags;
  final String? playlistId;
  final String? playlistName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order;

  AcademyContent({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.documentUrl,
    required this.contentType,
    this.tags = const [],
    this.playlistId,
    this.playlistName,
    required this.createdAt,
    required this.updatedAt,
    this.order = 0,
  });

  // Factory constructor from Firestore document
  factory AcademyContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AcademyContent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      videoUrl: data['videoUrl'],
      documentUrl: data['documentUrl'],
      contentType: data['contentType'] ?? 'video',
      tags: List<String>.from(data['tags'] ?? []),
      playlistId: data['playlistId'],
      playlistName: data['playlistName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: data['order'] ?? 0,
    );
  }

  // Factory constructor from JSON
  factory AcademyContent.fromJson(Map<String, dynamic> json) {
    return AcademyContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      videoUrl: json['videoUrl'],
      documentUrl: json['documentUrl'],
      contentType: json['contentType'] ?? 'video',
      tags: List<String>.from(json['tags'] ?? []),
      playlistId: json['playlistId'],
      playlistName: json['playlistName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      order: json['order'] ?? 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'documentUrl': documentUrl,
      'contentType': contentType,
      'tags': tags,
      'playlistId': playlistId,
      'playlistName': playlistName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order': order,
    };
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'documentUrl': documentUrl,
      'contentType': contentType,
      'tags': tags,
      'playlistId': playlistId,
      'playlistName': playlistName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'order': order,
    };
  }

  // Copy with method for updates
  AcademyContent copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    String? documentUrl,
    String? contentType,
    List<String>? tags,
    String? playlistId,
    String? playlistName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
  }) {
    return AcademyContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      playlistId: playlistId ?? this.playlistId,
      playlistName: playlistName ?? this.playlistName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
    );
  }
}

