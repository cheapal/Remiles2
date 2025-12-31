import 'dart:async';
import 'package:flutter/material.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/chat_model.dart';
import 'package:provider/provider.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:remiles/services/conversation_tracker.dart';

class SupportChatScreen extends StatefulWidget {
  final String conversationId;
  final String? initialMessage;

  const SupportChatScreen({
    super.key,
    required this.conversationId,
    this.initialMessage,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    // Register this conversation as currently open
    ConversationTracker.setCurrentConversation(widget.conversationId);
    
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _messageController.text = widget.initialMessage!;
      // Auto-send initial message after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _messageController.text.isNotEmpty) {
            _sendMessage();
          }
        });
      });
    }
    _loadMessages();
    _setupMessagesListener();
  }

  @override
  void dispose() {
    // Unregister this conversation when chat screen is closed
    ConversationTracker.clearCurrentConversation();
    
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _setupMessagesListener() {
    _messagesSubscription = FirebaseService.messages
        .where('conversationId', isEqualTo: widget.conversationId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                try {
                  _messages = snapshot.docs
                      .map((doc) => ChatMessage.fromFirestore(doc))
                      .toList()
                      .reversed
                      .toList();
                  _isLoading = false;
                  _errorMessage = null; // Clear any previous errors
                } catch (e) {
                  // If parsing fails, just set empty list
                  _messages = [];
                  _isLoading = false;
                  _errorMessage = null;
                }
              });
              _scrollToBottom();
            }
          },
          onError: (error) {
            // Only set error if it's a real error, not just empty results
            if (mounted) {
              final errorStr = error.toString();
              // Don't treat "no documents" as an error
              if (!errorStr.contains('no documents') && 
                  !errorStr.contains('No documents') &&
                  errorStr.isNotEmpty) {
                setState(() {
                  _errorMessage = errorStr;
                  _isLoading = false;
                });
              } else {
                // Empty results - not an error
                setState(() {
                  _messages = [];
                  _isLoading = false;
                  _errorMessage = null;
                });
              }
            }
          },
        );
  }

  Future<void> _loadMessages() async {
    try {
      if (mounted) {
        setState(() {
          _errorMessage = null; // Clear any previous errors
        });
      }
      
      final snapshot = await FirebaseService.messages
          .where('conversationId', isEqualTo: widget.conversationId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (mounted) {
        setState(() {
          try {
            _messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .toList()
                .reversed
                .toList();
            _isLoading = false;
            _errorMessage = null; // Ensure no error when loading succeeds
          } catch (e) {
            // If parsing fails, just set empty list
            _messages = [];
            _isLoading = false;
            _errorMessage = null;
          }
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      // Only set error if it's a real error, not just empty results
      final errorStr = e.toString();
      if (mounted) {
        if (!errorStr.contains('no documents') && 
            !errorStr.contains('No documents') &&
            errorStr.isNotEmpty) {
          setState(() {
            _errorMessage = errorStr;
            _isLoading = false;
          });
        } else {
          // Empty results - not an error
          setState(() {
            _messages = [];
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        await FirebaseService.sendSupportMessage(
          conversationId: widget.conversationId,
          senderId: user.uid,
          content: _messageController.text.trim(),
        );
        
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5E4A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'We\'re here to help',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _buildMessagesArea(currentUserId),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(String currentUserId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state if there are no messages (regardless of error state)
    // This ensures we don't show error when conversation is just empty
    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMessages,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with our support team',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  // Show error hint if there's an error, but still show empty state
                  if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Note: There was an issue loading messages. Pull down to retry.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Only show error screen if there are messages but we have an error
    // (This shouldn't normally happen, but just in case)
    if (_errorMessage != null && _errorMessage!.isNotEmpty && _messages.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isCurrentUser = message.senderId == currentUserId;
          return _buildMessageBubble(message, isCurrentUser);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2C5E4A),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFF2C5E4A)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(message.timestamp),
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF2C5E4A)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C5E4A),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
