import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../core/firebase_service.dart';

class CarrierPreferencesPage extends StatefulWidget {
  const CarrierPreferencesPage({super.key});

  @override
  State<CarrierPreferencesPage> createState() => _CarrierPreferencesPageState();
}

class _CarrierPreferencesPageState extends State<CarrierPreferencesPage> {
  List<String> _selectedVehicleTypes = [];
  List<String> _selectedServiceAreas = [];
  String? _selectedMaxWeight;
  List<String> _selectedPreferredLoadTypes = [];
  String? _selectedMaxDistance;
  bool _isSaving = false;

  // Vehicle types commonly used in logistics
  final List<String> _vehicleTypes = [
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

  // Comprehensive Canadian cities for service areas
  final List<String> _serviceAreaOptions = [
    // Ontario
    'Toronto, ON',
    'Ottawa, ON',
    'Hamilton, ON',
    'London, ON',
    'Kitchener, ON',
    'Windsor, ON',
    'Oshawa, ON',
    'Barrie, ON',
    'Sudbury, ON',
    'Kingston, ON',
    'Guelph, ON',
    'Cambridge, ON',
    'Waterloo, ON',
    'Brantford, ON',
    'Thunder Bay, ON',
    'Peterborough, ON',
    'Sarnia, ON',
    'Sault Ste. Marie, ON',
    'North Bay, ON',
    'Belleville, ON',
    'Cornwall, ON',
    'Chatham, ON',
    'Sarnia, ON',
    'Timmins, ON',
    'Kenora, ON',
    
    // British Columbia
    'Vancouver, BC',
    'Victoria, BC',
    'Surrey, BC',
    'Burnaby, BC',
    'Richmond, BC',
    'Abbotsford, BC',
    'Coquitlam, BC',
    'Saanich, BC',
    'Delta, BC',
    'Kelowna, BC',
    'Langley, BC',
    'Kamloops, BC',
    'Nanaimo, BC',
    'Chilliwack, BC',
    'Prince George, BC',
    'Vernon, BC',
    'Courtenay, BC',
    'Fort St. John, BC',
    'Cranbrook, BC',
    'Penticton, BC',
    
    // Quebec
    'Montreal, QC',
    'Quebec City, QC',
    'Laval, QC',
    'Gatineau, QC',
    'Longueuil, QC',
    'Sherbrooke, QC',
    'Saguenay, QC',
    'Lévis, QC',
    'Trois-Rivières, QC',
    'Terrebonne, QC',
    'Saint-Jean-sur-Richelieu, QC',
    'Brossard, QC',
    'Repentigny, QC',
    'Drummondville, QC',
    'Saint-Jérôme, QC',
    'Granby, QC',
    'Shawinigan, QC',
    'Dollard-des-Ormeaux, QC',
    'Blainville, QC',
    'Châteauguay, QC',
    
    // Alberta
    'Calgary, AB',
    'Edmonton, AB',
    'Red Deer, AB',
    'Lethbridge, AB',
    'St. Albert, AB',
    'Medicine Hat, AB',
    'Grande Prairie, AB',
    'Airdrie, AB',
    'Spruce Grove, AB',
    'Leduc, AB',
    'Fort McMurray, AB',
    'Cochrane, AB',
    'Camrose, AB',
    'Brooks, AB',
    'Cold Lake, AB',
    'Wetaskiwin, AB',
    'Lloydminster, AB',
    'Canmore, AB',
    'Strathmore, AB',
    'High River, AB',
    
    // Manitoba
    'Winnipeg, MB',
    'Brandon, MB',
    'Steinbach, MB',
    'Thompson, MB',
    'Portage la Prairie, MB',
    'Winkler, MB',
    'Selkirk, MB',
    'Morden, MB',
    'Flin Flon, MB',
    'Dauphin, MB',
    
    // Saskatchewan
    'Saskatoon, SK',
    'Regina, SK',
    'Prince Albert, SK',
    'Moose Jaw, SK',
    'Swift Current, SK',
    'Yorkton, SK',
    'North Battleford, SK',
    'Estevan, SK',
    'Weyburn, SK',
    'Cranbrook, SK',
    
    // Nova Scotia
    'Halifax, NS',
    'Sydney, NS',
    'Dartmouth, NS',
    'Truro, NS',
    'New Glasgow, NS',
    'Glace Bay, NS',
    'Kentville, NS',
    'Amherst, NS',
    'Bridgewater, NS',
    'Yarmouth, NS',
    
    // New Brunswick
    'Moncton, NB',
    'Saint John, NB',
    'Fredericton, NB',
    'Dieppe, NB',
    'Riverview, NB',
    'Edmundston, NB',
    'Bathurst, NB',
    'Miramichi, NB',
    'Campbellton, NB',
    'Oromocto, NB',
    
    // Newfoundland and Labrador
    'St. John\'s, NL',
    'Mount Pearl, NL',
    'Corner Brook, NL',
    'Conception Bay South, NL',
    'Grand Falls-Windsor, NL',
    'Gander, NL',
    'Happy Valley-Goose Bay, NL',
    'Labrador City, NL',
    'Stephenville, NL',
    'Clarenville, NL',
    
    // Prince Edward Island
    'Charlottetown, PE',
    'Summerside, PE',
    'Stratford, PE',
    'Cornwall, PE',
    'Montague, PE',
    
    // Northwest Territories
    'Yellowknife, NT',
    'Hay River, NT',
    'Inuvik, NT',
    'Fort Smith, NT',
    'Behchokò, NT',
    
    // Yukon
    'Whitehorse, YT',
    'Dawson City, YT',
    'Watson Lake, YT',
    'Haines Junction, YT',
    'Carmacks, YT',
    
    // Nunavut
    'Iqaluit, NU',
    'Rankin Inlet, NU',
    'Arviat, NU',
    'Baker Lake, NU',
    'Cambridge Bay, NU',
  ];

  // Weight capacity options
  final List<String> _maxWeightOptions = [
    '5,000 lbs',
    '10,000 lbs',
    '15,000 lbs',
    '20,000 lbs',
    '25,000 lbs',
    '30,000 lbs',
    '40,000 lbs',
    '50,000 lbs',
    '60,000 lbs',
    '80,000 lbs',
    '100,000 lbs',
    'No Limit',
  ];

  // Distance options
  final List<String> _maxDistanceOptions = [
    '50 miles',
    '100 miles',
    '200 miles',
    '300 miles',
    '500 miles',
    '750 miles',
    '1,000 miles',
    '1,500 miles',
    '2,000 miles',
    'Nationwide',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
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

                    /// Section: Vehicle Types
                    const Text(
                      "Vehicle Types",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMultiSelectDropdown(
                      "Select Vehicle Types",
                      _selectedVehicleTypes,
                      _vehicleTypes,
                      (selected) {
                        setState(() {
                          _selectedVehicleTypes = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 28),

                    /// Section: Service Areas
                    const Text(
                      "Service Areas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMultiSelectDropdown(
                      "Select Service Areas",
                      _selectedServiceAreas,
                      _serviceAreaOptions,
                      (selected) {
                        setState(() {
                          _selectedServiceAreas = selected;
                        });
                      },
                    ),
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
                    _buildMultiSelectDropdown(
                      "Select Preferred Load Types",
                      _selectedPreferredLoadTypes,
                      _loadTypes,
                      (selected) {
                        print('Load types selection changed: $selected');
                        setState(() {
                          _selectedPreferredLoadTypes = selected;
                        });
                        print('Load types state updated: $_selectedPreferredLoadTypes');
                      },
                    ),
                    const SizedBox(height: 20),

                    /// Capacity & Distance
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            "Max Weight",
                            _selectedMaxWeight,
                            _maxWeightOptions,
                            (value) {
                              setState(() {
                                _selectedMaxWeight = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            "Max Distance",
                            _selectedMaxDistance,
                            _maxDistanceOptions,
                            (value) {
                              print('Max distance selection changed: $value');
                              setState(() {
                                _selectedMaxDistance = value;
                              });
                              print('Max distance state updated: $_selectedMaxDistance');
                            },
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildMultiSelectDropdown(
    String label,
    List<String> selectedItems,
    List<String> options,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _isSaving ? null : () => _showMultiSelectDialog(label, selectedItems, options, onChanged),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItems.isEmpty 
                        ? 'Select $label'
                        : selectedItems.length == 1
                            ? selectedItems.first
                            : '${selectedItems.length} items selected',
                    style: TextStyle(
                      color: selectedItems.isEmpty ? Colors.grey.shade600 : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5D3B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E5D3B).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E5D3B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _isSaving ? null : () {
                        List<String> newSelection = List.from(selectedItems);
                        newSelection.remove(item);
                        onChanged(newSelection);
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: const Color(0xFF2E5D3B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _showMultiSelectDialog(
    String title,
    List<String> selectedItems,
    List<String> options,
    Function(List<String>) onChanged,
  ) {
    List<String> tempSelected = List.from(selectedItems);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = tempSelected.contains(option);
                    
                    return CheckboxListTile(
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 14),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(option);
                          } else {
                            tempSelected.remove(option);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    print('Multi-select dialog: Final selection: $tempSelected');
                    onChanged(tempSelected);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    // Ensure selectedValue is valid
    final validSelectedValue = (selectedValue != null && options.contains(selectedValue)) 
        ? selectedValue 
        : null;
    
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
              value: validSelectedValue,
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
  
  String _findClosestWeightOption(int weight) {
    // Parse all weight options to get their numeric values
    final weightValues = _maxWeightOptions.map((option) {
      if (option == 'No Limit') return 999999;
      final match = RegExp(r'(\d{1,3}(?:,\d{3})*)').firstMatch(option);
      if (match != null) {
        return int.parse(match.group(1)!.replaceAll(',', ''));
      }
      return 0;
    }).toList();
    
    // Find the closest option
    int closestIndex = 0;
    int minDifference = (weight - weightValues[0]).abs();
    
    for (int i = 1; i < weightValues.length; i++) {
      final difference = (weight - weightValues[i]).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }
    
    return _maxWeightOptions[closestIndex];
  }
  
  Future<void> _loadPreferences() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      
      if (carrier != null) {
        print('=== LOAD PREFERENCES DEBUG ===');
        print('Vehicle Types: ${carrier.vehicleTypes}');
        print('Service Areas: ${carrier.serviceAreas}');
        print('Carrier Preferences: ${carrier.carrierPreferences}');
        print('==============================');
        
        setState(() {
          _selectedVehicleTypes = carrier.vehicleTypes ?? [];
          _selectedServiceAreas = carrier.serviceAreas ?? [];
          _selectedPreferredLoadTypes = carrier.carrierPreferences?['preferredLoadTypes'] != null
              ? List<String>.from(carrier.carrierPreferences!['preferredLoadTypes'])
              : [];
          
          // Convert maxWeight back to string format for display
          if (carrier.carrierPreferences?['maxWeight'] != null) {
            final weight = carrier.carrierPreferences!['maxWeight'] as num;
            print('Raw weight from DB: $weight');
            
            // Format with comma for thousands
            final weightString = '${weight.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
              (Match m) => '${m[1]},'
            )} lbs';
            
            print('Formatted weight string: $weightString');
            print('Available options: $_maxWeightOptions');
            
            // Check if this weight exists in our options
            if (_maxWeightOptions.contains(weightString)) {
              _selectedMaxWeight = weightString;
              print('Exact match found: $weightString');
            } else {
              // Find the closest match from our options
              _selectedMaxWeight = _findClosestWeightOption(weight.toInt());
              print('Using closest match: $_selectedMaxWeight');
            }
          }
          
          _selectedMaxDistance = carrier.carrierPreferences?['maxDistance'];
          print('Max Distance: $_selectedMaxDistance');
          print('Preferred Load Types: $_selectedPreferredLoadTypes');
          
          print('=== UI STATE AFTER LOAD ===');
          print('UI Vehicle Types: $_selectedVehicleTypes');
          print('UI Service Areas: $_selectedServiceAreas');
          print('UI Preferred Load Types: $_selectedPreferredLoadTypes');
          print('UI Max Weight: $_selectedMaxWeight');
          print('UI Max Distance: $_selectedMaxDistance');
          print('===========================');
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;
    
    // Debug: Print current state before saving
    print('=== SAVE PREFERENCES DEBUG ===');
    print('Vehicle Types: $_selectedVehicleTypes');
    print('Service Areas: $_selectedServiceAreas');
    print('Preferred Load Types: $_selectedPreferredLoadTypes');
    print('Max Weight: $_selectedMaxWeight');
    print('Max Distance: $_selectedMaxDistance');
    print('==============================');
    
    // Validate that at least some preferences are selected
    if (_selectedVehicleTypes.isEmpty && _selectedServiceAreas.isEmpty) {
      _showAlertDialog(context, 'Please select at least one vehicle type and service area before saving.');
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      
      if (carrier != null) {
        // Prepare preferences data
        final preferencesData = {
          'preferredLoadTypes': _selectedPreferredLoadTypes,
          'maxWeight': _selectedMaxWeight != null 
              ? double.parse(_selectedMaxWeight!.replaceAll(RegExp(r'[^\d.]'), ''))
              : null,
          'maxDistance': _selectedMaxDistance,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        print('Saving preferences: $preferencesData');
        print('Selected Preferred Load Types: $_selectedPreferredLoadTypes');
        print('Selected Max Distance: $_selectedMaxDistance');

        // Update carrier document with new preferences
        await FirebaseService.updateCarrierPreferences(
          carrierUid: carrier.uid,
          vehicleTypes: _selectedVehicleTypes,
          serviceAreas: _selectedServiceAreas,
          carrierPreferences: preferencesData,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        // Refresh the carrier data in AuthProvider
        await authProvider.refreshUser();
        
        // Reload preferences to ensure UI is updated
        await _loadPreferences();
        
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
