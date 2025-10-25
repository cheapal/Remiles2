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
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      print('Loading conversations for user: ${user.uid}');
      final conversations = await FirebaseService.getUserConversations(user.uid);
      print('Found ${conversations.length} conversations');
      
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
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
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        
        // Debug: Print conversation details
        print('Conversation ${conversation.id}:');
        print('  Participants: ${conversation.participants}');
        print('  Current User: ${user?.uid}');
        
        final otherUserId = conversation.getOtherParticipant(user?.uid ?? '');
        print('  Other User ID: $otherUserId');
        
        // Skip conversations with invalid participants
        if (otherUserId.isEmpty) {
          print('  Skipping conversation due to invalid participants');
          return const SizedBox.shrink();
        }
        
        return _ConversationTile(
          conversation: conversation,
          otherUserId: otherUserId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  conversationId: conversation.id,
                  otherUserId: otherUserId,
                  otherUserName: 'User', // Simplified for now
                  listingTitle: conversation.listingTitle,
                  listingImageUrl: conversation.listingImageUrl,
                  listingId: conversation.listingId,
                ),
              ),
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
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.otherUserId,
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
          if (conversation.unreadCount[otherUserId] == true)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
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