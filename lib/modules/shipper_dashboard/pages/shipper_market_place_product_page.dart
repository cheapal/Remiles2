import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/ai_miley_page.dart';
import 'package:Remiles/models/product_listing.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // overall white background
      body: SafeArea(
        child: SingleChildScrollView(
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
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Hello, is this still available?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
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
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    children: [
                      TextSpan(text: 'Description: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(
                        text: widget.listing.description,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: ' See more',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
                        child: Icon(Icons.person, size: 32, color: green),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // rating stars + text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.shipperName,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),

                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star_border, color: Colors.orange, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "4.2 (39)",
                              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),




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
              return Image.network(
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

  void _sendMessage() {
    // TODO: Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent to seller!'),
        backgroundColor: Colors.green,
      ),
    );
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
