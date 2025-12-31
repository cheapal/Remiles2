import 'package:remiles/modules/shipper_dashboard/pages/shipper_dashboard_3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';
import '../../../core/utils/google_places_autocomplete.dart';
import '../../../core/utils/canadian_provinces_autocomplete.dart';
import '../../../core/utils/multi_select_dialog.dart';
import '../../../core/constants/app_constants.dart';

class ShipperDashboard2 extends StatefulWidget {
  const ShipperDashboard2({super.key});

  @override
  State<ShipperDashboard2> createState() => _ShipperDashboard2State();
}

class _ShipperDashboard2State extends State<ShipperDashboard2>
    with TickerProviderStateMixin {
  bool _agreeToTerms = false;
  late AnimationController _progressController1;
  int _selectedTab = 0;
  bool _saving = false;
  
  // Form controllers
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _operatingProvincesController = TextEditingController();
  final TextEditingController _insuranceProviderController = TextEditingController();
  final TextEditingController _policyNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _coverageLimitController = TextEditingController();
  
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
  File? _businessRegistrationImage;
  File? _insuranceDocumentImage;
  File? _governmentIdImage;
  File? _proofOfAddressImage;

  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _progressController1.dispose();
    _businessAddressController.dispose();
    _operatingProvincesController.dispose();
    _insuranceProviderController.dispose();
    _policyNumberController.dispose();
    _expiryDateController.dispose();
    _coverageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;

    // ======== Responsive rules ========
    final bool isWide = screenW >= 900;

    const topPanelColor = Color(0xFF064232);
    const bottomNavHeight = 100.0;

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      // FIX: remove `const` from Center so its non-const children are allowed
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
                    horizontal: isWide ? 100.0 : 40.0),
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
                        'Required Business Documents *',
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
                        text:
                        "Business Registration (Articles of Incorporation or Sole Proprietor Certificate)",
                        image: _businessRegistrationImage,
                        onTap: () => _pickImage('business_registration'),
                      ),
                      const SizedBox(height: 25),
                      _buildUploadField(
                        context: context,
                        text:
                        "Upload Proof of Business Insurance (Commercial General Liability, Cargo Insurance, etc.)",
                        image: _insuranceDocumentImage,
                        onTap: () => _pickImage('insurance_document'),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'For safety and compliance, all Re-Miles shippers must provide documentation of valid insurance coverage. This protects your freight and helps us maintain a trusted shipping network.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF7D8AB0),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Insurance provider",
                        icon: Icons.security_outlined,
                        controller: _insuranceProviderController,
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Policy Number",
                        icon: Icons.numbers_outlined,
                        controller: _policyNumberController,
                      ),
                      const SizedBox(height: 25),
                      _buildDatePickerField(
                        context: context,
                        hintText: "Expiry Date",
                        icon: Icons.calendar_today_outlined,
                        controller: _expiryDateController,
                      ),
                      const SizedBox(height: 25),
                      _buildTextInputField(
                        context: context,
                        hintText: "Coverage Limit",
                        icon: Icons.attach_money_outlined,
                        controller: _coverageLimitController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildChecklistSection(),
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
                              '“I confirm that my business maintains valid insurance coverage and that all uploaded documents are true and accurate.”',
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
                      _buildUploadField(
                        context: context,
                        text:
                        "Government-Issued ID (for business owner or authorized user)",
                        image: _governmentIdImage,
                        onTap: () => _pickImage('government_id'),
                      ),
                      const SizedBox(height: 25),
                      _buildUploadField(
                        context: context,
                        text: "Proof of Address (e.g., Utility bill)",
                        image: _proofOfAddressImage,
                        onTap: () => _pickImage('proof_of_address'),
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
                              borderRadius:
                              BorderRadius.all(Radius.circular(24.5)),
                            ),
                            child: Align(
                              alignment: const Alignment(0, -0.2),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            case 'business_registration':
              _businessRegistrationImage = File(image.path);
              break;
            case 'insurance_document':
              _insuranceDocumentImage = File(image.path);
              break;
            case 'government_id':
              _governmentIdImage = File(image.path);
              break;
            case 'proof_of_address':
              _proofOfAddressImage = File(image.path);
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
        errorMessage = 'Permission denied. Please allow access to photos in app settings.';
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
        _insuranceProviderController.text.trim().isEmpty ||
        _policyNumberController.text.trim().isEmpty ||
        _expiryDateController.text.trim().isEmpty ||
        _coverageLimitController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please fill in all required fields.');
      return;
    }
    
    // Validate required images
    if (_businessRegistrationImage == null ||
        _insuranceDocumentImage == null ||
        _governmentIdImage == null ||
        _proofOfAddressImage == null) {
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
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        // Upload images first
        final businessRegistrationUrl = await FirebaseService.uploadImage(
          shipper.uid,
          'business_registration',
          _businessRegistrationImage!,
        );
        
        final insuranceDocumentUrl = await FirebaseService.uploadImage(
          shipper.uid,
          'insurance_document',
          _insuranceDocumentImage!,
        );
        
        final governmentIdUrl = await FirebaseService.uploadImage(
          shipper.uid,
          'government_id',
          _governmentIdImage!,
        );
        
        final proofOfAddressUrl = await FirebaseService.uploadImage(
          shipper.uid,
          'proof_of_address',
          _proofOfAddressImage!,
        );
        
        if (businessRegistrationUrl == null ||
            insuranceDocumentUrl == null ||
            governmentIdUrl == null ||
            proofOfAddressUrl == null) {
          throw Exception('Failed to upload one or more images');
        }
        
        final response = {
          'businessAddress': _businessAddressController.text.trim(),
          'operatingProvinces': _operatingProvincesController.text.trim(),
          'industryType': _selectedIndustryTypes,
          'shipmentType': _selectedShipmentTypes,
          'insuranceProvider': _insuranceProviderController.text.trim(),
          'policyNumber': _policyNumberController.text.trim(),
          'expiryDate': _expiryDateController.text.trim(),
          'coverageLimit': _coverageLimitController.text.trim(),
          'agreeToTerms': _agreeToTerms,
          'businessRegistrationImageUrl': businessRegistrationUrl,
          'insuranceDocumentImageUrl': insuranceDocumentUrl,
          'governmentIdImageUrl': governmentIdUrl,
          'proofOfAddressImageUrl': proofOfAddressUrl,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        await FirebaseService.saveShipperDashboardResponse(
          shipper.uid,
          'dashboard_2_business_info',
          response,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        print('Dashboard 2 response saved successfully');
      }
      
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShipperDashboard3()),
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
                Icon(icon, size: 24, color: const Color.fromRGBO(0, 0, 0, 0.45)),
                const SizedBox(width: 10),
                // FIX: TextField is not const; remove const from Expanded/TextField
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
    File? image,
    VoidCallback? onTap,
  }) {
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
              child: image != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                        SizedBox(width: 8),
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

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Accepted formats: PDF, PNG, JPG',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Minimum requirement: General liability coverage',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.only(left: 15.0),
          child: Text(
            '• Must name their business\n• Must show general liability or freight-specific coverage',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.black,
              fontStyle: FontStyle.italic,
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF4B744F),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                controller.text = DateFormat('yyyy-MM-dd').format(picked);
              });
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
        ),
      ],
    );
  }
}
