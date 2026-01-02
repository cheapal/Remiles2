import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/core/utils/canadian_provinces_autocomplete.dart';
import 'package:remiles/core/utils/google_places_autocomplete.dart';
import 'package:remiles/core/utils/multi_select_dialog.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/carrier_dashboard_3.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';
import 'package:remiles/core/constants/app_constants.dart';

class CarrierDashboard2 extends StatefulWidget {
  const CarrierDashboard2({super.key});

  @override
  State<CarrierDashboard2> createState() => _CarrierDashboard2State();
}

class _CarrierDashboard2State extends State<CarrierDashboard2>
    with TickerProviderStateMixin {
  bool _agreeToTerms = false;
  late AnimationController _progressController1;
  int _selectedTab = 0;
  bool _saving = false;
  bool _isLoading = true;

  // Form controllers
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _operatingProvincesController =
      TextEditingController();
  final TextEditingController _commercialInsuranceProviderController =
      TextEditingController();
  final TextEditingController _commercialPolicyNumberController =
      TextEditingController();
  final TextEditingController _commercialExpiryDateController =
      TextEditingController();
  final TextEditingController _commercialCoverageLimitController =
      TextEditingController();
  final TextEditingController _cargoInsuranceProviderController =
      TextEditingController();
  final TextEditingController _cargoPolicyNumberController =
      TextEditingController();
  final TextEditingController _cargoExpiryDateController =
      TextEditingController();
  final TextEditingController _cargoCoverageLimitController =
      TextEditingController();
  final TextEditingController _yearsOfExperienceController =
      TextEditingController();

  // Multi-select state
  List<String> _selectedIndustryTypes = [];
  List<String> _selectedShipmentTypes = [];

  // Options for multi-select
  static const List<String> _industryTypeOptions = [
    'Manufacturing',
    'Retail',
    'Agriculture',
    'Construction',
    'Food & Beverage',
    'Healthcare',
    'Technology',
    'Automotive',
    'Textiles',
    'Chemicals',
    'Mining',
    'Energy',
    'Logistics & Transportation',
    'E-commerce',
    'Other',
  ];

  static const List<String> _shipmentTypeOptions = [
    'Pallets',
    'Containers',
    'Oversized Loads',
    'Flatbed',
    'Refrigerated',
    'Dry Van',
    'LTL (Less Than Truckload)',
    'FTL (Full Truckload)',
    'Hazmat',
    'Intermodal',
    'Bulk',
    'Other',
  ];

  // Google Places API Key - using AppConstants

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Image storage
  dynamic _driversLicenseImage;
  dynamic _vehicleRegistrationImage;
  dynamic _nscImage;

  // Image URLs from saved data
  String? _driversLicenseUrl;
  String? _vehicleRegistrationUrl;
  String? _nscUrl;

  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    _loadSavedData();
  }

  @override
  void dispose() {
    _progressController1.dispose();
    _businessAddressController.dispose();
    _operatingProvincesController.dispose();
    _commercialInsuranceProviderController.dispose();
    _commercialPolicyNumberController.dispose();
    _commercialExpiryDateController.dispose();
    _commercialCoverageLimitController.dispose();
    _cargoInsuranceProviderController.dispose();
    _cargoPolicyNumberController.dispose();
    _cargoExpiryDateController.dispose();
    _cargoCoverageLimitController.dispose();
    _yearsOfExperienceController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier != null) {
        final savedData = await FirebaseService.getCarrierDashboardResponse(
          carrier.uid,
          'dashboard_2_business_info',
        );

        if (savedData != null) {
          setState(() {
            _businessAddressController.text =
                savedData['businessAddress'] ?? '';
            _operatingProvincesController.text =
                savedData['operatingProvinces'] ?? '';
            _selectedIndustryTypes = List<String>.from(
              savedData['industryType'] ?? [],
            );
            _selectedShipmentTypes = List<String>.from(
              savedData['shipmentType'] ?? [],
            );
            _commercialInsuranceProviderController.text =
                savedData['commercialInsuranceProvider'] ?? '';
            _commercialPolicyNumberController.text =
                savedData['commercialPolicyNumber'] ?? '';
            _commercialExpiryDateController.text =
                savedData['commercialExpiryDate'] ?? '';
            _commercialCoverageLimitController.text =
                savedData['commercialCoverageLimit'] ?? '';
            _cargoInsuranceProviderController.text =
                savedData['cargoInsuranceProvider'] ?? '';
            _cargoPolicyNumberController.text =
                savedData['cargoPolicyNumber'] ?? '';
            _cargoExpiryDateController.text =
                savedData['cargoExpiryDate'] ?? '';
            _cargoCoverageLimitController.text =
                savedData['cargoCoverageLimit'] ?? '';
            _yearsOfExperienceController.text =
                savedData['yearsOfExperience'] ?? '';
            _agreeToTerms = savedData['agreeToTerms'] ?? false;

            // Store image URLs for restoration
            _driversLicenseUrl = savedData['driversLicenseUrl'];
            _vehicleRegistrationUrl = savedData['vehicleRegistrationUrl'];
            _nscUrl = savedData['nscUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading saved data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;

    // ======== Responsive rules ========
    final bool isWide = screenW >= 900;

    const topPanelColor = Color(0xFF064232);
    const bottomNavHeight = 100.0;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFEF6),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ======== Top section ========
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: topPanelColor,
                  image: isWide
                      ? null
                      : const DecorationImage(
                          image: AssetImage('assets/top_leather.png'),
                          fit: BoxFit.cover,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: const Text(
                            'Please answer the fields below',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 2.0,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9E9E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _progressController1,
                            builder: (context, child) {
                              return Container(
                                height: 6,
                                width: 153.0 * _progressController1.value,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCA4D),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ======== Form fields ========
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 100.0 : 40.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      GooglePlacesAutocomplete(
                        controller: _businessAddressController,
                        hintText: "Business Address",
                        icon: Icons.location_on_outlined,
                        apiKey: AppConstants.googleApiKey,
                      ),
                      const SizedBox(height: 25),
                      CanadianProvincesAutocomplete(
                        controller: _operatingProvincesController,
                        hintText: "Operating Province(s)",
                        icon: Icons.flag_outlined,
                      ),
                      const SizedBox(height: 25),
                      MultiSelectField(
                        hintText: "Industry Type",
                        icon: Icons.business_center_outlined,
                        subtext: "(manufacturing, retail, agriculture etc.)",
                        selectedItems: _selectedIndustryTypes,
                        title: "Select Industry Type(s)",
                        options: _industryTypeOptions,
                        onSelectionChanged: (List<String> selected) {
                          setState(() {
                            _selectedIndustryTypes = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 25),
                      MultiSelectField(
                        hintText: "Frequent shipment type",
                        icon: Icons.local_shipping_outlined,
                        subtext: "(pallets, containers, oversized loads, etc.)",
                        selectedItems: _selectedShipmentTypes,
                        title: "Select Shipment Type(s)",
                        options: _shipmentTypeOptions,
                        onSelectionChanged: (List<String> selected) {
                          setState(() {
                            _selectedShipmentTypes = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Required Carrier\'s Documents *',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Color(0xFFFF5454),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Upload clear images (PDF/JPEG/PNG only)',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Color(0xFFA8A8A2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUploadField(
                        context: context,
                        text: "Drivers License (Front & Back) *",
                        image: _driversLicenseImage,
                        imageUrl: _driversLicenseUrl,
                        onTap: () => _pickImage('drivers_license'),
                      ),
                      const SizedBox(height: 25),
                      _buildUploadField(
                        context: context,
                        text: "Vehicle Registration *",
                        image: _vehicleRegistrationImage,
                        imageUrl: _vehicleRegistrationUrl,
                        onTap: () => _pickImage('vehicle_registration'),
                      ),
                      const SizedBox(height: 25),
                      _buildUploadField(
                        context: context,
                        text: "NSC (National Safety Code) *",
                        image: _nscImage,
                        imageUrl: _nscUrl,
                        onTap: () => _pickImage('nsc'),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Certificate of Commercial Auto-liability Insurance',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'For safety and compliance, all Re-Miles carriers must provide documentation of valid insurance coverage. This protects your freight and helps us maintain a trusted shipping network.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF7D8AB0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextInputField(
                        context: context,
                        hintText: "Insurance provider",
                        icon: Icons.security_outlined,
                        controller: _commercialInsuranceProviderController,
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Policy Number",
                        icon: Icons.numbers_outlined,
                        controller: _commercialPolicyNumberController,
                      ),
                      const SizedBox(height: 25),
                      _buildDatePickerField(
                        context: context,
                        hintText: "Expiry Date",
                        icon: Icons.calendar_today_outlined,
                        controller: _commercialExpiryDateController,
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Coverage Limit",
                        icon: Icons.attach_money_outlined,
                        controller: _commercialCoverageLimitController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Cargo Insurance (Optional)',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextInputField(
                        context: context,
                        hintText: "Insurance provider",
                        icon: Icons.security_outlined,
                        controller: _cargoInsuranceProviderController,
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Policy Number",
                        icon: Icons.numbers_outlined,
                        controller: _cargoPolicyNumberController,
                      ),
                      const SizedBox(height: 25),
                      _buildDatePickerField(
                        context: context,
                        hintText: "Expiry Date",
                        icon: Icons.calendar_today_outlined,
                        controller: _cargoExpiryDateController,
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Coverage Limit",
                        icon: Icons.attach_money_outlined,
                        controller: _cargoCoverageLimitController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Number of years of experience",
                        icon: Icons.work_outline,
                        controller: _yearsOfExperienceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: Container(
                              width: 28,
                              height: 29,
                              decoration: BoxDecoration(
                                color: _agreeToTerms
                                    ? const Color(0xFF4B744F)
                                    : const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.25),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _agreeToTerms
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'I confirm that my business maintains valid insurance coverage and that all uploaded documents are true and accurate.',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: Color(0xFFFF1313),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _saving ? null : () => _handleNext(),
                          child: Container(
                            width: 110,
                            height: 55,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/signup_button.png'),
                                fit: BoxFit.fill,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(24.5),
                              ),
                            ),
                            child: Align(
                              alignment: const Alignment(0, -0.2),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      "Next",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Color.fromRGBO(0, 0, 0, 0.3),
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // space above bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ======== Bottom Navigation ========
      bottomNavigationBar: Container(
        height: bottomNavHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF064232),
          image: isWide
              ? null
              : const DecorationImage(
                  image: AssetImage('assets/nav_leather.png'),
                  fit: BoxFit.cover,
                ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(65),
            topRight: Radius.circular(65),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFFFFBDF),
            unselectedItemColor: const Color(0xFFFFFBDF).withOpacity(0.6),
            selectedLabelStyle: const TextStyle(fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 26),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart, size: 29),
                label: 'Manage Loads',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront, size: 30.82),
                label: 'Marketplace',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 31.37),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz, size: 25),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== Methods ========

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (imageType) {
            case 'drivers_license':
              _driversLicenseImage = image;
              _driversLicenseUrl = null; // Clear URL when new image is selected
              break;
            case 'vehicle_registration':
              _vehicleRegistrationImage = image;
              _vehicleRegistrationUrl = null;
              break;
            case 'nsc':
              _nscImage = image;
              _nscUrl = null;
              break;
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error picking image';

      // Handle specific permission errors
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('permission')) {
        errorMessage =
            'Permission denied. Please allow access to photos in app settings.';
      } else if (e.toString().contains('User cancelled')) {
        // User cancelled, don't show error
        return;
      } else {
        errorMessage = 'Error picking image: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleNext() async {
    // Validate required fields
    if (_businessAddressController.text.trim().isEmpty ||
        _operatingProvincesController.text.trim().isEmpty ||
        _selectedIndustryTypes.isEmpty ||
        _selectedShipmentTypes.isEmpty ||
        _commercialInsuranceProviderController.text.trim().isEmpty ||
        _commercialPolicyNumberController.text.trim().isEmpty ||
        _commercialExpiryDateController.text.trim().isEmpty ||
        _commercialCoverageLimitController.text.trim().isEmpty ||
        _yearsOfExperienceController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please fill in all required fields.');
      return;
    }

    // Validate required images
    if ((_driversLicenseImage == null && _driversLicenseUrl == null) ||
        (_vehicleRegistrationImage == null &&
            _vehicleRegistrationUrl == null) ||
        (_nscImage == null && _nscUrl == null)) {
      _showAlertDialog(context, 'Please upload all required documents.');
      return;
    }

    if (!_agreeToTerms) {
      _showAlertDialog(context, 'Please agree to the terms and conditions.');
      return;
    }

    setState(() => _saving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier != null) {
        // Upload images first (only if new images were selected)
        String? driversLicenseUrl = _driversLicenseUrl;
        if (_driversLicenseImage != null) {
          driversLicenseUrl = await FirebaseService.uploadCarrierDocument(
            carrier.uid,
            'drivers_license',
            _driversLicenseImage!,
          );
          if (driversLicenseUrl == null) {
            throw Exception('Failed to upload drivers license');
          }
        }

        String? vehicleRegistrationUrl = _vehicleRegistrationUrl;
        if (_vehicleRegistrationImage != null) {
          vehicleRegistrationUrl = await FirebaseService.uploadCarrierDocument(
            carrier.uid,
            'vehicle_registration',
            _vehicleRegistrationImage!,
          );
          if (vehicleRegistrationUrl == null) {
            throw Exception('Failed to upload vehicle registration');
          }
        }

        String? nscUrl = _nscUrl;
        if (_nscImage != null) {
          nscUrl = await FirebaseService.uploadCarrierDocument(
            carrier.uid,
            'nsc',
            _nscImage!,
          );
          if (nscUrl == null) {
            throw Exception('Failed to upload NSC');
          }
        }

        final response = {
          'businessAddress': _businessAddressController.text.trim(),
          'operatingProvinces': _operatingProvincesController.text.trim(),
          'industryType': _selectedIndustryTypes,
          'shipmentType': _selectedShipmentTypes,
          'driversLicenseUrl': driversLicenseUrl,
          'vehicleRegistrationUrl': vehicleRegistrationUrl,
          'nscUrl': nscUrl,
          'commercialInsuranceProvider': _commercialInsuranceProviderController
              .text
              .trim(),
          'commercialPolicyNumber': _commercialPolicyNumberController.text
              .trim(),
          'commercialExpiryDate': _commercialExpiryDateController.text.trim(),
          'commercialCoverageLimit': _commercialCoverageLimitController.text
              .trim(),
          'cargoInsuranceProvider':
              _cargoInsuranceProviderController.text.trim().isEmpty
              ? null
              : _cargoInsuranceProviderController.text.trim(),
          'cargoPolicyNumber': _cargoPolicyNumberController.text.trim().isEmpty
              ? null
              : _cargoPolicyNumberController.text.trim(),
          'cargoExpiryDate': _cargoExpiryDateController.text.trim().isEmpty
              ? null
              : _cargoExpiryDateController.text.trim(),
          'cargoCoverageLimit':
              _cargoCoverageLimitController.text.trim().isEmpty
              ? null
              : _cargoCoverageLimitController.text.trim(),
          'yearsOfExperience': _yearsOfExperienceController.text.trim(),
          'agreeToTerms': _agreeToTerms,
          'timestamp': DateTime.now().toIso8601String(),
        };

        await FirebaseService.saveCarrierDashboardResponse(
          carrier.uid,
          'dashboard_2_business_info',
          response,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'Network timeout. Please check your internet connection.',
            );
          },
        );

        print('Carrier Dashboard 2 response saved successfully');
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CarrierDashboard3()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ======== Widgets ========

  Widget _buildTextInputField({
    required BuildContext context,
    required String hintText,
    required IconData icon,
    String? subtext,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 49,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(108, 167, 138, 0.5),
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: const Color.fromRGBO(0, 0, 0, 0.45),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(0, 0, 0, 0.45),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (subtext != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 15.0),
            child: Text(
              subtext,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(0, 0, 0, 0.34),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadField({
    required BuildContext context,
    required String text,
    dynamic image,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    final hasImage = image != null || imageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: Color.fromRGBO(25, 85, 41, 0.65),
                  blurRadius: 10.5,
                  spreadRadius: -1,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: hasImage
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Image Selected',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
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
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
      child: Container(
        width: double.infinity,
        height: 49,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(108, 167, 138, 0.5),
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color.fromRGBO(0, 0, 0, 0.45)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.text.isEmpty ? hintText : controller.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: controller.text.isEmpty
                        ? const Color.fromRGBO(0, 0, 0, 0.45)
                        : const Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
