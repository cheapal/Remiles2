import 'package:flutter/material.dart';

class FilterManageLoadScreen extends StatefulWidget {
  final Map<String, String> currentFilters;
  final Function(Map<String, String>) onApplyFilters;

  const FilterManageLoadScreen({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterManageLoadScreen> createState() => _FilterManageLoadScreenState();
}

class _FilterManageLoadScreenState extends State<FilterManageLoadScreen> {
  String _selectedStatus = 'all';
  String _selectedLoadType = 'all';
  String _selectedEquipmentType = 'all';
  String _selectedOriginCity = 'all';
  String _selectedDestinationCity = 'all';
  String _selectedSortBy = 'createdAt';
  String _selectedSortOrder = 'desc';

  // Filter options
  final List<String> _statusOptions = [
    'all',
    'active',
    'inTransit',
    'booked',
    'cancelled',
    'completed',
  ];

  final List<String> _loadTypeOptions = [
    'all',
    'General Freight',
    'Food & Beverages',
    'Electronics',
    'Automotive Parts',
    'Machinery & Equipment',
    'Building Materials',
    'Furniture',
    'Textiles & Apparel',
    'Chemicals',
    'Pharmaceuticals',
    'Agricultural Products',
    'Livestock',
    'Hazardous Materials',
    'Oversized Loads',
    'Fragile Goods',
    'Temperature Controlled',
    'High Value Cargo',
    'Bulk Materials',
    'Retail Goods',
    'Industrial Supplies',
  ];

  final List<String> _equipmentTypeOptions = [
    'all',
    'Dry Van',
    'Refrigerated (Reefer)',
    'Flatbed',
    'Step Deck',
    'Lowboy',
    'Car Carrier',
    'Tanker',
    'Box Truck',
    'Dump Truck',
    'Grain Hopper',
    'Livestock Trailer',
    'Container Chassis',
    'Heavy Haul',
    'Auto Transport',
    'Intermodal',
  ];

  final List<String> _cityOptions = [
    'all',
    'Toronto, ON',
    'Vancouver, BC',
    'Montreal, QC',
    'Calgary, AB',
    'Edmonton, AB',
    'Ottawa, ON',
    'Winnipeg, MB',
    'Quebec City, QC',
    'Hamilton, ON',
    'Kitchener, ON',
    'London, ON',
    'Victoria, BC',
    'Halifax, NS',
    'Oshawa, ON',
    'Windsor, ON',
    'Saskatoon, SK',
    'Regina, SK',
    'Sherbrooke, QC',
    'Kelowna, BC',
    'Barrie, ON',
    'Abbotsford, BC',
    'Sudbury, ON',
    'Kingston, ON',
    'Trois-Rivières, QC',
    'Guelph, ON',
    'Cambridge, ON',
    'Waterloo, ON',
    'Brantford, ON',
    'Moncton, NB',
    'Saint John, NB',
  ];

  final List<String> _sortByOptions = [
    'createdAt',
    'pickupDateTime',
    'deliveryDateTime',
    'loadType',
    'originAddress',
    'destinationAddress',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilters['status'] ?? 'all';
    _selectedLoadType = widget.currentFilters['loadType'] ?? 'all';
    _selectedEquipmentType = widget.currentFilters['equipmentType'] ?? 'all';
    _selectedOriginCity = widget.currentFilters['originCity'] ?? 'all';
    _selectedDestinationCity = widget.currentFilters['destinationCity'] ?? 'all';
    _selectedSortBy = widget.currentFilters['sortBy'] ?? 'createdAt';
    _selectedSortOrder = widget.currentFilters['sortOrder'] ?? 'desc';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Loads',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF064232),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Filter
                    _buildFilterSection(
                      'Status',
                      _selectedStatus,
                      _statusOptions,
                      (value) => setState(() => _selectedStatus = value!),
                    ),
                    const SizedBox(height: 20),

                    // Load Type Filter
                    _buildFilterSection(
                      'Load Type',
                      _selectedLoadType,
                      _loadTypeOptions,
                      (value) => setState(() => _selectedLoadType = value!),
                    ),
                    const SizedBox(height: 20),

                    // Equipment Type Filter
                    _buildFilterSection(
                      'Equipment Type',
                      _selectedEquipmentType,
                      _equipmentTypeOptions,
                      (value) => setState(() => _selectedEquipmentType = value!),
                    ),
                    const SizedBox(height: 20),

                    // Origin City Filter
                    _buildFilterSection(
                      'Origin City',
                      _selectedOriginCity,
                      _cityOptions,
                      (value) => setState(() => _selectedOriginCity = value!),
                    ),
                    const SizedBox(height: 20),

                    // Destination City Filter
                    _buildFilterSection(
                      'Destination City',
                      _selectedDestinationCity,
                      _cityOptions,
                      (value) => setState(() => _selectedDestinationCity = value!),
                    ),
                    const SizedBox(height: 20),

                    // Sort By Filter
                    _buildFilterSection(
                      'Sort By',
                      _selectedSortBy,
                      _sortByOptions,
                      (value) => setState(() => _selectedSortBy = value!),
                    ),
                    const SizedBox(height: 20),

                    // Sort Order Filter
                    _buildFilterSection(
                      'Sort Order',
                      _selectedSortOrder,
                      ['desc', 'asc'],
                      (value) => setState(() => _selectedSortOrder = value!),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064232),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    String selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF064232),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              items: options.map((String option) {
                String displayText;
                if (option == 'all') {
                  displayText = 'All $title';
                } else if (title == 'Status') {
                  // Special handling for status options
                  switch (option) {
                    case 'active':
                      displayText = 'Active';
                      break;
                    case 'inTransit':
                      displayText = 'In-Transit';
                      break;
                    case 'booked':
                      displayText = 'Booked';
                      break;
                    case 'cancelled':
                      displayText = 'Cancelled';
                      break;
                    case 'completed':
                      displayText = 'Completed';
                      break;
                    default:
                      displayText = option;
                  }
                } else {
                  displayText = option;
                }
                
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    displayText,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedLoadType = 'all';
      _selectedEquipmentType = 'all';
      _selectedOriginCity = 'all';
      _selectedDestinationCity = 'all';
      _selectedSortBy = 'createdAt';
      _selectedSortOrder = 'desc';
    });
  }

  void _applyFilters() {
    final filters = {
      'status': _selectedStatus,
      'loadType': _selectedLoadType,
      'equipmentType': _selectedEquipmentType,
      'originCity': _selectedOriginCity,
      'destinationCity': _selectedDestinationCity,
      'sortBy': _selectedSortBy,
      'sortOrder': _selectedSortOrder,
    };
    
    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }
}