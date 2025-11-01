import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/chat_model.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:flutter/material.dart';


class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TopNavigationBar(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Text(
                    'Messages',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildConversationsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'User not logged in',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ChatConversation>>(
      stream: FirebaseService.getUserConversationsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Error loading conversations',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your conversations will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final user = authProvider.currentUser;
            
            final otherUserId = conversation.getOtherParticipant(user?.uid ?? '');
            
            // Skip conversations with invalid participants
            if (otherUserId.isEmpty || user == null) {
              return const SizedBox.shrink();
            }
            
            // Get current user ID for unread check
            final currentUserId = user.uid;
            
            return _ConversationTile(
              conversation: conversation,
              otherUserId: otherUserId,
              currentUserId: currentUserId,
              onTap: () async {
                // Get other user's name
                String otherUserName = 'User';
                try {
                  final shipperDoc = await FirebaseService.shippers.doc(otherUserId).get();
                  if (shipperDoc.exists) {
                    final data = shipperDoc.data() as Map<String, dynamic>?;
                    otherUserName = data?['companyName'] ?? data?['displayName'] ?? data?['name'] ?? 'Shipper';
                  } else {
                    final carrierDoc = await FirebaseService.carriers.doc(otherUserId).get();
                    if (carrierDoc.exists) {
                      final data = carrierDoc.data() as Map<String, dynamic>?;
                      otherUserName = data?['companyName'] ?? data?['displayName'] ?? 'Carrier';
                    }
                  }
                } catch (e) {
                  print('Error fetching user name: $e');
                }

                // Get load details if this is a load conversation
                String? loadId = conversation.loadId;
                double? loadPrice;
                
                if (loadId != null) {
                  // Try to find the load to get price
                  try {
                    final shippersSnapshot = await FirebaseService.shippers.get();
                    for (final shipperDoc in shippersSnapshot.docs) {
                      final loadDoc = await FirebaseService.shippers
                          .doc(shipperDoc.id)
                          .collection('loads')
                          .doc(loadId)
                          .get();
                      if (loadDoc.exists) {
                        final loadData = loadDoc.data();
                        loadPrice = (loadData?['price'] as num?)?.toDouble();
                        break;
                      }
                    }
                  } catch (e) {
                    print('Error fetching load price: $e');
                  }
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        listingTitle: conversation.listingTitle,
                        listingImageUrl: conversation.listingImageUrl,
                        listingId: conversation.listingId,
                        loadId: loadId,
                        loadPrice: loadPrice,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final String otherUserId;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.otherUserId,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFF1E5B3D);
    const Color hintColor = Colors.grey;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: iconColor,
        child: Text(
          conversation.listingTitle?.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        conversation.listingTitle ?? 'Product Inquiry',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.lastMessage?.content ?? 'No messages yet',
        style: const TextStyle(
          color: hintColor,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (conversation.lastMessage != null)
            Text(
              _formatTime(conversation.lastMessage!.timestamp),
              style: const TextStyle(
                color: hintColor,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          if (conversation.unreadCount[currentUserId] == true)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}