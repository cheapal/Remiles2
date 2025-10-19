import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/filter_manage_loads.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_dashboard_post_load.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ===== Brand + Layout constants (reuse across screens if you like) =====
const Color brandColor = Color(0xFF064232); // one source of truth for both bars
const double kMaxContentWidth = 980.0;

class ShipperManageLoadsScreen extends StatefulWidget {
  const ShipperManageLoadsScreen({super.key});

  @override
  State<ShipperManageLoadsScreen> createState() => _ShipperManageLoadsScreenState();
}

class _ShipperManageLoadsScreenState extends State<ShipperManageLoadsScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController1;
  int _selectedTab = 0;
  bool _isSearchActive = false;
  final _searchCtrl = TextEditingController();
  
  // Load management state
  List<Map<String, dynamic>> _loads = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  Map<String, int> _loadStats = {};
  
  // Filter state
  Map<String, String> _currentFilters = {
    'status': 'all',
    'loadType': 'all',
    'equipmentType': 'all',
    'originCity': 'all',
    'destinationCity': 'all',
    'sortBy': 'createdAt',
    'sortOrder': 'desc',
  };
  
  
  // Search debounce
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _searchCtrl.addListener(() {
      final has = _searchCtrl.text.isNotEmpty;
      if (has != _isSearchActive) {
        setState(() => _isSearchActive = has);
      }
      
      // Debounce search
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _loadLoads(reset: true);
      });
    });
    
    _loadLoads();
    _loadLoadStats();
  }

  @override
  void dispose() {
    _progressController1.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ======== Load Management Methods ========
  
  Future<void> _loadLoads({bool reset = false}) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        final result = await FirebaseService.getShipperLoads(
          shipperUid: shipper.uid,
          searchQuery: _searchCtrl.text.trim(),
          status: _currentFilters['status']!,
          loadType: _currentFilters['loadType']!,
          equipmentType: _currentFilters['equipmentType']!,
          originCity: _currentFilters['originCity']!,
          destinationCity: _currentFilters['destinationCity']!,
          sortBy: _currentFilters['sortBy']!,
          sortOrder: _currentFilters['sortOrder']!,
          limit: 10,
          lastDocument: reset ? null : _lastDocument,
        );
        
        setState(() {
          if (reset) {
            _loads = result['loads'] as List<Map<String, dynamic>>;
            _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          } else {
            _loads.addAll(result['loads'] as List<Map<String, dynamic>>);
            _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          }
          _hasMore = result['hasMore'] as bool;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load loads: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadLoadStats() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        final stats = await FirebaseService.getShipperLoadStats(shipper.uid);
        setState(() => _loadStats = stats);
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }
  
  void _onApplyFilters(Map<String, String> filters) {
    setState(() {
      _currentFilters = filters;
    });
    _loadLoads(reset: true);
  }
  
  
  void _onStatusTabChanged(int index) {
    setState(() {
      _selectedTab = index;
      switch (index) {
        case 0:
          _currentFilters['status'] = 'all';
          break;
        case 1:
          _currentFilters['status'] = 'active';
          break;
        case 2:
          _currentFilters['status'] = 'inTransit';
          break;
        case 3:
          _currentFilters['status'] = 'booked';
          break;
        case 4:
          _currentFilters['status'] = 'cancelled';
          break;
        case 5:
          _currentFilters['status'] = 'completed';
          break;
        default:
          _currentFilters['status'] = 'all';
          break;
      }
    });
    _loadLoads(reset: true);
  }
  
  Future<void> _updateLoadStatus(String loadId, String newStatus) async {
    if (loadId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid load ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        await FirebaseService.updateLoadStatus(shipper.uid, loadId, newStatus);
        _loadLoads(reset: true);
        _loadLoadStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update load status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBookedStatus(String loadId, bool isBooked) async {
    if (loadId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid load ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        if (isBooked) {
          await FirebaseService.markLoadAsBooked(shipper.uid, loadId);
        } else {
          await FirebaseService.unmarkLoadAsBooked(shipper.uid, loadId);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBooked ? 'Load marked as booked' : 'Load unmarked as booked'),
              backgroundColor: const Color(0xFF195529),
            ),
          );
        }
        
        // Reload loads and stats
        await Future.wait([
          _loadLoads(reset: true),
          _loadLoadStats(),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booked status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteLoad(String loadId) async {
    if (loadId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid load ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        await FirebaseService.deleteLoad(shipper.uid, loadId);
        _loadLoads(reset: true);
        _loadLoadStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete load: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    // Reset pagination and reload data
    setState(() {
      _loads.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    
    await Future.wait([
      _loadLoads(reset: true),
      _loadLoadStats(),
    ]);
  }

  void _repostLoad(Map<String, dynamic> load) async {
    // Open post load screen with pre-filled data
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShipperDashboardPostLoad(
          editLoadData: load, // Pass the load data for editing
        ),
      ),
    );
    
    // If load was updated, refresh the loads list
    if (result != null && result['loadUpdated'] == true) {
      _loadLoads(reset: true);
      _loadLoadStats();
    }
  }

  void _showDeleteConfirmation(String loadId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Load'),
          content: const Text('Are you sure you want to delete this load? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLoad(loadId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ================= Top section =================
                TopNavigationBar(context),

                // ================= Main Content =================
                Padding(
                  // a bit more inner breathing room on desktop
                  padding:
                  EdgeInsets.symmetric(horizontal: isWide ? 100.0 : 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Manage Loads',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 32,
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh, color: Color(0xFF386544)),
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildSearchBar(),
                        const SizedBox(height: 25),
                        GestureDetector(
                          onTap: () async {
                            // Navigate to post load screen
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ShipperDashboardPostLoad(),
                              ),
                            );
                            
                            // If load was created, refresh the loads list
                            if (result != null && result['loadUpdated'] == true) {
                              _loadLoads(reset: true);
                              _loadLoadStats();
                            }
                          },
                          child: Row(
                            children: [
                              _buildMainButton(
                                '+ Post Loads',
                                const Color(0xFFFFCF5F),
                                Colors.black,
                                () async {
                                  // Navigate to post load screen
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ShipperDashboardPostLoad(),
                                    ),
                                  );
                                  
                                  // If load was created, refresh the loads list
                                  if (result != null && result['loadUpdated'] == true) {
                                    _loadLoads(reset: true);
                                    _loadLoadStats();
                                  }
                                }
                              ),
                              const SizedBox(width: 15),
                            _buildMainButton(
                              'Booked Loads',
                              const Color(0xFF195529),
                              Colors.white,
                              () {
                                // Navigate to booked loads by selecting the booked status pill
                                setState(() {
                                  _selectedTab = 3; // Booked is at index 3
                                  _currentFilters['status'] = 'booked';
                                });
                                _loadLoads(reset: true);
                              }
                            ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildStatusTabs(),
                        const SizedBox(height: 25),
                        _buildLoadsList(),
                        const SizedBox(height: 100), // space above bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      );
  }

  // ================= Widgets =================

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(183, 123, 40, 0.44),
            blurRadius: 2.8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(Icons.search, size: 18, color: Colors.black.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search Loads ....',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_isSearchActive)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                FocusScope.of(context).unfocus();
              },
              child: const Icon(Icons.close, size: 18, color: Colors.black),
            )
          else
            GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => FilterManageLoadScreen(
                      currentFilters: _currentFilters,
                      onApplyFilters: _onApplyFilters,
                    ),
                  );
                },
                child: SvgPicture.asset('assets/filter_2.svg')),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text, Color bgColor, Color textColor, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap
        ,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(183, 123, 40, 0.44),
                blurRadius: 2.8,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    final statusTabs = [
      {'label': 'All Loads', 'status': 'all', 'count': _loadStats['total'] ?? 0},
      {'label': 'Active Loads', 'status': 'active', 'count': _loadStats['active'] ?? 0},
      {'label': 'In-Transit', 'status': 'inTransit', 'count': _loadStats['inTransit'] ?? 0},
      {'label': 'Booked', 'status': 'booked', 'count': _loadStats['booked'] ?? 0},
      {'label': 'Cancelled', 'status': 'cancelled', 'count': _loadStats['cancelled'] ?? 0},
      {'label': 'Completed', 'status': 'completed', 'count': _loadStats['completed'] ?? 0},
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusTabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;
          
          return Padding(
            padding: EdgeInsets.only(right: index < statusTabs.length - 1 ? 10 : 0),
            child: _buildStatusButton(
              '${tab['label']} (${tab['count']})',
              isSelected ? const Color(0xFF386544) : Colors.white,
              isSelected ? Colors.white : Colors.black,
              () => _onStatusTabChanged(index),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusButton(String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF386544)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadsList() {
    if (_isLoading && _loads.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loads.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 13.4,
              spreadRadius: 0,
              offset: Offset(0, 13.4),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No loads found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new load',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ..._loads.map((load) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildLoadCard(load),
        )),
        
        // Load more button
        if (_hasMore && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () => _loadLoads(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF386544),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Load More'),
            ),
          ),
          
        // Loading indicator for pagination
        if (_isLoading && _loads.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildLoadCard(Map<String, dynamic> load) {
    final status = load['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 13.4,
            spreadRadius: 0,
            offset: Offset(0, 13.4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF386544), size: 18),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'From: ${load['originAddress'] ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF386544), size: 18),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'To: ${load['destinationAddress'] ?? 'N/A'}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Show repost button for cancelled loads
            if (status == 'cancelled') ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                  onPressed: () => _repostLoad(load),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Repost Load'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF195529),
                    backgroundColor: const Color(0xFF195529).withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                ],
              ),
            ],
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF386544), size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Pickup: ${_formatDate(load['pickupDateTime'], includeTime: true)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF386544), size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Delivery: ${_formatDeliveryWindow(load)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '#${load['id']?.length != null && load['id']!.length >= 8 ? load['id']!.substring(0, 8) : load['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Equipment: ${load['equipmentNeeded'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF195529),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom stats row
            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildCardTextWithIcon(
                  Icons.monitor_weight_outlined, 
                  '${load['weight'] ?? 'N/A'} lb'
                ),
                _buildCardTextWithIcon(
                  Icons.monitor_weight_outlined, 
                  '\$${load['quoteBudget'] ?? 'N/A'}'
                ),
                _buildCardTextWithIcon(
                  Icons.route_outlined, 
                  '${load['dimensions'] ?? 'N/A'}'
                ),
                _buildCardTextWithIcon(
                  Icons.description_outlined, 
                  '${load['additionalDocument'] != null ? '1 Doc' : '0 Docs'}'
                ),
              ],
            ),
            
            // Action buttons - Horizontal ListView for single line
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Book/Unbook button
                    if (load['id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => _toggleBookedStatus(load['id'], load['status'] != 'booked'),
                          style: TextButton.styleFrom(
                            foregroundColor: load['status'] == 'booked' ? Colors.orange : const Color(0xFF195529),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(load['status'] == 'booked' ? 'Unbook' : 'Mark as Booked'),
                        ),
                      ),
                    // Mark In-Transit button
                    if (load['id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => _updateLoadStatus(load['id'], 'inTransit'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Mark In-Transit'),
                        ),
                      ),
                    // Mark Completed button
                    if (load['id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => _updateLoadStatus(load['id'], 'completed'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Mark Completed'),
                        ),
                      ),
                    // Cancel button
                    if (load['id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => _updateLoadStatus(load['id'], 'cancelled'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    // Delete button
                    if (load['id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextButton(
                          onPressed: () => _showDeleteConfirmation(load['id']),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Delete'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTextWithIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF195529)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14.3,
              fontWeight: FontWeight.w600,
              color: Color(0xFF195529),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF386544);
      case 'inTransit':
        return Colors.blue;
      case 'booked':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFF386544);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'inTransit':
        return 'In-Transit';
      case 'booked':
        return 'Booked';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Active';
    }
  }

  String _formatDate(dynamic dateValue, {bool includeTime = false}) {
    if (dateValue == null) return 'N/A';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'N/A';
      }
      
      if (includeTime) {
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDeliveryWindow(Map<String, dynamic> load) {
    // Try new DateTime fields first
    if (load['deliveryWindowStart'] != null && load['deliveryWindowEnd'] != null) {
      final startDate = _formatDate(load['deliveryWindowStart']);
      final endDate = _formatDate(load['deliveryWindowEnd']);
      return '$startDate - $endDate';
    }
    
    // Fallback to old string field
    if (load['deliveryWindow'] != null) {
      return _formatDate(load['deliveryWindow']);
    }
    
    return 'N/A';
  }
}
