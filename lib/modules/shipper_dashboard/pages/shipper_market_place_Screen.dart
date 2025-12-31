import 'dart:async';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_market_place_product_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_profile_create_listing.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_profile_screen.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/product_listing.dart';
import 'package:remiles/models/shipper_model.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== Brand + layout constants (reuse across screens) =====
const Color brandColor = Color(0xFF064232); // one source of truth for both bars
const Color brandGreen = Color(0xFF195529);
const double kMaxContentWidth = 980.0;


class ShipperMarketplaceScreen extends StatefulWidget {
  const ShipperMarketplaceScreen({super.key});

  @override
  State<ShipperMarketplaceScreen> createState() => _ShipperMarketplaceScreenState();
}

class _ShipperMarketplaceScreenState extends State<ShipperMarketplaceScreen>
    with TickerProviderStateMixin {
  int _selectedFilter = 0; // 0: All, 1: New, 2: Used, 3: Refurbished
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedLocation = 'All Locations';

  // Data management
  List<ProductListing> _listings = [];
  List<ProductListing> _filteredListings = [];
  String? _errorMessage;
  
  // Pagination
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 10;

  // Available locations
  final List<String> _availableLocations = [
    'All Locations',
    'Vancouver, BC',
    'Toronto, ON',
    'Montreal, QC',
    'Calgary, AB',
    'Edmonton, AB',
    'Ottawa, ON',
    'Winnipeg, MB',
    'Quebec City, QC',
    'Hamilton, ON',
    'Kitchener, ON',
  ];

  late final AnimationController _shimmerCtrl;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadListings();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          onRefresh: _refreshListings,
        child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ===== Top bar (brand color, leather only on narrow) =====
              TopNavigationBar(context),

              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              //   decoration: BoxDecoration(
              //     color: brandColor,
              //     image: isWide
              //         ? null
              //         : const DecorationImage(
              //       image: AssetImage('assets/top_leather.png'),
              //       fit: BoxFit.cover,
              //     ),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.20),
              //         blurRadius: 5,
              //         spreadRadius: 2,
              //         offset: const Offset(0, 3),
              //       ),
              //     ],
              //     borderRadius: const BorderRadius.only(
              //       bottomLeft: Radius.circular(20),
              //       bottomRight: Radius.circular(20),
              //     ),
              //   ),
              //   child: SafeArea(
              //     bottom: false,
              //     child: _buildTopBar(isWide),
              //   ),
              // ),

              // ===== Content =====
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 100 : 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      // Title row with inline "+ Create listing" on the right
                      Row(
                        children: [
                          const Text(
                            'Marketplace',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                          const Spacer(),
                          _pill(
                            text: '+ Create listing',
                            bg: brandColor,
                            fg: const Color(0xFFFFFBDF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            onTap: () {
                              // show dialog Navigate to create listing screen
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return  ShipperCreateListing();
                                },
                              );

                            },
                          ),

                          const SizedBox(width: 12),

                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShipperProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: brandColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(25, 85, 41, 0.36),
                                    blurRadius: 2.8,
                                    spreadRadius: 0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Full-width search bar
                      _searchBar(),

                      const SizedBox(height: 16),

                      // Filters row (All/New/Used - Like New/Used - Good/Used - Fair/Refurbished)
                      Padding(
                        padding: EdgeInsetsGeometry.all(1),
                        child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            _filterChip('All', 0,
                                activeBg: brandGreen, activeFg: Colors.white),
                            const SizedBox(width: 10),
                              _filterChip('New', 1,
                                  activeBg: brandGreen, activeFg: Colors.white),
                            const SizedBox(width: 10),
                              _filterChip('Used - Like New', 2, width: 120,
                                  activeBg: brandGreen, activeFg: Colors.white),
                            const SizedBox(width: 10),
                              _filterChip('Used - Good', 3, width: 100,
                                  activeBg: brandGreen, activeFg: Colors.white),
                            const SizedBox(width: 10),
                              _filterChip('Used - Fair', 4, width: 100,
                                  activeBg: brandGreen, activeFg: Colors.white),
                            const SizedBox(width: 10),
                              _filterChip('Refurbished', 5, width: 120,
                                  activeBg: brandGreen, activeFg: Colors.white),
                          ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Location + Today's Picks
                      Row(
                        children: [
                          const Text(
                            "Today's Picks",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showLocationPicker,
                            child: Row(
                              children: [
                                const Icon(Icons.place, size: 20, color: brandColor),
                                const SizedBox(width: 6),
                          Text(
                                  _selectedLocation,
                                  style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: brandGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, size: 20, color: brandGreen),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Grid of ads (skeleton while loading)
                      _adsGrid(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }



  // Search bar (matches app styling)
  Widget _searchBar() {
    return Container(
      height: 36,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(25, 85, 41, 0.36),
            blurRadius: 2.8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: Colors.black.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search trucks, trailers, parts ....',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF959595),
                ),
                isDense: true,
                border: InputBorder.none,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.filter_list, size: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Pills (used for create listing etc.)
  Widget _pill({
    required String text,
    required Color bg,
    required Color fg,
    EdgeInsetsGeometry padding =
    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18.2),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(25, 85, 41, 0.36),
              blurRadius: 2.8,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: padding,
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  // Filter chip row item
  Widget _filterChip(
      String text,
      int index, {
        Color activeBg = Colors.white,
        Color activeFg = Colors.black,
        double width = 70,
      }) {
    final bool isActive = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
          _currentPage = 0;
          _hasMoreData = true;
          _listings.clear();
          _filteredListings.clear();
        });
        _loadListings();
      },
      child: Container(
        width: width,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(18.2),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(25, 85, 41, 0.36),
              blurRadius: 2.8,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? activeFg : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  // Ads grid using skeletons while loading
  Widget _adsGrid() {
    final double screenW = MediaQuery.of(context).size.width;

    // Responsive column count
    final int crossAxisCount = screenW >= 1280
        ? 5
        : screenW >= 1000
        ? 4
        : screenW >= 720
        ? 3
        : 2;

    if (_isLoading) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
          childAspectRatio: 200 / 280, // Increased height for better image visibility
      ),
      itemBuilder: (context, i) {
          return Shimmer(
            controller: _shimmerCtrl,
            baseColor: const Color(0xFFE8E8E8),
            highlightColor: const Color(0xFFF5F5F5),
            child: _SkeletonAdCard(),
          );
        },
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredListings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredListings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 200 / 300, // Increased height for better image visibility
          ),
          itemBuilder: (context, i) {
            final listing = _filteredListings[i];
            return _AdCard(
              listing: listing,
              onRefresh: _refreshListings,
            );
          },
        ),
        if (_isLoadingMore)
          Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
              ),
            ),
          ),
        if (!_hasMoreData && _filteredListings.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'No more listings to load',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Data loading methods
  Future<void> _loadListings({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = 0;
          _hasMoreData = true;
          _listings.clear();
          _filteredListings.clear();
        });
      } else {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Get condition filter
      String? condition;
      if (_selectedFilter > 0) {
        final conditionMap = {
          1: 'New',
          2: 'Used - Like New',
          3: 'Used - Good',
          4: 'Used - Fair',
          5: 'Refurbished',
        };
        condition = conditionMap[_selectedFilter];
      }

      // Get location filter
      String? location;
      if (_selectedLocation != 'All Locations') {
        location = _selectedLocation;
      }

      final listings = await FirebaseService.getProductListings(
        condition: condition,
        location: location,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _listings = listings;
            _filteredListings = listings;
          } else {
            _listings.addAll(listings);
            _filteredListings.addAll(listings);
          }
          _isLoading = false;
          _hasMoreData = listings.length == _pageSize;
          _currentPage++;
        });
        _applyFilters();
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

  Future<void> _refreshListings() async {
    await _loadListings(isRefresh: true);
  }

  // Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreListings();
    }
  }

  // Load more listings for pagination
  Future<void> _loadMoreListings() async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Get condition filter
      String? condition;
      if (_selectedFilter > 0) {
        final conditionMap = {
          1: 'New',
          2: 'Used - Like New',
          3: 'Used - Good',
          4: 'Used - Fair',
          5: 'Refurbished',
        };
        condition = conditionMap[_selectedFilter];
      }

      // Get location filter
      String? location;
      if (_selectedLocation != 'All Locations') {
        location = _selectedLocation;
      }

      final listings = await FirebaseService.getProductListings(
        condition: condition,
        location: location,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          _listings.addAll(listings);
          _filteredListings.addAll(listings);
          _isLoadingMore = false;
          _hasMoreData = listings.length == _pageSize;
          _currentPage++;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more listings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Search functionality
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 0;
      _hasMoreData = true;
      _listings.clear();
      _filteredListings.clear();
    });
    _loadListings();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _currentPage = 0;
      _hasMoreData = true;
      _listings.clear();
      _filteredListings.clear();
    });
    _loadListings();
  }

  // Apply filters to loaded data (for client-side filtering of already loaded items)
  void _applyFilters() {
    List<ProductListing> filtered = List.from(_listings);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((listing) {
        return listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               listing.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               listing.location.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredListings = filtered;
    });
  }

  // Error state widget
  Widget _buildErrorState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
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
              onPressed: _loadListings,
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

  // Empty state widget
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No listings found for "$_searchQuery"'
                  : 'No listings available',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearSearch,
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Location picker
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableLocations.length,
                  itemBuilder: (context, index) {
                    final location = _availableLocations[index];
                    final isSelected = location == _selectedLocation;
                    final isAllLocations = location == 'All Locations';
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? brandGreen : Colors.grey,
                      ),
                      title: Text(
                        location,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? brandGreen : Colors.black,
                        ),
                      ),
                      trailing: isAllLocations ? const Icon(Icons.public, color: brandGreen) : null,
                      onTap: () {
                        setState(() {
                          _selectedLocation = location;
                          _currentPage = 0;
                          _hasMoreData = true;
                          _listings.clear();
                          _filteredListings.clear();
                        });
                        _loadListings();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A beautiful ad card following the market design sizing & shadows
class _AdCard extends StatefulWidget {
  const _AdCard({
    required this.listing,
    this.onRefresh,
  });

  final ProductListing listing;
  final VoidCallback? onRefresh;

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  ShipperModel? _shipperData;
  bool _isLoadingShipper = false;
  int? _completedShipments;

  @override
  void initState() {
    super.initState();
    _loadShipperData();
  }

  Future<void> _loadShipperData() async {
    if (widget.listing.shipperUid.isEmpty) return;
    
    setState(() {
      _isLoadingShipper = true;
    });

    try {
      final shipper = await FirebaseService.getShipper(widget.listing.shipperUid);
      if (shipper != null) {
        // Also load completed shipments count
        final stats = await FirebaseService.getShipperLoadStats(shipper.uid);
        
        if (mounted) {
          setState(() {
            _shipperData = shipper;
            _completedShipments = stats['completed'] ?? 0;
            _isLoadingShipper = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingShipper = false;
          });
        }
      }
    } catch (e) {
      print('Error loading shipper data for listing: $e');
      if (mounted) {
        setState(() {
          _isLoadingShipper = false;
        });
      }
    }
  }

  bool get _isOwnListing {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    return currentUser != null && widget.listing.shipperUid == currentUser.uid;
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return GestureDetector(
      onTap: () {
        // Handle ad tap (e.g., navigate to details)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPagePrecise(listing: listing)
          ),
        ).then((result) {
          // Refresh listings if listing was deleted
          if (result == true && mounted && widget.onRefresh != null) {
            widget.onRefresh!();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2), // prevent shadow clipping
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Decreased from 23 to 12 for less roundness
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6CA78A).withOpacity(0.20),
              blurRadius: 13.4,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Decreased from 23 to 12
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product image
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFD9D9D9),
                      child: listing.imageUrls.isNotEmpty
                          ? Image.network(
                              listing.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image, size: 34, color: Colors.white);
                              },
                            )
                          : const Icon(Icons.image, size: 34, color: Colors.white),
                    ),
                    // "Your Listing" pill badge
                    if (_isOwnListing)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: brandGreen,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Your Listing',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
                    // tag + price row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: listing.condition == 'New'
                                    ? brandGreen
                                    : const Color(0xFF386544),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                listing.condition,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '\$${listing.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFFCEB838),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Color(0xFF386544)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: brandGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Rating, Verified, Shipments row (only show if not own listing)
                    if (!_isOwnListing && (_isLoadingShipper || _shipperData != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            // Rating
                            Icon(Icons.star, size: 14, color: const Color(0xFFFDD610)),
                            const SizedBox(width: 2),
                            Text(
                              _shipperData?.rating != null
                                  ? '${_shipperData!.rating!.toStringAsFixed(1)}'
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _shipperData?.rating != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Verified Badge (based on account or phone verification)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: ((_shipperData?.isVerified == true) || (_shipperData?.isPhoneVerified == true))
                                    ? const Color(0xFF81AB3A)
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 7,
                                color: Colors.white,
                              ),
                            ),
                            /// Hiding this for now - need solution for that
                            // const SizedBox(width: 4),
                            // Text(
                            //   ((_shipperData?.isVerified == true) || (_shipperData?.isPhoneVerified == true)) ? 'Verified' : '',
                            //   style: TextStyle(
                            //     fontSize: 10,
                            //     fontWeight: FontWeight.w500,
                            //     color: ((_shipperData?.isVerified == true) || (_shipperData?.isPhoneVerified == true)) ? Colors.black87 : Colors.grey,
                            //   ),
                            // ),
                            const Spacer(),
                            // Shipments
                            Icon(Icons.local_shipping, size: 12, color: Colors.black87),
                            const SizedBox(width: 2),
                            _isLoadingShipper
                                ? const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  )
                                : Text(
                                    '${_completedShipments ?? _shipperData?.totalShipments ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            const SizedBox(width: 6),
                            // Comment/Review icon
                            GestureDetector(
                              onTap: () {
                                _navigateToChat(context);
                              },
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Flag/Report icon
                            GestureDetector(
                              onTap: () {
                                _showReportDialog(context);
                              },
                              child: Icon(
                                Icons.flag_outlined,
                                size: 14,
                                color: Colors.black54,
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
        ),
      ),
    );
  }

  Future<void> _navigateToChat(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to chat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

   

    try {
      // Create or get conversation for this listing
      final conversationId = await FirebaseService.createOrGetConversation(
        senderId: user.uid,
        receiverId: widget.listing.shipperUid,
        listingId: widget.listing.id,
        listingTitle: widget.listing.title,
        listingImageUrl: widget.listing.imageUrls.isNotEmpty 
            ? widget.listing.imageUrls.first 
            : null,
      );

    

      // Navigate to chat screen
      if (context.mounted) {
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
              listingId: widget.listing.id,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Report Listing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF186230),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing: ${widget.listing.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seller: ${widget.listing.shipperName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reason for reporting:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF186230),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        hintText: 'Please describe the issue...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF43975A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                      ),
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a reason for reporting'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSubmitting = true;
                    });

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
                      setDialogState(() {
                        isSubmitting = false;
                      });
                      return;
                    }

                    final success = await FirebaseService.submitReport(
                      reporterId: reporter.uid,
                      reportedUserId: widget.listing.shipperUid,
                      reportedUserName: widget.listing.shipperName,
                      reason: reasonController.text.trim(),
                      listingId: widget.listing.id,
                    );

                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Report submitted successfully. Thank you for your feedback.'
                                : 'Failed to submit report. Please try again.',
                          ),
                          backgroundColor: success ? const Color(0xFF4B744F) : Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF186230),
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Skeleton version of ad card, with sub-elements for a richer effect.
class _SkeletonAdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Decreased from 23 to 12 for less roundness
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A).withOpacity(0.20),
            blurRadius: 13.4,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // Decreased from 23 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image area skeleton
            Expanded(child: Container(color: const Color(0xFFD9D9D9))),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _line(width: 40, height: 16, radius: 8),
                      const Spacer(),
                      _line(width: 58, height: 14, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _line(width: double.infinity, height: 14, radius: 6),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _line(width: 90, height: 12, radius: 6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line({required double width, required double height, double radius = 4}) {
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

/// Lightweight shimmer without external packages.
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
        // Move gradient from left to right
        final double slide = (controller.value * 2) - 1; // -1 .. 1
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 - slide, 0),
              end: Alignment(1 - slide, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
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
