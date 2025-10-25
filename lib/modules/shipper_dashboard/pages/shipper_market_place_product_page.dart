import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/ai_miley_page.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:Remiles/models/product_listing.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:photo_view/photo_view.dart';

import 'package:flutter/material.dart';

class ProductPagePrecise extends StatefulWidget {
  final ProductListing listing;
  
  const ProductPagePrecise({Key? key, required this.listing}) : super(key: key);

  @override
  State<ProductPagePrecise> createState() => _ProductPagePreciseState();
}

class _ProductPagePreciseState extends State<ProductPagePrecise> {
  final Color green = const Color(0xFF497A57);
  bool _isSaved = false;
  bool _isAlertSet = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final TextEditingController _messageController = TextEditingController();
  
  // Shipper details
  Map<String, dynamic>? _shipperDetails;
  bool _isLoadingShipper = true;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _loadShipperDetails();
    _messageController.text = 'Hello, is this still available?';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _checkIfSaved() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        final isSaved = await FirebaseService.isListingSaved(user.uid, widget.listing.id);
        if (mounted) {
          setState(() {
            _isSaved = isSaved;
          });
        }
      }
    } catch (e) {
      // Silently handle error - user can still use the page
      print('Error checking saved status: $e');
    }
  }

  void _loadShipperDetails() async {
    try {
      final shipperDetails = await FirebaseService.getShipperDetails(widget.listing.shipperUid);
      if (mounted) {
        setState(() {
          _shipperDetails = shipperDetails;
          _isLoadingShipper = false;
        });
      }
    } catch (e) {
      print('Error loading shipper details: $e');
      if (mounted) {
        setState(() {
          _isLoadingShipper = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // overall white background
      body: SingleChildScrollView(
        child: Column(
          children: [
            //top nav
            TopNavigationBar(context),
            // ---------- BACK BUTTON ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 0, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            // ---------- IMAGE CAROUSEL ----------
            _buildImageCarousel(),
      
            Column(
              children: [
                const SizedBox(height: 24),
                // ---------- TITLE + PRICE ROW ----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:  [
                      Expanded(
                        child: Text(
                          '${widget.listing.title}\n\$${widget.listing.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: green, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  widget.listing.location,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
      
      
            // ---------- Message card overlaps - use negative translate ----------
            Transform.translate(
              offset: const Offset(0, -10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: green.withOpacity(0.9), width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: green.withOpacity(0.12),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send seller a message',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F4),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                maxLines: 1,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Send',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      
            const SizedBox(height: 12),
      
            // ---------- ALERT + SAVE (centered pills) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _outlinePill(
                    icon: _isAlertSet ? Icons.notifications : Icons.notifications_none, 
                    label: _isAlertSet ? 'Alert Set' : 'Alert', 
                    green: green,
                    onTap: _toggleAlert,
                  ),
                  _outlinePill(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border, 
                    label: _isSaved ? 'Saved' : 'Save', 
                    green: green,
                    onTap: _toggleSave,
                  ),
                ],
              ),
            ),
      
            const SizedBox(height: 22),
      
            // ---------- PRODUCT DESCRIPTION (black text + "See more" blue) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDescriptionText(),
            ),
      
            const SizedBox(height: 28),
      
            // ---------- SELLER ROW ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: green.withOpacity(0.6), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: _shipperDetails?['profileImageUrl'] != null
                          ? NetworkImage(_shipperDetails!['profileImageUrl'])
                          : null,
                      child: _shipperDetails?['profileImageUrl'] == null
                          ? Icon(Icons.person, size: 32, color: green)
                          : null,
                    ),
                  ),
      
                  const SizedBox(width: 14),
      
                  // rating stars + text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          Text(
                        _shipperDetails?['name'] ?? widget.listing.shipperName,
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
      
                      _buildRatingStars(),
                    ],
                  ),
      
                  const Spacer(),
      
                  // big support circle button (matches screenshot)
                  GestureDetector(
                    onTap: () {
                      // handle support tap
                      showDialog(
                        context: context,
                        builder: (context) => AiMileyScreen()
                      );
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: green.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Icon(Icons.headset_mic, color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            ),
      
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.listing.imageUrls.isEmpty) {
      return Container(
        height: 260,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: widget.listing.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openImageViewer(index),
                child: Image.network(
                  widget.listing.imageUrls[index],
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 260,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (widget.listing.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.listing.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<String> _createConversation(dynamic user) async {
    // Create or get conversation
    print('Creating conversation between ${user.uid} and ${widget.listing.shipperUid}');
    final conversationId = await FirebaseService.createOrGetConversation(
      senderId: user.uid,
      receiverId: widget.listing.shipperUid,
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      listingImageUrl: widget.listing.imageUrls.isNotEmpty 
          ? widget.listing.imageUrls.first 
          : null,
    );
    print('Conversation ID: $conversationId');
    
    return conversationId;
  }

  void _sendMessage() async {
    // Check if user is logged in first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send messages'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if message is empty
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // // Show loading indicator
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) => const Center(
    //     child: CircularProgressIndicator(),
    //   ),
    // );

    try {
      // Add timeout to the conversation creation
      final conversationId = await Future.any([
        _createConversation(user),
        Future.delayed(const Duration(seconds: 10), () {
          throw Exception('Conversation creation timed out');
        }),
      ]);

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate to chat screen with pre-filled message
      print('Navigating to chat screen with conversation ID: $conversationId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: widget.listing.shipperUid,
            otherUserName: widget.listing.shipperName,
            listingTitle: widget.listing.title,
            listingImageUrl: widget.listing.imageUrls.isNotEmpty 
                ? widget.listing.imageUrls.first 
                : null,
            listingId: widget.listing.id, // Pass the listing ID for view details
            preFilledMessage: messageText, // Pass the message to pre-fill
          ),
        ),
      );
    } catch (e) {
      print('Error in _sendMessage: $e');
      
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleAlert() {
    setState(() {
      _isAlertSet = !_isAlertSet;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isAlertSet ? 'Alert set for this listing!' : 'Alert removed!'),
        backgroundColor: _isAlertSet ? Colors.green : Colors.orange,
      ),
    );
  }

  void _toggleSave() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to save listings'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_isSaved) {
        // Remove from saved
        await FirebaseService.removeSavedListing(user.uid, widget.listing.id);
        setState(() {
          _isSaved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing removed from saved!'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Add to saved
        await FirebaseService.saveListing(user.uid, widget.listing);
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDescriptionText() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Create a TextPainter to measure the text
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.listing.description,
            style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          maxLines: 3,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        // Check if text overflows (more than 3 lines)
        final isOverflowing = textPainter.didExceedMaxLines;
        
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            children: [
              const TextSpan(
                text: 'Description: ', 
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: widget.listing.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isOverflowing)
                TextSpan(
                  text: ' See more',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingStars() {
    if (_isLoadingShipper) {
      return const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      );
    }

    // Get rating from shipper details or show 0 if no data
    final rating = _shipperDetails?['rating']?.toDouble() ?? 0.0;
    final reviewCount = _shipperDetails?['reviewCount'] ?? 0;
    
    return Row(
      children: [
        ...List.generate(5, (index) {
          if (rating == 0.0) {
            // Show all black/empty stars when no rating
            return const Icon(Icons.star_border, color: Colors.grey, size: 18);
          } else if (index < rating.floor()) {
            return const Icon(Icons.star, color: Colors.orange, size: 18);
          } else if (index < rating) {
            return const Icon(Icons.star_half, color: Colors.orange, size: 18);
          } else {
            return const Icon(Icons.star_border, color: Colors.grey, size: 18);
          }
        }),
        const SizedBox(width: 4),
        Text(
          rating == 0.0 ? 'No ratings' : '${rating.toStringAsFixed(1)} ($reviewCount)',
          style: TextStyle(
            fontSize: 14, 
            color: rating == 0.0 ? Colors.grey : Colors.black87, 
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }

  void _openImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          imageUrls: widget.listing.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _outlinePill({
    required IconData icon, 
    required String label, 
    required Color green,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: green, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: green.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          ),
        ),
      ),
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return PhotoView(
            imageProvider: NetworkImage(widget.imageUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            initialScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'image_$index',
            ),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, event) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: widget.imageUrls.length > 1
          ? Container(
              height: 60,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
