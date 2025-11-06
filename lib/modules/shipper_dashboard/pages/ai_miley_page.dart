import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/auth_provider.dart';

// Define the primary color for reuse
const Color primaryGreen = Color(0xFF1E4620);

class AiMileyScreen extends StatefulWidget {
  const AiMileyScreen({super.key});

  @override
  State<AiMileyScreen> createState() => _AiMileyScreenState();
}

class _AiMileyScreenState extends State<AiMileyScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isTyping = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _addWelcomeMessage();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
              if (_recognizedText.isNotEmpty) {
                _messageController.text = _recognizedText;
                _recognizedText = '';
              }
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition error: ${error.errorMsg}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
    
    if (mounted) {
      setState(() {
        _speechAvailable = available;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final authProvider = context.read<AuthProvider>();
    final shipper = authProvider.shipperUser;
    final userName = shipper?.companyName ?? 
                     shipper?.displayName ?? 
                     authProvider.currentUser?.displayName ?? 
                     'there';
    
    final greeting = _getGreeting();
    
    setState(() {
      _messages.add(ChatMessage(
        text: '$greeting $userName! 👋\n\nI\'m Miley, your AI assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    // Scroll to bottom after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
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
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate AI typing
    setState(() {
      _isTyping = true;
    });

    // Simulate AI response delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Generate AI response
    final response = _generateAIResponse(text);
    
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  String _generateAIResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // Help with posting loads
    if (lowerMessage.contains('post') && lowerMessage.contains('load')) {
      return 'To post a load, go to the "Manage Loads" tab and tap "Post a New Load". Fill in pickup and delivery locations, dates, load specifications, and any special requirements. Need help with any specific step?';
    }
    
    // Help with subscriptions
    if (lowerMessage.contains('subscription') || lowerMessage.contains('plan') || lowerMessage.contains('upgrade')) {
      return 'You can manage your subscription in "Boost My Page". We offer three plans:\n\n• Starter Bundle: \$99/month - 10 load postings + 1 Boost\n• Pro Bundle: \$249/month - 25 load postings + 5 Boosts\n• Enterprise Bundle: \$449/month - Unlimited postings + 10 Boosts\n\nWould you like to upgrade?';
    }
    
    // Help with managing loads
    if (lowerMessage.contains('manage') || lowerMessage.contains('edit') || lowerMessage.contains('delete')) {
      return 'To manage your loads, go to "Manage Loads" tab. You can:\n\n• View all your loads by status\n• Edit active loads\n• Delete loads\n• Track load progress\n\nWhat would you like to do?';
    }
    
    // Help with payments
    if (lowerMessage.contains('payment') || lowerMessage.contains('billing') || lowerMessage.contains('invoice')) {
      return 'You can manage your payment methods in Profile > Payment Method. For billing questions or to view invoices, check your subscription history in "Boost My Page". Need help with something specific?';
    }
    
    // Help with account
    if (lowerMessage.contains('account') || lowerMessage.contains('profile') || lowerMessage.contains('settings')) {
      return 'You can update your account information in Profile > Account Details. For settings like password changes, go to Profile > Settings. What would you like to update?';
    }
    
    // General help
    if (lowerMessage.contains('help') || lowerMessage.contains('how')) {
      return 'I\'m here to help! I can assist you with:\n\n• Posting and managing loads\n• Subscription plans and upgrades\n• Account settings\n• Payment and billing\n• General app usage\n\nWhat do you need help with?';
    }
    
    // Greetings
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hey')) {
      return 'Hello! How can I assist you today?';
    }
    
    // Thank you
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    }
    
    // Default response
    return 'I understand you\'re asking about "$userMessage". Let me help you with that. Could you provide a bit more detail? I can assist with:\n\n• Load posting and management\n• Subscription plans\n• Account settings\n• Payment and billing\n• General app questions';
  }

  Future<void> _startVoiceInput() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check and request microphone permission
    final micPermission = await Permission.microphone.status;
    if (!micPermission.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required for voice input'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (_isListening) {
      // Stop listening
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      // Start listening
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _recognizedText = result.recognizedWords;
              if (result.finalResult) {
                _messageController.text = result.recognizedWords;
                _recognizedText = '';
                _isListening = false;
                // Auto-send if there's text
                if (result.recognizedWords.trim().isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      _sendMessage();
                    }
                  });
                }
              }
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final shipper = authProvider.shipperUser;
    final userName = shipper?.companyName ?? 
                     shipper?.displayName ?? 
                     authProvider.currentUser?.displayName ?? 
                     'User';
    
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: primaryGreen,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Miley',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AiAvatar(),
                        const SizedBox(height: 24),
                        Text(
                          '$greeting\n$userName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          // Message input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show recognized text when listening
                  if (_isListening && _recognizedText.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _recognizedText,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _isListening ? 'Listening...' : 'Type your message...',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: _isListening 
                                ? Colors.red.shade50 
                                : Colors.grey.shade200,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            enabled: !_isListening,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) {
                            if (!_isListening) {
                              _sendMessage();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Voice icon button
                      GestureDetector(
                        onTap: _startVoiceInput,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isListening 
                                ? Colors.red 
                                : primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      if (!_isListening) ...[
                        const SizedBox(width: 8),
                        // Send button
                        GestureDetector(
                          onTap: _sendMessage,
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: primaryGreen,
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: primaryGreen,
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? primaryGreen
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                color: Colors.grey.shade700,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: primaryGreen,
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animatedValue = ((value + delay) % 1.0);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(0.3 + (animatedValue * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) {
          setState(() {});
        }
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final Color lightGreen = HSLColor.fromColor(primaryGreen).withLightness(0.25).toColor();

    return CircleAvatar(
      radius: 70,
      backgroundColor: lightGreen,
      child: CircleAvatar(
        radius: 60,
        backgroundColor: primaryGreen,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.headset_mic,
              color: Colors.white.withOpacity(0.8),
              size: 70,
            ),
            const Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
