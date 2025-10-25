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
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.listingId,
    this.isRead = false,
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
      isRead: data['isRead'] ?? false,
    );
  }

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
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
      isRead: data['isRead'] ?? false,
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
      'isRead': isRead,
    };
  }
}

enum MessageType { text, image, listing }

class ChatConversation {
  final String id;
  final List<String> participants;
  final String? listingId;
  final String? listingTitle;
  final String? listingImageUrl;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, bool> unreadCount; // userId -> hasUnreadMessages

  ChatConversation({
    required this.id,
    required this.participants,
    this.listingId,
    this.listingTitle,
    this.listingImageUrl,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = const {},
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      listingId: data['listingId'],
      listingTitle: data['listingTitle'],
      listingImageUrl: data['listingImageUrl'],
      lastMessage: data['lastMessage'] != null 
          ? ChatMessage.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      unreadCount: Map<String, bool>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImageUrl': listingImageUrl,
      'lastMessage': lastMessage?.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
    };
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
