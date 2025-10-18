import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';

class ShipperDashboardMyPreferencePage extends StatefulWidget {
  const ShipperDashboardMyPreferencePage({super.key});

  @override
  State<ShipperDashboardMyPreferencePage> createState() => _ShipperDashboardMyPreferencePageState();
}

class _ShipperDashboardMyPreferencePageState extends State<ShipperDashboardMyPreferencePage> {
  String? _selectedTruckType;
  String? _selectedLoadType;
  String? _selectedHomeBase;
  String? _selectedRadius;
  bool _isSaving = false;

  // Truck types commonly used in logistics
  final List<String> _truckTypes = [
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

  // Load types commonly transported
  final List<String> _loadTypes = [
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

  // Common Canadian cities for home base
  final List<String> _homeBaseOptions = [
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

  // Radius options
  final List<String> _radiusOptions = [
    'within 50 km',
    'within 100 km',
    'within 150 km',
    'within 200 km',
    'within 250 km',
    'within 300 km',
    'within 400 km',
    'within 500 km',
    'within 750 km',
    'within 1000 km',
    'Nationwide',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(

          child: Column(
            children: [
              TopNavigationBar(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 40),
                    /// Title
                    const Text(
                      "My Preferences",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Section: Truck & Equipment
                    const Text(
                      "Truck & Equipment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField("Truck Type", _selectedTruckType, _truckTypes, (value) {
                      setState(() {
                        _selectedTruckType = value;
                      });
                    }),
                    const SizedBox(height: 28),

                    /// Section: Service Area / Location
                    const Text(
                      "Service Area / Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField("Home Base", _selectedHomeBase, _homeBaseOptions, (value) {
                      setState(() {
                        _selectedHomeBase = value;
                      });
                    }),
                    const SizedBox(height: 16),
                    _buildDropdownField("Radius", _selectedRadius, _radiusOptions, (value) {
                      setState(() {
                        _selectedRadius = value;
                      });
                    }),
                    const SizedBox(height: 28),

                    /// Section: Load Preferences
                    const Text(
                      "Load Preferences",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField("Load Type", _selectedLoadType, _loadTypes, (value) {
                      setState(() {
                        _selectedLoadType = value;
                      });
                    }),
                    const SizedBox(height: 40),

                    /// Save Button
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSaving 
                              ? const Color(0xFF2E5D3B).withOpacity(0.7)
                              : const Color(0xFF2E5D3B),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isSaving ? null : _savePreferences,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text(
                'Select $label',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isSaving ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ======== Methods ========
  
  Future<void> _loadPreferences() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        final preferences = await FirebaseService.getShipperPreferences(shipper.uid);
        if (preferences != null) {
          setState(() {
            _selectedTruckType = preferences['preferredTruckType'];
            _selectedLoadType = preferences['preferredLoadType'];
            _selectedHomeBase = preferences['preferredHomeBase'];
            _selectedRadius = preferences['preferredRadius'];
          });
        }
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;
    
    // Validate that at least one preference is selected
    if (_selectedTruckType == null && _selectedLoadType == null && 
        _selectedHomeBase == null && _selectedRadius == null) {
      _showAlertDialog(context, 'Please select at least one preference before saving.');
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        final preferencesData = {
          'preferredTruckType': _selectedTruckType,
          'preferredLoadType': _selectedLoadType,
          'preferredHomeBase': _selectedHomeBase,
          'preferredRadius': _selectedRadius,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        await FirebaseService.saveShipperPreferences(
          shipper.uid,
          preferencesData,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate back
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Validation Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
