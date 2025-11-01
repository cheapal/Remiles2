
import 'package:flutter/material.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/models/chat_model.dart';
import 'package:Remiles/models/offer_model.dart';
import 'package:Remiles/models/user_model.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/negotiation_timer.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/offer_dialog.dart';
import 'package:Remiles/modules/shipper_dashboard/widgets/counter_offer_dialog.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/user_profile_dialog.dart';
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
  final String? loadId; // For load negotiations
  final double? loadPrice; // For load negotiations
  final String? preFilledMessage;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.listingTitle,
    this.listingImageUrl,
    this.listingId,
    this.loadId,
    this.loadPrice,
    this.preFilledMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  ChatConversation? _conversation;
  bool _isNegotiationExpired = false;
  bool _canSendMessages = true; // Can send messages (not expired for non-booked carriers)
  Map<String, OfferModel> _offersCache = {}; // Cache offers by offerId
  OfferModel? _activeOffer; // Current active offer for this conversation
  bool _isLoadBooked = false; // Track if load is booked
  bool _isProcessingOffer = false; // Track if offer is being processed
  String? _loadShipperId; // Track shipper ID for the load
  String? _otherUserProfileImage; // Profile image of the other user

  @override
  void initState() {
    super.initState();
    // Pre-fill message if provided
    if (widget.preFilledMessage != null && widget.preFilledMessage!.isNotEmpty) {
      _messageController.text = widget.preFilledMessage!;
    }
    _loadConversation();
    _loadMessages();
    
    // Check timer expiration periodically
    if (widget.loadId != null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _checkTimerExpiration();
        }
      });
    }
  }

  Future<void> _loadConversation() async {
    try {
      final convDoc = await FirebaseService.conversations.doc(widget.conversationId).get();
      if (convDoc.exists) {
        setState(() {
          _conversation = ChatConversation.fromFirestore(convDoc);
          _isNegotiationExpired = _conversation?.isNegotiationExpired ?? false;
          _updateCanSendMessages();
        });
      }
      
      // Check if load is booked
      if (widget.loadId != null) {
        await _checkLoadStatus();
      }
      
      // Load other user's profile image
      await _loadOtherUserProfile();
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  Future<void> _loadOtherUserProfile() async {
    try {
      // Try to get user profile image
      final shipper = await FirebaseService.getShipper(widget.otherUserId);
      if (shipper != null && shipper.profileImageUrl != null) {
        if (mounted) {
          setState(() {
            _otherUserProfileImage = shipper.profileImageUrl;
          });
        }
        return;
      }
      
      final carrier = await FirebaseService.getCarrier(widget.otherUserId);
      if (carrier != null && carrier.profileImageUrl != null && mounted) {
        setState(() {
          _otherUserProfileImage = carrier.profileImageUrl;
        });
      }
    } catch (e) {
      print('Error loading other user profile: $e');
    }
  }

  Future<void> _checkLoadStatus() async {
    try {
      if (widget.loadId == null) return;
      
      // Find the load in shipper subcollections
      final shippersSnapshot = await FirebaseService.shippers.get();
      for (final shipperDoc in shippersSnapshot.docs) {
        final loadDoc = await FirebaseService.shippers
            .doc(shipperDoc.id)
            .collection('loads')
            .doc(widget.loadId!)
            .get();
        
        if (loadDoc.exists) {
          final loadData = loadDoc.data();
          final status = loadData?['status'] as String?;
          
          if (mounted) {
            setState(() {
              _isLoadBooked = status == 'booked';
              _loadShipperId = shipperDoc.id; // Store shipper ID from the load
            });
          }
          break;
        }
      }
    } catch (e) {
      print('Error checking load status: $e');
    }
  }

  void _updateCanSendMessages() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) {
      _canSendMessages = false;
      return;
    }

    // If it's a load negotiation and timer expired
    if (widget.loadId != null && _isNegotiationExpired) {
      // Check if user is the booked carrier (they can still chat after booking)
      try {
        // Try to find if this carrier booked the load
        final shippersSnapshot = await FirebaseService.firestore.collection('shippers').get();
        bool isBookedByThisCarrier = false;
        
        for (final shipperDoc in shippersSnapshot.docs) {
          final loadDoc = await FirebaseService.firestore
              .collection('shippers')
              .doc(shipperDoc.id)
              .collection('loads')
              .doc(widget.loadId!)
              .get();
          
          if (loadDoc.exists) {
            final loadData = loadDoc.data();
            if (loadData != null && loadData['bookedByCarrierId'] == user.uid) {
              isBookedByThisCarrier = true;
              break;
            }
          }
        }
        
        _canSendMessages = isBookedByThisCarrier;
      } catch (e) {
        _canSendMessages = false;
      }
    } else {
      _canSendMessages = true;
    }
    
    if (mounted) {
      setState(() {});
    }
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
      
      // Load offers for offer messages
      final offersToLoad = <String>{};
      for (final message in messages) {
        if (message.type == MessageType.offer && message.offerId != null) {
          offersToLoad.add(message.offerId!);
        }
      }
      
      // Load all offers
      for (final offerId in offersToLoad) {
        final offer = await FirebaseService.getOfferById(offerId);
        if (offer != null) {
          _offersCache[offerId] = offer;
          // Track active offer for this conversation
          if (offer.conversationId == widget.conversationId && 
              (offer.status == OfferStatus.pending || offer.status == OfferStatus.counterOffered) &&
              offer.isActive) {
            _activeOffer = offer;
          }
        }
      }
      
      // Also check conversation's activeOfferId
      if (_conversation?.activeOfferId != null) {
        final activeOfferId = _conversation!.activeOfferId!;
        if (!_offersCache.containsKey(activeOfferId)) {
          final offer = await FirebaseService.getOfferById(activeOfferId);
          if (offer != null) {
            _offersCache[activeOfferId] = offer;
            if (offer.isActive) {
              _activeOffer = offer;
            }
          }
        } else if (_offersCache[activeOfferId]!.isActive) {
          _activeOffer = _offersCache[activeOfferId];
        }
      }
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _errorMessage = null;
        });
        
        // Check load status after loading messages
        if (widget.loadId != null) {
          _checkLoadStatus();
        }
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

  Future<void> _sendOffer(double offerAmount) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final carrier = authProvider.carrierUser;
      
      if (user == null || widget.loadId == null) return;

      final carrierName = carrier?.companyName ?? user.displayName ?? 'Carrier';
      
      await FirebaseService.sendOffer(
        conversationId: widget.conversationId,
        carrierId: user.uid,
        carrierName: carrierName,
        shipperId: widget.otherUserId,
        loadId: widget.loadId!,
        offerAmount: offerAmount,
      );

      // Reload conversation and messages
      await _loadConversation();
      await _loadMessages();
      
      // Scroll to bottom to show new offer
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptOffer(String offerId) async {
    if (_isProcessingOffer) return; // Prevent multiple simultaneous requests
    
    try {
      if (widget.loadId == null) return;

      final offer = _offersCache[offerId];
      if (offer == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final isCarrier = user?.uid == offer.carrierId;

      // Show loading dialog
      if (mounted) {
        setState(() {
          _isProcessingOffer = true;
        });
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing offer...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Process offer with timeout
      final success = await FirebaseService.acceptOffer(
        offerId: offerId,
        loadId: widget.loadId!,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            setState(() {
              _isProcessingOffer = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request timed out. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return false;
        },
      );

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Send acceptance message
        final acceptedPrice = offer.counterOfferAmount ?? offer.offerAmount;
        final messageText = isCarrier
            ? 'Offer accepted at \$${acceptedPrice.toStringAsFixed(2)} by carrier'
            : 'Offer accepted at \$${acceptedPrice.toStringAsFixed(2)} by shipper';
        
        await FirebaseService.sendMessage(
          conversationId: widget.conversationId,
          senderId: user!.uid,
          receiverId: widget.otherUserId,
          content: messageText,
        );

        // Reload everything
        await _checkLoadStatus();
        await _loadConversation();
        await _loadMessages();
        
        if (mounted) {
          setState(() {
            _isProcessingOffer = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer accepted! Load has been booked.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessingOffer = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to accept offer. Load may have been booked by another carrier.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        setState(() {
          _isProcessingOffer = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCounterOffer(String offerId, double counterAmount) async {
    try {
      await FirebaseService.sendCounterOffer(
        offerId: offerId,
        counterAmount: counterAmount,
      );

      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send counter-offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectOffer(String offerId) async {
    try {
      await FirebaseService.rejectOffer(offerId);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBookAtOriginalPrice() async {
    if (_isProcessingOffer) return; // Prevent multiple simultaneous requests
    
    try {
      if (widget.loadId == null || widget.loadPrice == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) return;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Book at Original Price'),
          content: Text(
            'Do you want to book this load at the original price of \$${widget.loadPrice!.toStringAsFixed(2)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Book Now'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading dialog
      if (mounted) {
        setState(() {
          _isProcessingOffer = true;
        });
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Booking load...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Book the load at original price with timeout
      final success = await FirebaseService.bookLoad(
        loadId: widget.loadId!,
        carrierUid: user.uid,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            setState(() {
              _isProcessingOffer = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request timed out. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return false;
        },
      );

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Send acceptance message
        await FirebaseService.sendMessage(
          conversationId: widget.conversationId,
          senderId: user.uid,
          receiverId: widget.otherUserId,
          content: 'Load booked at original price of \$${widget.loadPrice!.toStringAsFixed(2)} by carrier',
        );

        // Reload everything
        await _checkLoadStatus();
        await _loadConversation();
        await _loadMessages();
        
        if (mounted) {
          setState(() {
            _isProcessingOffer = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load booked successfully at original price!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessingOffer = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to book load. It may have been booked by another carrier.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        setState(() {
          _isProcessingOffer = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking load: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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

    if (!_canSendMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Negotiation timer has expired. You can only chat if you booked this load.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

  void _checkTimerExpiration() {
    if (_conversation != null && widget.loadId != null) {
      final wasExpired = _isNegotiationExpired;
      final isNowExpired = _conversation!.isNegotiationExpired;
      
      if (wasExpired != isNowExpired) {
        setState(() {
          _isNegotiationExpired = isNowExpired;
          _updateCanSendMessages();
        });
      }
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
            // Sticky timer for load negotiations (hide if booked)
            if (!_isLoadBooked &&
                widget.loadId != null && 
                ((_conversation != null && 
                  _conversation!.isNegotiationActive &&
                  _conversation!.negotiationExpiresAt != null) ||
                 (_activeOffer != null && _activeOffer!.isActive)))
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: NegotiationTimer(
                  expiresAt: _conversation?.negotiationExpiresAt ?? _activeOffer!.expiresAt,
                  isExpired: _isNegotiationExpired || 
                            (_activeOffer != null && _activeOffer!.expiresAt.isBefore(DateTime.now())),
                ),
              ),
          ],
        ),
        leading: Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
             
            ],
          ),
        ),
        actions: [
          // Report button
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            onPressed: () => _showReportDialog(),
            tooltip: 'Report',
          ),
          if (widget.listingImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.listingImageUrl!),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
             GestureDetector(
                onTap: _showProfileDialog,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0,right: 14),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _otherUserProfileImage != null
                        ? NetworkImage(_otherUserProfileImage!)
                        : null,
                    child: _otherUserProfileImage == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          // Sticky action buttons bar (for load negotiations)
          if (widget.loadId != null && widget.loadPrice != null)
            _buildStickyActionBar(),
          // Listing info card (for product listings)
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
            enabled: _canSendMessages,
          ),
        ],
      ),
      // Floating action button removed - using button in load info card instead
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
      itemCount: (widget.loadId != null && widget.loadPrice != null ? 1 : 0) + _messages.length,
      itemBuilder: (context, index) {
        // Show load info as first "message" bubble
        if (widget.loadId != null && widget.loadPrice != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLoadInfoMessage(),
          );
        }
        
        final messageIndex = widget.loadId != null && widget.loadPrice != null 
            ? index - 1 
            : index;
        final message = _messages[messageIndex];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        final isMe = user?.uid == message.senderId;
        
        // Handle offer messages differently
        if (message.type == MessageType.offer && message.offerId != null) {
          final offer = _offersCache[message.offerId!];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOfferMessage(message, offer, isMe),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: isMe 
              ? _SentMessage(text: message.content)
              : _ReceivedMessage(text: message.content),
        );
      },
    );
  }


  Widget _buildLoadInfoMessage() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '\$${widget.loadPrice!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(color: primaryColor),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Load #${widget.loadId!.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                ),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyActionBar() {
    return Builder(
      builder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        bool carrierCheck = false;
        bool isShipper = false;
        
        if (currentUser != null) {
          if (_activeOffer != null) {
            carrierCheck = currentUser.uid == _activeOffer!.carrierId;
            isShipper = currentUser.uid == _activeOffer!.shipperId;
          } else {
            // If no active offer but we have loadId, check if current user is the shipper
            if (widget.loadId != null && _loadShipperId != null) {
              // Use the shipper ID from the load document
              isShipper = currentUser.uid == _loadShipperId;
              carrierCheck = !isShipper;
            } else if (widget.loadId != null) {
              // Fallback: assume otherUserId is the shipper if we're viewing from carrier side
              isShipper = currentUser.uid == widget.otherUserId;
              carrierCheck = !isShipper;
            } else {
              carrierCheck = currentUser.uid != widget.otherUserId;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // For Carriers only (hide buttons if load is booked or user is shipper)
              if (!_isLoadBooked && !isShipper && (carrierCheck || (currentUser != null && _activeOffer == null))) ...[
                // Book at Original Price button (always available unless already booked)
                if (_activeOffer?.status != OfferStatus.accepted &&
                    (_conversation == null || !_conversation!.isNegotiationActive || !_isNegotiationExpired))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleBookAtOriginalPrice,
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      label: Text(
                        'Book @ \$${widget.loadPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                // Accept button (if counter-offer received)
                if (_activeOffer != null &&
                    _activeOffer!.status == OfferStatus.counterOffered &&
                    _activeOffer!.isActive &&
                    !_isNegotiationExpired)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAcceptOffer(_activeOffer!.id),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text(
                        'Accept',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                // Make Offer button
                if (_activeOffer?.status != OfferStatus.accepted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isNegotiationExpired ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => OfferDialog(
                            currentPrice: widget.loadPrice!,
                            onSendOffer: _sendOffer,
                          ),
                        );
                      },
                      icon: Icon(
                        _activeOffer == null ? Icons.add : Icons.reply,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _activeOffer == null ? 'Make Offer' : 'New Offer',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNegotiationExpired 
                            ? Colors.grey 
                            : primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
              // For Shippers (hide if load is booked)
              if (!_isLoadBooked &&
                  !carrierCheck && 
                  _activeOffer != null &&
                  (_activeOffer!.status == OfferStatus.pending || 
                   _activeOffer!.status == OfferStatus.counterOffered) &&
                  _activeOffer!.isActive &&
                  !_isNegotiationExpired)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                      builder: (context) => CounterOfferDialog(
                        originalOfferAmount: _activeOffer!.counterOfferAmount ?? _activeOffer!.offerAmount,
                        currentPrice: widget.loadPrice,
                        onCounterOffer: (amount) => _handleCounterOffer(_activeOffer!.id, amount),
                        onAccept: () => _handleAcceptOffer(_activeOffer!.id),
                        onReject: () => _handleRejectOffer(_activeOffer!.id),
                      ),
                      );
                    },
                    icon: const Icon(Icons.attach_money, color: Colors.white, size: 18),
                    label: const Text(
                      'Respond',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfferMessage(ChatMessage message, OfferModel? offer, bool isMe) {
    if (offer == null) {
      // Fallback if offer not loaded
      return isMe 
          ? _SentMessage(text: message.content)
          : _ReceivedMessage(text: message.content);
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final isShipper = user?.uid == offer.shipperId;
    final isAccepted = offer.status == OfferStatus.accepted || _isLoadBooked;
    final isGreyedOut = isAccepted || offer.status == OfferStatus.rejected;

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: isGreyedOut ? 0.5 : 1.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAccepted
                    ? Colors.green.shade50
                    : isMe 
                        ? primaryColor.withOpacity(0.1) 
                        : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAccepted
                      ? Colors.green
                      : isMe 
                          ? primaryColor 
                          : Colors.blue.shade300,
                  width: 2,
                ),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: isMe ? primaryColor : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Offer: \$${offer.offerAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMe ? primaryColor : Colors.blue.shade900,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              if (offer.counterOfferAmount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Counter-offer: \$${offer.counterOfferAmount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _getOfferStatusText(offer.status),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
            ),
          ),
        ),
        // Action buttons for shippers on pending/counter-offered offers (hide if booked)
        if (!_isLoadBooked &&
            isShipper && !isMe && 
            (offer.status == OfferStatus.pending || offer.status == OfferStatus.counterOffered) &&
            offer.isActive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CounterOfferDialog(
                        originalOfferAmount: offer.counterOfferAmount ?? offer.offerAmount,
                        currentPrice: widget.loadPrice,
                        onCounterOffer: (amount) => _handleCounterOffer(offer.id, amount),
                        onAccept: () => _handleAcceptOffer(offer.id),
                        onReject: () => _handleRejectOffer(offer.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Respond'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getOfferStatusText(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return 'Pending response';
      case OfferStatus.accepted:
        return 'Offer accepted';
      case OfferStatus.rejected:
        return 'Offer rejected';
      case OfferStatus.counterOffered:
        return 'Counter-offer made';
      case OfferStatus.expired:
        return 'Offer expired';
    }
  }

  void _showProfileDialog() {
    // Determine user role if we have an active offer
    UserRole? userRole;
    if (_activeOffer != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        if (user.uid == _activeOffer!.shipperId) {
          userRole = UserRole.shipper;
        } else if (user.uid == _activeOffer!.carrierId) {
          userRole = UserRole.carrier;
        }
      }
    } else if (_loadShipperId != null && widget.otherUserId == _loadShipperId) {
      userRole = UserRole.shipper;
    }

    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(
        userId: widget.otherUserId,
        userName: widget.otherUserName,
        userRole: userRole,
        onReport: () => _showReportDialog(),
      ),
    );
  }

  void _showReportDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final isCarrier = user != null && 
        (widget.loadId == null || (_activeOffer != null && user.uid == _activeOffer!.carrierId));
    
    // Determine what/who is being reported
    String reportedEntityName;
    
    if (widget.loadId != null) {
      // Reporting in load negotiation context
      if (isCarrier) {
        reportedEntityName = widget.otherUserName;
      } else {
        reportedEntityName = _activeOffer?.carrierName ?? widget.otherUserName;
      }
    } else {
      // Reporting in general conversation
      reportedEntityName = widget.otherUserName;
    }

    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reporting: $reportedEntityName'),
              if (widget.loadId != null) ...[
                const SizedBox(height: 8),
                Text('Load ID: ${widget.loadId}'),
              ],
              const SizedBox(height: 16),
              const Text('Reason for reporting:'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Please describe the issue...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for reporting'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Submit report to Firebase
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final reporter = authProvider.currentUser;
              
              if (reporter == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You must be logged in to submit a report'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final success = await FirebaseService.submitReport(
                reporterId: reporter.uid,
                reportedUserId: widget.otherUserId,
                reportedUserName: reportedEntityName,
                reason: reasonController.text.trim(),
                loadId: widget.loadId,
                conversationId: widget.conversationId,
                offerId: _activeOffer?.id,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Report submitted successfully' 
                        : 'Failed to submit report. Please try again.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFF2C5E4A), // Dark green
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
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
        // Message bubble with constraints to prevent overflow
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
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
  final bool enabled;

  const _MessageInputField({
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: enabled ? Colors.grey : Colors.grey.shade400),
            onPressed: enabled ? () { /* Handle add button press */ } : null,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: TextStyle(color: enabled ? Colors.black : Colors.grey),
              decoration: InputDecoration(
                hintText: enabled ? 'Type a message...' : 'Negotiation expired',
                hintStyle: TextStyle(color: enabled ? Colors.grey : Colors.grey.shade400),
                border: InputBorder.none,
              ),
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send, 
              color: enabled ? const Color(0xFF2C5E4A) : Colors.grey.shade400,
            ),
            onPressed: enabled ? onSend : null,
          ),
        ],
      ),
    );
  }
}
