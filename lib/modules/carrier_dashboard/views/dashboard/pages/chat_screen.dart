
import 'package:flutter/material.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/chat_model.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_market_place_product_page.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? listingTitle;
  final String? listingImageUrl;
  final String? listingId;
  final String? preFilledMessage;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.listingTitle,
    this.listingImageUrl,
    this.listingId,
    this.preFilledMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasTimedOut = false;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill message if provided
    if (widget.preFilledMessage != null && widget.preFilledMessage!.isNotEmpty) {
      _messageController.text = widget.preFilledMessage!;
    }
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      print('Loading messages for conversation: ${widget.conversationId}');
      
      // Check if conversation ID is valid
      if (widget.conversationId.isEmpty) {
        print('Conversation ID is empty');
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid conversation ID';
            _isLoading = false;
          });
        }
        return;
      }
      
      // Add timeout to prevent infinite loading
      final messages = await FirebaseService.getConversationMessagesOnce(widget.conversationId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Message loading timed out');
              throw Exception('Message loading timed out');
            },
          );
      
      print('Loaded ${messages.length} messages');
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _viewListingDetails() async {
    if (widget.listingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing details not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Fetch the full listing details
      final listing = await FirebaseService.getProductListingById(widget.listingId!);
      if (listing != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPagePrecise(listing: listing),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load listing: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        await FirebaseService.sendMessage(
          conversationId: widget.conversationId,
          senderId: user.uid,
          receiverId: widget.otherUserId,
          content: _messageController.text.trim(),
        );
        
        _messageController.clear();
        
        // Reload messages to show the new one
        await _loadMessages();
        
        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5E4A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.listingTitle != null)
              Text(
                widget.listingTitle!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.listingImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.listingImageUrl!),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Listing info card
          if (widget.listingTitle != null)
            GestureDetector(
              onTap: _viewListingDetails,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    if (widget.listingImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          widget.listingImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    if (widget.listingImageUrl != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.listingTitle!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap to view details',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          // Chat messages area
          Expanded(
            child: _buildMessagesArea(),
          ),
          // Message input field
          _MessageInputField(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    print('Building messages area - Loading: $_isLoading, Messages: ${_messages.length}, Error: $_errorMessage');
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Failed to load messages',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadMessages();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = false;
                  _errorMessage = null;
                  _messages = []; // Show empty state instead
                });
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
    }
    
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the conversation below',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        final isMe = user?.uid == message.senderId;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: isMe 
              ? _SentMessage(text: message.content)
              : _ReceivedMessage(text: message.content),
        );
      },
    );
  }

  Widget _buildMessagesAreaStream() {
    return StreamBuilder<List<ChatMessage>>(
      stream: FirebaseService.getConversationMessages(widget.conversationId),
      builder: (context, snapshot) {
                print('Chat Stream - Connection State: ${snapshot.connectionState}');
                print('Chat Stream - Has Error: ${snapshot.hasError}');
                print('Chat Stream - Error: ${snapshot.error}');
                print('Chat Stream - Has Data: ${snapshot.hasData}');
                print('Chat Stream - Data: ${snapshot.data}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  if (_hasTimedOut) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading timeout',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Unable to load messages',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasTimedOut = false;
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh the stream
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final messages = snapshot.data ?? [];
                print('Messages count: ${messages.length}');
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final user = authProvider.currentUser;
                    final isMe = user?.uid == message.senderId;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: isMe 
                          ? _SentMessage(text: message.content)
                          : _ReceivedMessage(text: message.content),
                    );
                  },
                );
      },
    );
  }
}

// Widget for a sent message bubble (right side)
class _SentMessage extends StatelessWidget {
  final String text;
  const _SentMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C5E4A), // Dark green
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

// Widget for a received message bubble (left side)
class _ReceivedMessage extends StatelessWidget {
  final String text;
  const _ReceivedMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with online indicator
        Stack(
          children: [
             CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person_outline, color: Colors.black),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Message bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// Widget for the text input field at the bottom
class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputField({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.grey),
            onPressed: () { /* Handle add button press */ },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF2C5E4A)),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
