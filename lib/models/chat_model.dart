import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? listingId; // Reference to the product listing
  final String? offerId; // Reference to an offer (for offer messages)
  final bool isRead;
  final List<String> deletedBy; // UIDs of users who deleted this message

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.listingId,
    this.offerId,
    this.isRead = false,
    this.deletedBy = const [],
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      listingId: data['listingId'],
      offerId: data['offerId'],
      isRead: data['isRead'] ?? false,
      deletedBy: List<String>.from(data['deletedBy'] ?? []),
    );
  }

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      listingId: data['listingId'],
      offerId: data['offerId'],
      isRead: data['isRead'] ?? false,
      deletedBy: List<String>.from(data['deletedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'listingId': listingId,
      'offerId': offerId,
      'isRead': isRead,
      'deletedBy': deletedBy,
    };
  }
}

enum MessageType { text, image, listing, offer }

class ChatConversation {
  final String id;
  final List<String> participants;
  final String? listingId;
  final String? listingTitle;
  final String? listingImageUrl;
  final String? loadId; // Reference to load (for load negotiations)
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool> unreadCount; // userId -> hasUnreadMessages
  final DateTime? negotiationStartTime; // When first offer was sent
  final DateTime? negotiationExpiresAt; // 12 hours from negotiationStartTime
  final bool isNegotiationActive; // Whether negotiation is active
  final String? activeOfferId; // ID of the current active offer
  final bool isSupport; // Whether this is a support conversation
  final Map<String, DateTime>
  clearedAt; // userId -> timestamp when conversation was cleared

  ChatConversation({
    required this.id,
    required this.participants,
    this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    this.loadId,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = const {},
    this.negotiationStartTime,
    this.negotiationExpiresAt,
    this.isNegotiationActive = false,
    this.activeOfferId,
    this.isSupport = false,
    this.clearedAt = const {},
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      listingId: data['listingId'],
      listingTitle: data['listingTitle'],
      listingImageUrl: data['listingImageUrl'],
      loadId: data['loadId'],
      lastMessage: data['lastMessage'] != null
          ? ChatMessage.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      unreadCount: Map<String, bool>.from(data['unreadCount'] ?? {}),
      negotiationStartTime: data['negotiationStartTime'] != null
          ? (data['negotiationStartTime'] as Timestamp).toDate()
          : null,
      negotiationExpiresAt: data['negotiationExpiresAt'] != null
          ? (data['negotiationExpiresAt'] as Timestamp).toDate()
          : null,
      isNegotiationActive: data['isNegotiationActive'] ?? false,
      activeOfferId: data['activeOfferId'],
      isSupport: data['isSupport'] ?? false,
      clearedAt:
          (data['clearedAt'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as Timestamp).toDate()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
      'loadId': loadId,
      'lastMessage': lastMessage?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
      'negotiationStartTime': negotiationStartTime != null
          ? Timestamp.fromDate(negotiationStartTime!)
          : null,
      'negotiationExpiresAt': negotiationExpiresAt != null
          ? Timestamp.fromDate(negotiationExpiresAt!)
          : null,
      'isNegotiationActive': isNegotiationActive,
      'activeOfferId': activeOfferId,
      'isSupport': isSupport,
      'clearedAt': clearedAt.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
    };
  }

  bool get isNegotiationExpired {
    if (negotiationExpiresAt == null) return false;
    return DateTime.now().isAfter(negotiationExpiresAt!);
  }

  Duration? get negotiationTimeRemaining {
    if (negotiationExpiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(negotiationExpiresAt!)) {
      return Duration.zero;
    }
    return negotiationExpiresAt!.difference(now);
  }

  String getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((id) => id != currentUserId);
    } catch (e) {
      // If no other participant found, return the first participant that's not the current user
      // or return an empty string if no valid participants exist
      if (participants.isEmpty) {
        return '';
      }

      // Try to find any participant that's different from current user
      for (String participantId in participants) {
        if (participantId != currentUserId) {
          return participantId;
        }
      }

      // If all participants are the same as current user (shouldn't happen), return empty string
      return '';
    }
  }
}
