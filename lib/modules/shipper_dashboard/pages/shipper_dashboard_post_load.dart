import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import '../../../core/utils/google_places_autocomplete.dart';
import '../../../core/constants/app_constants.dart';

class ShipperDashboardPostLoad extends StatefulWidget {
  final Map<String, dynamic>? editLoadData;

  const ShipperDashboardPostLoad({super.key, this.editLoadData});

  @override
  State<ShipperDashboardPostLoad> createState() =>
      _ShipperDashboardPostLoadState();
}

class _ShipperDashboardPostLoadState extends State<ShipperDashboardPostLoad>
    with TickerProviderStateMixin {
  late AnimationController _progressController1;

  // Form controllers
  final TextEditingController _originAddressController =
      TextEditingController();
  final TextEditingController _destinationAddressController =
      TextEditingController();
  final TextEditingController _loadTypeController = TextEditingController();
  final TextEditingController _loadSensitivityController =
      TextEditingController();
  final TextEditingController _loadDescriptionController =
      TextEditingController();
  final TextEditingController _declaredValueController =
      TextEditingController();
  final TextEditingController _pickupDateTimeController =
      TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _deliveryWindowController =
      TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _equipmentNeededController =
      TextEditingController();
  final TextEditingController _quoteBudgetController = TextEditingController();

  // State variables
  bool _isPosting = false;
  bool _isSavingDraft = false;
  XFile? _additionalDocument;
  final ImagePicker _picker = ImagePicker();
  String _weightUnit = 'kg'; // Default weight unit
  String _selectedEquipment = ''; // Selected equipment from dropdown
  final TextEditingController _equipmentOtherController =
      TextEditingController(); // For "Other" option

  // DateTime variables
  DateTime? _pickupDateTime;
  DateTime? _deliveryWindowStart;
  DateTime? _deliveryWindowEnd;

  // For editing existing loads
  String? _previousDocumentUrl;
  String? _previousDocumentName;
  bool _isPreviousDocumentImage = false;

  // Google Places API Key - using AppConstants

  // Load Type Options
  static const List<String> _loadTypeOptions = [
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

  // Load Sensitivity Options
  static const List<String> _loadSensitivityOptions = [
    'Standard',
    'Fragile',
    'Hazardous',
    'Temperature Sensitive',
    'High Value',
    'Oversized',
    'Time Sensitive',
    'Perishable',
    'Flammable',
    'Corrosive',
    'Explosive',
    'Radioactive',
    'Medical/Pharmaceutical',
    'Electronics',
    'Artwork/Antiques',
  ];

  // Weight Unit Options
  static const List<String> _weightUnitOptions = [
    'kg',
    'lbs',
    'tons',
    'tonnes',
  ];

  // Equipment Needed Options
  static const List<String> _equipmentOptions = [
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
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Prefill form if editing existing load
    if (widget.editLoadData != null) {
      _prefillForm();
    }
  }

  void _prefillForm() {
    final data = widget.editLoadData!;

    _originAddressController.text = data['originAddress']?.toString() ?? '';
    _destinationAddressController.text =
        data['destinationAddress']?.toString() ?? '';
    _loadTypeController.text = data['loadType']?.toString() ?? '';
    _loadSensitivityController.text = data['loadSensitivity']?.toString() ?? '';
    _loadDescriptionController.text = data['loadDescription']?.toString() ?? '';
    _declaredValueController.text = data['declaredValue']?.toString() ?? '';
    // Parse pickup date/time
    if (data['pickupDateTime'] != null) {
      if (data['pickupDateTime'] is DateTime) {
        _pickupDateTime = data['pickupDateTime'];
      } else {
        try {
          _pickupDateTime = DateTime.parse(data['pickupDateTime'].toString());
        } catch (e) {
          _pickupDateTime = null;
        }
      }
      _pickupDateTimeController.text = _pickupDateTime != null
          ? '${_pickupDateTime!.day}/${_pickupDateTime!.month}/${_pickupDateTime!.year} ${_pickupDateTime!.hour.toString().padLeft(2, '0')}:${_pickupDateTime!.minute.toString().padLeft(2, '0')}'
          : '';
    }

    _weightController.text = data['weight']?.toString() ?? '';
    // Parse weight unit if it exists, otherwise default to 'kg'
    if (data['weightUnit'] != null) {
      _weightUnit = data['weightUnit'].toString();
    } else {
      _weightUnit = 'kg'; // Default
    }

    // Parse delivery window (single date/time)
    if (data['deliveryWindowStart'] != null &&
        data['deliveryWindowEnd'] != null) {
      try {
        _deliveryWindowStart = data['deliveryWindowStart'] is DateTime
            ? data['deliveryWindowStart']
            : DateTime.parse(data['deliveryWindowStart'].toString());
        _deliveryWindowEnd = data['deliveryWindowEnd'] is DateTime
            ? data['deliveryWindowEnd']
            : DateTime.parse(data['deliveryWindowEnd'].toString());
        // Display date and time
        if (_deliveryWindowStart != null) {
          _deliveryWindowController.text =
              '${_deliveryWindowStart!.day}/${_deliveryWindowStart!.month}/${_deliveryWindowStart!.year} ${_deliveryWindowStart!.hour.toString().padLeft(2, '0')}:${_deliveryWindowStart!.minute.toString().padLeft(2, '0')}';
          // If end date is different, still set it but display only start date/time
          if (_deliveryWindowEnd == null) {
            _deliveryWindowEnd = _deliveryWindowStart;
          }
        }
      } catch (e) {
        _deliveryWindowStart = null;
        _deliveryWindowEnd = null;
        _deliveryWindowController.text =
            data['deliveryWindow']?.toString() ?? '';
      }
    } else if (data['deliveryWindowStart'] != null) {
      // Handle case where only start date/time exists
      try {
        _deliveryWindowStart = data['deliveryWindowStart'] is DateTime
            ? data['deliveryWindowStart']
            : DateTime.parse(data['deliveryWindowStart'].toString());
        _deliveryWindowEnd = _deliveryWindowStart;
        _deliveryWindowController.text = _deliveryWindowStart != null
            ? '${_deliveryWindowStart!.day}/${_deliveryWindowStart!.month}/${_deliveryWindowStart!.year} ${_deliveryWindowStart!.hour.toString().padLeft(2, '0')}:${_deliveryWindowStart!.minute.toString().padLeft(2, '0')}'
            : '';
      } catch (e) {
        _deliveryWindowStart = null;
        _deliveryWindowEnd = null;
        _deliveryWindowController.text =
            data['deliveryWindow']?.toString() ?? '';
      }
    } else {
      _deliveryWindowController.text = data['deliveryWindow']?.toString() ?? '';
    }
    _dimensionsController.text = data['dimensions']?.toString() ?? '';
    // Handle equipment needed - check if it's in the options or custom
    final equipmentValue = data['equipmentNeeded']?.toString() ?? '';
    if (equipmentValue.isNotEmpty) {
      if (_equipmentOptions.contains(equipmentValue)) {
        _selectedEquipment = equipmentValue;
        _equipmentNeededController.text = equipmentValue;
      } else {
        // It's a custom value, set to "Other" and populate the other field
        _selectedEquipment = 'Other';
        _equipmentNeededController.text = 'Other';
        _equipmentOtherController.text = equipmentValue;
      }
    }
    _quoteBudgetController.text = data['quoteBudget']?.toString() ?? '';

    // Handle additional document if it exists
    if (data['additionalDocument'] != null) {
      _previousDocumentUrl = data['additionalDocument'].toString();

      // Extract filename from URL (get the part after the last '/')
      final urlParts = _previousDocumentUrl!.split('/');
      _previousDocumentName = urlParts.isNotEmpty
          ? urlParts.last
          : 'Previous Document';

      // Check if it's an image based on file extension
      final imageExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.bmp',
        '.webp',
      ];
      final urlLower = _previousDocumentUrl!.toLowerCase();

      // Check both endsWith and contains for more flexible detection
      _isPreviousDocumentImage = imageExtensions.any(
        (ext) => urlLower.endsWith(ext) || urlLower.contains(ext),
      );

      // If we can't determine if it's an image, assume it might be and let the UI handle it
      if (!_isPreviousDocumentImage &&
          (urlLower.contains('image') || urlLower.contains('photo'))) {
        _isPreviousDocumentImage = true;
      }
    }
  }

  @override
  void dispose() {
    _progressController1.dispose();
    _originAddressController.dispose();
    _destinationAddressController.dispose();
    _loadTypeController.dispose();
    _loadSensitivityController.dispose();
    _loadDescriptionController.dispose();
    _declaredValueController.dispose();
    _pickupDateTimeController.dispose();
    _weightController.dispose();
    _deliveryWindowController.dispose();
    _dimensionsController.dispose();
    _equipmentNeededController.dispose();
    _equipmentOtherController.dispose();
    _quoteBudgetController.dispose();
    super.dispose();
  }

  // Date/Time picker methods
  Future<void> _selectPickupDateTime() async {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      currentTime: _pickupDateTime ?? DateTime.now(),
      locale: LocaleType.en,
      onConfirm: (date) {
        setState(() {
          _pickupDateTime = date;
          _pickupDateTimeController.text =
              '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

          // If delivery is set and is before the new pickup time, clear it
          if (_deliveryWindowStart != null &&
              _deliveryWindowStart!.isBefore(date)) {
            _deliveryWindowStart = null;
            _deliveryWindowEnd = null;
            _deliveryWindowController.clear();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Delivery date/time has been cleared as it was before pickup time. Please select a new delivery date/time.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      },
    );
  }

  Future<void> _selectDeliveryWindow() async {
    // Calculate minimum delivery time (must be after pickup time)
    DateTime minDeliveryTime;
    if (_pickupDateTime != null) {
      // Delivery must be at least 1 hour after pickup
      minDeliveryTime = _pickupDateTime!.add(const Duration(hours: 1));
    } else {
      // If no pickup time set, delivery can be from now
      minDeliveryTime = DateTime.now();
    }

    // Ensure minDeliveryTime is not in the past
    if (minDeliveryTime.isBefore(DateTime.now())) {
      minDeliveryTime = DateTime.now().add(const Duration(hours: 1));
    }

    // Set current delivery time, ensuring it's not before pickup
    DateTime currentDeliveryTime = _deliveryWindowStart ?? minDeliveryTime;
    if (currentDeliveryTime.isBefore(minDeliveryTime)) {
      currentDeliveryTime = minDeliveryTime;
    }

    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: minDeliveryTime,
      maxTime: DateTime.now().add(const Duration(days: 365)),
      currentTime: currentDeliveryTime,
      locale: LocaleType.en,
      onConfirm: (date) {
        // Validate that delivery is after pickup
        if (_pickupDateTime != null && date.isBefore(_pickupDateTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Delivery date/time must be after pickup date/time. Please select a later time.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Validate that delivery is at least 1 hour after pickup
        if (_pickupDateTime != null) {
          final difference = date.difference(_pickupDateTime!);
          if (difference.inHours < 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Delivery must be at least 1 hour after pickup time.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
        }

        setState(() {
          // Set both start and end to the same date/time (delivery date/time)
          // This represents the delivery date/time of the journey
          _deliveryWindowStart = date;
          _deliveryWindowEnd = date;
          _deliveryWindowController.text =
              '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: topPanelColor,
      //   elevation: 0,
      //   toolbarHeight: 60,
      //   title: Text(
      //     widget.editLoadData != null ? 'Edit Load' : 'Post Load',
      //   ),
      // ),
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Navigation Bar
              TopNavigationBar(context),

              // Form fields
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTabletOrDesktop ? 100.0 : 30.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 35),
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
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
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                widget.editLoadData != null
                                    ? 'Edit Load'
                                    : 'Post a New Load',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 26,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Image.asset(
                                'assets/yellow_trolly.png',
                                width: 30,
                                height: 30,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: GooglePlacesAutocomplete(
                            controller: _originAddressController,
                            hintText: 'Origin Address',
                            icon: Icons.location_on,
                            apiKey: AppConstants.googleApiKey,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: GooglePlacesAutocomplete(
                            controller: _destinationAddressController,
                            hintText: 'Destination Address',
                            icon: Icons.location_on,
                            apiKey: AppConstants.googleApiKey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            context,
                            "Load Type",
                            _loadTypeController,
                            _loadTypeOptions,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDropdownField(
                            context,
                            "Load Sensitivity",
                            _loadSensitivityController,
                            _loadSensitivityOptions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildTextArea(
                      context,
                      "Please Provide a Specific Load Description",
                      _loadDescriptionController,
                    ),
                    const SizedBox(height: 25),
                    _buildNumericInputField(
                      context,
                      "Declared Value (For Insurance) (CAD)",
                      _declaredValueController,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeField(
                            context,
                            "Pick Up Date/Time",
                            _pickupDateTimeController,
                            _selectPickupDateTime,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildWeightField(
                            context,
                            "Weight",
                            _weightController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeField(
                            context,
                            "Delivery Window",
                            _deliveryWindowController,
                            _selectDeliveryWindow,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildInputField(
                            context,
                            "Dimensions (Optional)",
                            _dimensionsController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Equipment Needed Dropdown
                    _buildEquipmentDropdown(context),
                    // Show custom equipment field only if "Other" is selected
                    if (_selectedEquipment == 'Other') ...[
                      const SizedBox(height: 15),
                      _buildInputField(
                        context,
                        "Specify Equipment (Required)",
                        _equipmentOtherController,
                      ),
                    ],
                    const SizedBox(height: 25),
                    _buildNumericInputField(
                      context,
                      "Quote/Budget (CAD)",
                      _quoteBudgetController,
                    ),
                    const SizedBox(height: 25),
                    _buildUploadField(
                      context,
                      "Upload Additional Documents (Optional)",
                      onTap: () => _pickDocument(),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          widget.editLoadData != null
                              ? "Update Draft"
                              : "Save As Draft",
                          const Color(0xFF195529),
                          Colors.white,
                          () => _saveAsDraft(),
                          width: 110.45,
                          height: 42.55,
                        ),
                        const SizedBox(width: 15),
                        _buildActionButton(
                          widget.editLoadData != null ? "Update" : "Post",
                          const Color(0xFFFFCF5F),
                          Colors.black,
                          () => _postLoad(),
                          width: 180,
                          height: 40,
                          isPostLoad: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
  ) {
    return Container(
      width: double.infinity,
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF959595),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
    List<String> options,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options[index];
                          final isSelected = controller.text == option;
                          return ListTile(
                            title: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF43975A)
                                    : Colors.black,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF43975A),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                controller.text = option;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? hintText : controller.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: controller.text.isEmpty
                          ? const Color(0xFF959595)
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Color(0xFF959595),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Equipment Needed dropdown with "Other" option support
  Widget _buildEquipmentDropdown(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _equipmentOptions.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = _equipmentOptions[index];
                          final isSelected = _selectedEquipment == option;
                          return ListTile(
                            title: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF43975A)
                                    : Colors.black,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Color(0xFF43975A),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedEquipment = option;
                                _equipmentNeededController.text = option;
                                // Clear "Other" field if switching away from "Other"
                                if (option != 'Other') {
                                  _equipmentOtherController.clear();
                                }
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedEquipment.isEmpty
                        ? 'Equipment Needed (Optional)'
                        : _selectedEquipment,
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedEquipment.isEmpty
                          ? const Color(0xFF959595)
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Color(0xFF959595),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericInputField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
  ) {
    return Container(
      width: double.infinity,
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF959595),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
  ) {
    return Container(
      width: double.infinity,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF959595),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.4,
                    minChildSize: 0.3,
                    maxChildSize: 0.6,
                    expand: false,
                    builder: (context, scrollController) {
                      return Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(top: 12, bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: _weightUnitOptions.length,
                              itemBuilder: (BuildContext context, int index) {
                                final unit = _weightUnitOptions[index];
                                final isSelected = _weightUnit == unit;
                                return ListTile(
                                  title: Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF43975A)
                                          : Colors.black,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Color(0xFF43975A),
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _weightUnit = unit;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF43975A).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _weightUnit,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF43975A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Color(0xFF43975A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField(
    BuildContext context,
    String hintText,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? hintText : controller.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: controller.text.isEmpty
                          ? const Color(0xFF959595)
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF959595),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea(
    BuildContext context,
    String hintText,
    TextEditingController controller,
  ) {
    return Container(
      width: double.infinity,
      height: 85,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF959595),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildUploadField(
    BuildContext context,
    String text, {
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 57,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(183, 123, 40, 0.44),
                  blurRadius: 2.8,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: _additionalDocument != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Document Selected',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : _previousDocumentUrl != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Show small image preview if it's an image
                        if (_isPreviousDocumentImage)
                          Container(
                            width: 32,
                            height: 32,
                            margin: EdgeInsets.only(left: 8, right: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                _previousDocumentUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Container(
                                    width: 32,
                                    height: 32,
                                    child: Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image,
                                    color: Colors.blue,
                                    size: 20,
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          // Always show document icon for non-images
                          Icon(Icons.description, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _previousDocumentName ?? 'Previous Document',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Image.asset(
                      'assets/upload_icon.png',
                      width: 30,
                      height: 30,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _previousDocumentUrl != null
              ? "Previous Document (Tap to replace)"
              : text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Color(0xFF959595),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed, {
    double? width,
    double? height,
    bool isPostLoad = false,
  }) {
    final isLoading = isPostLoad ? _isPosting : _isSavingDraft;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isLoading ? bgColor.withOpacity(0.7) : bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (!isPostLoad)
              const BoxShadow(
                color: Color.fromRGBO(25, 85, 41, 0.36),
                blurRadius: 2.8,
                spreadRadius: 0,
                offset: Offset(0, 2.8),
              ),
            if (isPostLoad)
              const BoxShadow(
                color: Color.fromRGBO(25, 85, 41, 0.36),
                blurRadius: 2.8,
                spreadRadius: 0,
                offset: Offset(0, 2.8),
              ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: isPostLoad ? 20 : 11.2,
                    color: textColor,
                    fontWeight: isPostLoad ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  // ======== Methods ========

  Future<void> _pickDocument() async {
    try {
      final XFile? document = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (document != null) {
        setState(() {
          _additionalDocument = document;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document selected successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting document: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveAsDraft() async {
    if (_isSavingDraft) return;

    // Validate that at least one field is filled
    if (!_validateDraftForm()) return;

    setState(() => _isSavingDraft = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper != null) {
        final loadData = _buildLoadData(isDraft: true);

        // Check if we're editing an existing load
        if (widget.editLoadData != null && widget.editLoadData!['id'] != null) {
          // Editing existing load
          final loadId = widget.editLoadData!['id'].toString();
          loadData['id'] = loadId;

          // Upload new document if provided
          if (_additionalDocument != null) {
            final documentUrl = await FirebaseService.uploadLoadDocument(
              shipper.uid,
              loadId,
              _additionalDocument!,
            );
            if (documentUrl != null) {
              loadData['additionalDocument'] = documentUrl;
            }
          } else if (_previousDocumentUrl != null) {
            // Keep existing document if no new one uploaded
            loadData['additionalDocument'] = _previousDocumentUrl;
          }

          await FirebaseService.updateShipperLoad(
            shipper.uid,
            loadId,
            loadData,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Network timeout. Please check your internet connection.',
              );
            },
          );
        } else {
          // Creating new load
          final loadId = DateTime.now().millisecondsSinceEpoch.toString();
          loadData['id'] = loadId;

          // Upload document if provided
          if (_additionalDocument != null) {
            final documentUrl = await FirebaseService.uploadLoadDocument(
              shipper.uid,
              loadId,
              _additionalDocument!,
            );
            if (documentUrl != null) {
              loadData['additionalDocument'] = documentUrl;
            }
          }

          await FirebaseService.saveShipperLoad(shipper.uid, loadData).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Network timeout. Please check your internet connection.',
              );
            },
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.editLoadData != null
                    ? 'Load draft updated successfully!'
                    : 'Load saved as draft successfully',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _postLoad() async {
    if (_isPosting) return;

    // Validate required fields
    if (!_validateForm()) return;

    setState(() => _isPosting = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper != null) {
        final loadData = _buildLoadData(isDraft: false);

        // Check if we're editing an existing load
        if (widget.editLoadData != null && widget.editLoadData!['id'] != null) {
          // Editing existing load
          final loadId = widget.editLoadData!['id'].toString();
          loadData['id'] = loadId;

          // Upload new document if provided
          if (_additionalDocument != null) {
            final documentUrl = await FirebaseService.uploadLoadDocument(
              shipper.uid,
              loadId,
              _additionalDocument!,
            );
            if (documentUrl != null) {
              loadData['additionalDocument'] = documentUrl;
            }
          } else if (_previousDocumentUrl != null) {
            // Keep existing document if no new one uploaded
            loadData['additionalDocument'] = _previousDocumentUrl;
          }

          await FirebaseService.updateShipperLoad(
            shipper.uid,
            loadId,
            loadData,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Network timeout. Please check your internet connection.',
              );
            },
          );
        } else {
          // Creating new load
          final loadId = DateTime.now().millisecondsSinceEpoch.toString();
          loadData['id'] = loadId;

          // Upload document if provided
          if (_additionalDocument != null) {
            final documentUrl = await FirebaseService.uploadLoadDocument(
              shipper.uid,
              loadId,
              _additionalDocument!,
            );
            if (documentUrl != null) {
              loadData['additionalDocument'] = documentUrl;
            }
          }

          await FirebaseService.saveShipperLoad(shipper.uid, loadData).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Network timeout. Please check your internet connection.',
              );
            },
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.editLoadData != null
                    ? 'Load updated successfully!'
                    : 'Load posted successfully!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Clear form
          _clearForm();

          // Navigate back with result indicating load was updated/created
          Navigator.of(context).pop({'loadUpdated': true});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post load: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  bool _validateDraftForm() {
    // Check if at least one field has content
    final hasContent =
        _originAddressController.text.trim().isNotEmpty ||
        _destinationAddressController.text.trim().isNotEmpty ||
        _loadTypeController.text.trim().isNotEmpty ||
        _loadSensitivityController.text.trim().isNotEmpty ||
        _loadDescriptionController.text.trim().isNotEmpty ||
        _declaredValueController.text.trim().isNotEmpty ||
        _pickupDateTime != null ||
        _weightController.text.trim().isNotEmpty ||
        _deliveryWindowStart != null ||
        _deliveryWindowEnd != null ||
        _dimensionsController.text.trim().isNotEmpty ||
        _equipmentNeededController.text.trim().isNotEmpty ||
        (_selectedEquipment == 'Other' &&
            _equipmentOtherController.text.trim().isNotEmpty) ||
        _quoteBudgetController.text.trim().isNotEmpty ||
        _additionalDocument != null;

    if (!hasContent) {
      _showAlertDialog(
        context,
        'Please fill in at least one field before saving as draft.',
      );
      return false;
    }

    return true;
  }

  bool _validateForm() {
    if (_originAddressController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter origin address.');
      return false;
    }

    if (_destinationAddressController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter destination address.');
      return false;
    }

    if (_loadTypeController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please select load type.');
      return false;
    }

    // Validate load type is from the options
    if (!_loadTypeOptions.contains(_loadTypeController.text.trim())) {
      _showAlertDialog(
        context,
        'Please select a valid load type from the dropdown.',
      );
      return false;
    }

    if (_loadSensitivityController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please select load sensitivity.');
      return false;
    }

    // Validate load sensitivity is from the options
    if (!_loadSensitivityOptions.contains(
      _loadSensitivityController.text.trim(),
    )) {
      _showAlertDialog(
        context,
        'Please select a valid load sensitivity from the dropdown.',
      );
      return false;
    }

    if (_loadDescriptionController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please provide a load description.');
      return false;
    }

    if (_loadDescriptionController.text.trim().length < 10) {
      _showAlertDialog(
        context,
        'Load description must be at least 10 characters long.',
      );
      return false;
    }

    if (_declaredValueController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter declared value.');
      return false;
    }

    // Validate declared value is a valid positive number
    final declaredValue = double.tryParse(_declaredValueController.text.trim());
    if (declaredValue == null || declaredValue <= 0) {
      _showAlertDialog(
        context,
        'Please enter a valid declared value (must be a positive number).',
      );
      return false;
    }

    if (_pickupDateTime == null) {
      _showAlertDialog(context, 'Please select pickup date/time.');
      return false;
    }

    // Validate pickup date is not in the past
    if (_pickupDateTime!.isBefore(DateTime.now())) {
      _showAlertDialog(context, 'Pickup date/time cannot be in the past.');
      return false;
    }

    if (_weightController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter weight.');
      return false;
    }

    // Validate weight is a valid positive number
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      _showAlertDialog(
        context,
        'Please enter a valid weight (must be a positive number).',
      );
      return false;
    }

    if (_deliveryWindowStart == null || _deliveryWindowEnd == null) {
      _showAlertDialog(context, 'Please select delivery date/time.');
      return false;
    }

    // Validate that delivery is after pickup
    if (_pickupDateTime != null && _deliveryWindowStart != null) {
      if (_deliveryWindowStart!.isBefore(_pickupDateTime!) ||
          _deliveryWindowStart!.isAtSameMomentAs(_pickupDateTime!)) {
        _showAlertDialog(
          context,
          'Delivery date/time must be after pickup date/time.',
        );
        return false;
      }

      // Validate that delivery is at least 1 hour after pickup
      final difference = _deliveryWindowStart!.difference(_pickupDateTime!);
      if (difference.inHours < 1) {
        _showAlertDialog(
          context,
          'Delivery must be at least 1 hour after pickup time.',
        );
        return false;
      }
    }

    // Validate equipment "Other" field if "Other" is selected
    if (_selectedEquipment == 'Other') {
      if (_equipmentOtherController.text.trim().isEmpty) {
        _showAlertDialog(
          context,
          'Please specify the equipment type when "Other" is selected.',
        );
        return false;
      }
    }

    if (_quoteBudgetController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter quote/budget.');
      return false;
    }

    // Validate quote/budget is a valid positive number
    final quoteBudget = double.tryParse(_quoteBudgetController.text.trim());
    if (quoteBudget == null || quoteBudget <= 0) {
      _showAlertDialog(
        context,
        'Please enter a valid quote/budget (must be a positive number).',
      );
      return false;
    }

    return true;
  }

  Map<String, dynamic> _buildLoadData({required bool isDraft}) {
    // Check if this is a repost (editing a cancelled load)
    final isRepost =
        widget.editLoadData != null &&
        (widget.editLoadData!['status'] == 'cancelled' ||
            widget.editLoadData!['status'] == 'completed');

    // Determine status: draft -> 'draft', repost -> 'available', new/update -> 'active'
    String status;
    if (isDraft) {
      status = 'draft';
    } else if (isRepost) {
      status = 'available';
    } else {
      status = 'active';
    }

    return {
      'originAddress': _originAddressController.text.trim(),
      'destinationAddress': _destinationAddressController.text.trim(),
      'loadType': _loadTypeController.text.trim(),
      'loadSensitivity': _loadSensitivityController.text.trim(),
      'loadDescription': _loadDescriptionController.text.trim(),
      'declaredValue': _declaredValueController.text.trim(),
      'pickupDateTime': _pickupDateTime?.toIso8601String(),
      'weight': _weightController.text.trim(),
      'weightUnit': _weightUnit,
      'deliveryWindowStart': _deliveryWindowStart?.toIso8601String(),
      'deliveryWindowEnd': _deliveryWindowEnd?.toIso8601String(),
      'deliveryWindow': _deliveryWindowController.text
          .trim(), // Keep for backward compatibility
      'dimensions': _dimensionsController.text.trim(),
      // Save custom equipment if "Other" is selected, otherwise save the selected option
      'equipmentNeeded': _selectedEquipment == 'Other'
          ? _equipmentOtherController.text.trim()
          : _equipmentNeededController.text.trim(),
      'quoteBudget': _quoteBudgetController.text.trim(),
      'isDraft': isDraft,
      'status': status,
      'isBooked': false, // New loads are not booked initially
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  void _clearForm() {
    _originAddressController.clear();
    _destinationAddressController.clear();
    _loadTypeController.clear();
    _loadSensitivityController.clear();
    _loadDescriptionController.clear();
    _declaredValueController.clear();
    _pickupDateTimeController.clear();
    _weightController.clear();
    _deliveryWindowController.clear();
    _dimensionsController.clear();
    _equipmentNeededController.clear();
    _equipmentOtherController.clear();
    _quoteBudgetController.clear();
    setState(() {
      _additionalDocument = null;
      _pickupDateTime = null;
      _deliveryWindowStart = null;
      _deliveryWindowEnd = null;
      _weightUnit = 'kg'; // Reset to default
      _selectedEquipment = ''; // Reset equipment selection
    });
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
