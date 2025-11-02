import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/load_model.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/load_card_info.dart';
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

class _ManageLoadScreenState extends State<ManageLoadScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadLoads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }


  Future<void> _loadLoads({bool reset = false}) async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
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
      
      // Debug print
      print('Loaded ${_loads.length} loads for filter: $_selectedFilter');
      print('Has more: $_hasMore');
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
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      
      // Show user-friendly error message
      if (mounted) {
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
      setState(() {
        _searchQuery = query;
      });
      
      // Cancel previous debounce timer
      _searchDebounce?.cancel();
      
      // If immediate is true (e.g., when clearing), reload right away
      // Otherwise, use debounce timer
      if (immediate) {
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshLoads,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Navigation Bar
            TopNavigationBar(context),

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

                  /// Search and Filter Section
                  _buildSearchAndFilterSection(),

            const SizedBox(height: 16),

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
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 50,
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter buttons
          _buildFilterButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['All', 'Available Loads', 'My Bookings', 'In-Transit', 'Cancelled Loads', 'Completed Loads'];
    
    return Column(
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

  /// Get loads that have matchPercentage (matched/recommended loads)
  List<LoadModel> _getMatchedLoads() {
    return _loads.where((load) => load.matchPercentage != null).toList();
  }

  /// Get loads that don't have matchPercentage (regular loads)
  List<LoadModel> _getNonMatchedLoads() {
    return _loads.where((load) => load.matchPercentage == null).toList();
  }

  /// Build recommended loads section (only matched loads)
  List<Widget> _buildRecommendedLoads() {
    final matchedLoads = _getMatchedLoads();
    
    if (matchedLoads.isEmpty) {
      return [];
    }
    
    // Sort by match percentage (highest first) and take the first one
    matchedLoads.sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
    
    return [
      RecommendedLoad(load: matchedLoads.first),
    ];
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
