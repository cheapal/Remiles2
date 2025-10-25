import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/load_card_info.dart';
import 'package:flutter/material.dart';

import '../../common/widgets/recommended_load.dart';
import '../../common/widgets/top_navigation_bar.dart';

class ManageLoadScreen extends StatefulWidget {
  const ManageLoadScreen({super.key});

  @override
  State<ManageLoadScreen> createState() => _ManageLoadScreenState();
}

class _ManageLoadScreenState extends State<ManageLoadScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Available Loads';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
            
            /// Recommended Load (only show for Available Loads)
            if (_selectedFilter == 'Available Loads') ...[
            RecommendedLoad(),
            const SizedBox(height: 20),
            ],

            /// Load Cards
            _buildLoadCards(),
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
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
                      setState(() {
                        _searchQuery = '';
                      });
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
    final filters = ['Available Loads', 'My Bookings', 'In-Transit', 'Cancelled Loads', 'Completed Loads'];
    
    return Column(
      children: [
        // First row
        Row(
          children: [
            _buildFilterButton(filters[0], 0),
            const SizedBox(width: 8),
            _buildFilterButton(filters[1], 1),
          ],
        ),
        const SizedBox(height: 8),
        // Second row
        Row(
          children: [
            _buildFilterButton(filters[2], 2),
            const SizedBox(width: 8),
            _buildFilterButton(filters[3], 3),
            const SizedBox(width: 8),
            _buildFilterButton(filters[4], 4),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterButton(String text, int index) {
    final isActive = _selectedFilter == text;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = text;
          });
        },
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
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadCards() {
    // Filter loads based on selected filter and search query
    final filteredLoads = _getFilteredLoads();
    
    if (filteredLoads.isEmpty) {
      return Center(
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
      );
    }

    return Column(
      children: filteredLoads.map((load) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LoadCardInfo(),
      )).toList(),
    );
  }

  List<Map<String, dynamic>> _getFilteredLoads() {
    // Mock data - replace with actual data from your backend
    final allLoads = [
      {
        'id': '1',
        'title': 'Toronto to Montreal',
        'price': '\$1500',
        'distance': '215 mi',
        'status': 'Available',
        'from': 'Toronto, ON',
        'to': 'Montreal, QC',
        'pickup': 'Sep 1st, 2025',
        'delivery': 'Sep 3rd, 2025',
        'weight': '15,000 lb',
        'equipment': 'Flatbed',
        'category': 'Available Loads',
      },
      {
        'id': '2',
        'title': 'Vancouver to Calgary',
        'price': '\$2200',
        'distance': '350 mi',
        'status': 'Booked',
        'from': 'Vancouver, BC',
        'to': 'Calgary, AB',
        'pickup': 'Sep 5th, 2025',
        'delivery': 'Sep 7th, 2025',
        'weight': '20,000 lb',
        'equipment': 'Dry Van',
        'category': 'My Bookings',
      },
      // Add more mock data as needed
    ];

    return allLoads.where((load) {
      // Filter by category
      if (load['category'] != _selectedFilter) return false;
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (load['title']?.toString().toLowerCase() ?? '').contains(query) ||
               (load['from']?.toString().toLowerCase() ?? '').contains(query) ||
               (load['to']?.toString().toLowerCase() ?? '').contains(query);
      }
      
      return true;
    }).toList();
  }

}
