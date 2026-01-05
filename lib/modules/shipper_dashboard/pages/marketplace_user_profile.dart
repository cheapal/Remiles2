import 'dart:async';
import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_market_place_product_page.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/product_listing.dart';
import 'package:remiles/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remiles/providers/auth_provider.dart';

// ===== Brand + layout constants (reuse across screens) =====
const Color brandColor = Color(0xFF064232);
const Color brandGreen = Color(0xFF195529);

class MarketplaceUserProfile extends StatefulWidget {
  const MarketplaceUserProfile({super.key});

  @override
  State<MarketplaceUserProfile> createState() => _MarketplaceUserProfileState();
}

class _MarketplaceUserProfileState extends State<MarketplaceUserProfile>
    with TickerProviderStateMixin {
  int _selectedTab =
      0; // 0: My Listings, 1: Saved Items, 2: Inbox, 3: Reviews, 4: Recently Viewed
  bool _isLoading = true;
  String? _errorMessage;

  // Data management
  List<ProductListing> _myListings = [];
  List<ProductListing> _savedListings = [];
  List<ProductListing> _recentlyViewed = [];
  List<ChatConversation> _conversations = [];

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadUserData();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ===== Top bar =====
              TopNavigationBar(context),

              // ===== Content =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 100 : 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      // Header with back button and profile info
                      _buildHeader(),

                      const SizedBox(height: 20),

                      // Navigation tabs
                      _buildNavigationTabs(),

                      const SizedBox(height: 20),

                      // Content based on selected tab
                      _buildTabContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final shipper = authProvider.shipperUser;
    final userName = user?.displayName ?? shipper?.companyName ?? 'User';
    final profileImageUrl = shipper?.profileImageUrl ?? user?.profileImageUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),

        Expanded(
          child: Text(
            "$userName",
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Colors.black,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),

        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: brandColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: profileImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    profileImageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: brandColor,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: brandColor,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : const Icon(Icons.person, color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildNavigationTabs() {
    return Column(
      children: [
        // Top row
        Row(
          children: [
            _buildTabButton(
              'My Listings',
              0,
              Icons.list_alt,
              isActive: _selectedTab == 0,
            ),
            const SizedBox(width: 12),
            _buildTabButton(
              'Saved',
              1,
              Icons.bookmark_border,
              isActive: _selectedTab == 1,
            ),
            const SizedBox(width: 12),
            _buildTabButton(
              'Inbox',
              2,
              Icons.inbox_outlined,
              isActive: _selectedTab == 2,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row
        Row(
          children: [
            _buildTabButton(
              'Reviews',
              3,
              Icons.star_border,
              isActive: _selectedTab == 3,
            ),
            const SizedBox(width: 12),
            _buildTabButton(
              'Recently Viewed',
              4,
              Icons.history,
              isActive: _selectedTab == 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(
    String text,
    int index,
    IconData icon, {
    bool isActive = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
          _loadTabData();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? brandGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? brandGreen : brandGreen.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: brandGreen.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? Colors.white : brandGreen, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isActive ? Colors.white : brandGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildMyListings();
      case 1:
        return _buildSavedItems();
      case 2:
        return _buildConversations();
      case 3:
        return _buildReviews();
      case 4:
        return _buildRecentlyViewed();
      default:
        return _buildMyListings();
    }
  }

  Widget _buildMyListings() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_myListings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No listings yet',
        subtitle: 'Create your first listing to get started',
        actionText: 'Create Listing',
        onAction: () {
          // Navigate to create listing
          Navigator.pop(context);
        },
      );
    }

    return _buildListingsGrid(_myListings);
  }

  Widget _buildSavedItems() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_savedListings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'No saved items',
        subtitle: 'Items you save will appear here',
      );
    }

    return _buildListingsGrid(_savedListings);
  }

  Widget _buildConversations() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_conversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations',
        subtitle: 'Your conversations will appear here',
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
        final otherUserId = conversation.getOtherParticipant(user?.uid ?? '');

        return _ConversationCard(
          conversation: conversation,
          otherUserId: otherUserId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  conversationId: conversation.id,
                  otherUserId: otherUserId,
                  otherUserName: conversation.participants.contains(otherUserId)
                      ? 'User' // You might want to fetch the actual name
                      : 'Unknown User',
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

  Widget _buildReviews() {
    return _buildEmptyState(
      icon: Icons.star_border,
      title: 'No reviews yet',
      subtitle: 'Reviews from buyers will appear here',
    );
  }

  Widget _buildRecentlyViewed() {
    if (_recentlyViewed.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No recently viewed',
        subtitle: 'Items you view will appear here',
      );
    }

    return _buildListingsGrid(_recentlyViewed);
  }

  Widget _buildListingsGrid(List<ProductListing> listings) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ListingCard(
            listing: listing,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductPagePrecise(listing: listing),
                ),
              );
              // Refresh listings if listing was deleted or updated
              if (result == true && mounted) {
                _loadUserData();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer(
            controller: _shimmerCtrl,
            baseColor: const Color(0xFFE8E8E8),
            highlightColor: const Color(0xFFF5F5F5),
            child: _SkeletonListingCard(),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Load user's listings
      final listings = await FirebaseService.getProductListings(
        shipperUid: user.uid,
      );

      if (mounted) {
        setState(() {
          _myListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load listings: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedListings() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final savedListings = await FirebaseService.getSavedListings(user.uid);
      setState(() {
        _savedListings = savedListings;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final conversations = await FirebaseService.getUserConversations(
        user.uid,
      );
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadTabData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedTab == 0) {
        await _loadUserData();
      } else if (_selectedTab == 1) {
        await _loadSavedListings();
      } else if (_selectedTab == 2) {
        await _loadConversations();
      }
      // Other tabs can be implemented later
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Listing card widget
class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onTap});

  final ProductListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6CA78A).withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left side - Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price - More prominent
                      Text(
                        '\$${listing.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFCEB838),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        listing.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Location and Condition row
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: brandGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: brandGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            listing.condition,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right side - Product image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: listing.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.image, size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton listing card
class _SkeletonListingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A).withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left side - Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(
                      width: double.infinity,
                      height: 16,
                      radius: 6,
                    ),
                    const SizedBox(height: 8),
                    _SkeletonLine(width: 80, height: 18, radius: 6),
                    const SizedBox(height: 8),
                    _SkeletonLine(
                      width: double.infinity,
                      height: 13,
                      radius: 6,
                    ),
                    const SizedBox(height: 4),
                    _SkeletonLine(width: 200, height: 13, radius: 6),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SkeletonLine(width: 16, height: 16, radius: 8),
                        const SizedBox(width: 4),
                        _SkeletonLine(width: 100, height: 13, radius: 6),
                        const Spacer(),
                        _SkeletonLine(width: 60, height: 12, radius: 6),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right side - Image skeleton
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SkeletonLine({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Shimmer effect
class Shimmer extends StatelessWidget {
  const Shimmer({
    super.key,
    required this.child,
    required this.controller,
    this.baseColor = const Color(0xFFEAEAEA),
    this.highlightColor = const Color(0xFFF7F7F7),
  });

  final Widget child;
  final AnimationController controller;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final double slide = (controller.value * 2) - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 - slide, 0),
              end: Alignment(1 - slide, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

/// Conversation card widget
class _ConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final String otherUserId;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.otherUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: brandGreen,
              child: Text(
                conversation.listingTitle?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.listingTitle ?? 'Product Inquiry',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessage != null)
                        Text(
                          _formatTime(conversation.lastMessage!.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage?.content ?? 'No messages yet',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (conversation.unreadCount[otherUserId] == true)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
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
