import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/load_model.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/load_card_info.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:async';

import '../../common/widgets/recommended_load.dart';
import '../../common/widgets/top_navigation_bar.dart';

class ManageLoadScreen extends StatefulWidget {
  const ManageLoadScreen({super.key});

  @override
  State<ManageLoadScreen> createState() => _ManageLoadScreenState();
}

class _ManageLoadScreenState extends State<ManageLoadScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  
  // State management
  List<LoadModel> _loads = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;
  Timer? _searchDebounce;
  late final AnimationController _sortController;
  late final Animation<double> _sortAnimation;
  late final Animation<double> _sortRotation;

  static const double _searchBarHeight = 50;
  static const double _sortHeaderHeight = 48;
  static const double _searchAndSortSpacing = 12;
  static const double _sortExpandedExtraHeight = 116; // 12 spacing + two 40px rows + 8 gap + 16 bottom padding
  static const double _stickyHeaderTopPadding = 8;

  double get _collapsedHeaderHeight =>
      _stickyHeaderTopPadding + _searchBarHeight + _searchAndSortSpacing + _sortHeaderHeight;

  @override
  void initState() {
    super.initState();
    _sortController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sortAnimation = CurvedAnimation(
      parent: _sortController,
      curve: Curves.easeInOut,
    );
    _sortRotation = Tween<double>(begin: 0.0, end: 0.5).animate(_sortAnimation);
    _sortController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadLoads();
  }

  @override
  void dispose() {
    _sortController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }


  Future<void> _loadLoads({bool reset = false}) async {
    if (_isLoading || !_hasMore) return;
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> result;
      
      if (_selectedFilter == 'All') {
        // Get all loads for the carrier (both available and booked)
        result = await FirebaseService.getAllLoadsForCarrier(
          carrierUid: user.uid,
          searchQuery: _searchQuery,
          limit: 10,
          lastDocument: reset ? null : _lastDocument,
        );
      } else if (_selectedFilter == 'Available Loads') {
        result = await FirebaseService.getAvailableLoadsForCarrier(
          carrierUid: user.uid,
          searchQuery: _searchQuery,
          limit: 10,
          lastDocument: reset ? null : _lastDocument,
        );
      } else {
        String status = 'booked';
        if (_selectedFilter == 'In-Transit') status = 'in-transit';
        else if (_selectedFilter == 'Cancelled Loads') status = 'cancelled';
        else if (_selectedFilter == 'Completed Loads') status = 'completed';
        
        result = await FirebaseService.getCarrierBookedLoads(
          carrierUid: user.uid,
          status: status,
          limit: 10,
          lastDocument: reset ? null : _lastDocument,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _loads = List<LoadModel>.from(result['loads']);
            _lastDocument = result['lastDocument'];
          } else {
            _loads.addAll(List<LoadModel>.from(result['loads']));
            _lastDocument = result['lastDocument'];
          }
          _hasMore = result['hasMore'] as bool;
          _isLoading = false;
        });
      }
      
      // Debug print
      print('Loaded ${_loads.length} loads for filter: $_selectedFilter');
      print('Has more: $_hasMore');
      
      // Debug: Check match percentages
      final matchedCount = _loads.where((load) => load.matchPercentage != null && load.matchPercentage! > 0).length;
      print('Loads with matchPercentage > 0: $matchedCount');
      if (matchedCount > 0) {
        final topMatches = _loads.where((load) => load.matchPercentage != null && load.matchPercentage! > 0)
            .toList()
          ..sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
        print('Top 3 matches: ${topMatches.take(3).map((l) => '${l.id}: ${l.matchPercentage?.toStringAsFixed(1)}%').join(', ')}');
      }
    } catch (e) {
      String errorMessage;
      print('Error loading loads: $e'); // Debug print
      print('Selected filter: $_selectedFilter'); // Debug print
      print('Search query: $_searchQuery'); // Debug print
      
      if (e is SocketException || e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please contact support.';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'No loads found for your current filters.';
      } else {
        errorMessage = 'Failed to load loads: ${e.toString()}';
      }
      
      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
        
        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadLoads(reset: true),
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshLoads() async {
    // Clear current data and reset pagination
    if (!mounted) return;
    setState(() {
      _loads = [];
      _lastDocument = null;
      _hasMore = true;
      _error = null;
    });
    
    // Reload data
    await _loadLoads(reset: true);
  }

  void _onFilterChanged(String filter) {
    if (filter != _selectedFilter) {
      if (!mounted) return;
      setState(() {
        _selectedFilter = filter;
        _loads = [];
        _lastDocument = null;
        _hasMore = true;
      });
      _loadLoads(reset: true);
    }
  }

  void _onSearchChanged(String query, {bool immediate = false}) {
    if (query != _searchQuery) {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
      });
      
      // Cancel previous debounce timer
      _searchDebounce?.cancel();
      
      // If immediate is true (e.g., when clearing), reload right away
      // Otherwise, use debounce timer
      if (immediate) {
        if (!mounted) return;
        setState(() {
          _loads = [];
          _lastDocument = null;
          _hasMore = true;
          _error = null;
        });
        _loadLoads(reset: true);
      } else {
        // Set new debounce timer
        _searchDebounce = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _loads = [];
              _lastDocument = null;
              _hasMore = true;
              _error = null;
            });
            _loadLoads(reset: true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = _collapsedHeaderHeight + (_sortExpandedExtraHeight * _sortAnimation.value);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// Top Navigation Bar - Fixed at top
          TopNavigationBar(context),
          
          /// RefreshIndicator starts from here (above Manage Loads text)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshLoads,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Top Card without Shadow
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Manage Loads",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Track and manage your loads efficiently",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Sticky Search and Filter Section
                  SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: _StickySearchBarDelegate(
                      child: _buildSearchAndFilterSection(),
                      minHeight: headerHeight,
                      maxHeight: headerHeight,
                      topPadding: _stickyHeaderTopPadding,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Recommended Load (only show matched loads with matchPercentage for Available Loads and All)
                        if ((_selectedFilter == 'Available Loads' || _selectedFilter == 'All')) ...[
                          ..._buildRecommendedLoads(),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),

                  /// Load Cards
                  _buildLoadCardsSliver(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Container(
            height: _searchBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                const SizedBox(width: 16),
                Icon(Icons.search, size: 20, color: Colors.black.withOpacity(0.6)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search loads...',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      // Always reload when clearing - reset state and reload immediately
                      _searchDebounce?.cancel();
                      if (!mounted) return;
                      setState(() {
                        _searchQuery = '';
                        _loads = [];
                        _lastDocument = null;
                        _hasMore = true;
                        _error = null;
                      });
                      _loadLoads(reset: true);
                    },
                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  ),
                IconButton(
                  onPressed: () {
                    // Filter button action - could scroll to filters or show filter dialog
                    // For now, we'll just add a visual indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Filter: $_selectedFilter'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(Icons.filter_list, color: Colors.black.withOpacity(0.6)),
                  tooltip: 'Filter',
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          const SizedBox(height: _searchAndSortSpacing),

          _buildSortSection(),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(25, 85, 41, 0.24),
            blurRadius: 3,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              FocusScope.of(context).unfocus();
              if (_sortController.isAnimating) return;
              if (_sortController.status == AnimationStatus.completed) {
                _sortController.reverse();
              } else {
                _sortController.forward();
              }
            },
            child: Container(
              height: _sortHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.85),
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: _sortRotation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _sortAnimation,
              axisAlignment: -1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    _buildFilterButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['All', 'Available', 'My Bookings', 'In-Transit', 'Cancelled', 'Completed'];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // First row
        Row(
          children: [
            _buildFilterButton(filters[0], 0),
            const SizedBox(width: 8),
            _buildFilterButton(filters[1], 1),
            const SizedBox(width: 8),
            _buildFilterButton(filters[2], 2),
          ],
        ),
        const SizedBox(height: 8),
        // Second row
        Row(
          children: [
            _buildFilterButton(filters[3], 3),
            const SizedBox(width: 8),
            _buildFilterButton(filters[4], 4),
            const SizedBox(width: 8),
            _buildFilterButton(filters[5], 5),
          ],
        ),
      ],
    );
  }

  /// Get loads that have matchPercentage > 0 (matched/recommended loads)
  /// These are loads that have a meaningful match score
  List<LoadModel> _getMatchedLoads() {
    return _loads.where((load) => 
      load.matchPercentage != null && load.matchPercentage! > 0
    ).toList();
  }

  /// Get all loads for regular cards (excluding the top recommended one)
  /// This includes all loads with any match percentage
  List<LoadModel> _getNonMatchedLoads() {
    final matchedLoads = _getMatchedLoads();
    
    // If there are matched loads, exclude the top one (shown in recommended section)
    if (matchedLoads.isNotEmpty) {
      matchedLoads.sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
      final topMatchId = matchedLoads.first.id;
      
      // Return all loads except the top matched one
      return _loads.where((load) => load.id != topMatchId).toList();
    }
    
    // If no matched loads, return all loads
    return _loads;
  }

  /// Build recommended loads section (only top matched load with matchPercentage > 20%)
  /// Shows only the best match to highlight it
  List<Widget> _buildRecommendedLoads() {
    final matchedLoads = _getMatchedLoads();
    
    if (matchedLoads.isEmpty) {
      return [];
    }
    
    // Sort by match percentage (highest first) and take the first one
    matchedLoads.sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
    
    // Only show in recommended if match is above 20% threshold
    final topMatch = matchedLoads.first;
    if (topMatch.matchPercentage != null && topMatch.matchPercentage! >= 20.0) {
      return [
        RecommendedLoad(load: topMatch),
      ];
    }
    
    return [];
  }

  Widget _buildFilterButton(String text, int index) {
    final isActive = _selectedFilter == text;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onFilterChanged(text),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(25, 85, 41, 0.36),
                blurRadius: 2.0412,
                spreadRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadCardsSliver() {
    if (_error != null) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Error loading loads',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 14, color: Colors.red.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshLoads,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Filter out matched loads from regular load cards
    final nonMatchedLoads = _getNonMatchedLoads();

    if (_loads.isEmpty && _isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildLoadingCard(),
          childCount: 3, // Show 3 loading cards
        ),
      );
    }

    if (nonMatchedLoads.isEmpty && !_isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No loads found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty 
                    ? 'Try adjusting your search terms'
                    : 'No loads available for this filter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < nonMatchedLoads.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LoadCardInfo(load: nonMatchedLoads[index], onLoadBooked: _refreshLoads),
            );
          } else if (_hasMore && !_isLoading) {
            // Load more when reaching the end
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadLoads();
            });
            return const SizedBox.shrink();
          } else if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading more loads...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
        childCount: nonMatchedLoads.length + (_hasMore ? 1 : 0),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white,
            spreadRadius: -2,
            blurRadius: 5,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 50,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Route Info
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dates
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          
          // Bottom Row
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Delegate for sticky search bar header
class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;
  final double topPadding;

  _StickySearchBarDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
    required this.topPadding,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_StickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        topPadding != oldDelegate.topPadding;
  }
}
