import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/carrier_dashboard_main_page.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class CarrierDashboard3 extends StatefulWidget {
  const CarrierDashboard3({super.key});

  @override
  State<CarrierDashboard3> createState() => _CarrierDashboard3State();
}

class _CarrierDashboard3State extends State<CarrierDashboard3>
    with TickerProviderStateMixin {
  late AnimationController _progressController1;
  int _selectedTab = 0;
  bool _isGstRegistered = false;
  bool? _isCarbonFootprintInterested = null;
  bool _saving = false;
  bool _isLoading = true;

  // Form controller
  final TextEditingController _businessNumberController =
      TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Image storage
  dynamic _driversAbstractImage;
  dynamic _backgroundCheckImage;

  // Image URLs from saved data
  String? _driversAbstractUrl;
  String? _backgroundCheckUrl;

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
    _businessNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier != null) {
        final savedData = await FirebaseService.getCarrierDashboardResponse(
          carrier.uid,
          'dashboard_3_business_number',
        );

        if (savedData != null) {
          setState(() {
            _businessNumberController.text = savedData['businessNumber'] ?? '';
            _isGstRegistered = savedData['isGstRegistered'] ?? false;
            _isCarbonFootprintInterested =
                savedData['isCarbonFootprintInterested'];

            // Store image URLs for restoration
            _driversAbstractUrl = savedData['driversAbstractUrl'];
            _backgroundCheckUrl = savedData['backgroundCheckUrl'];
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

    // Responsive rules (same approach as your other fixed screen)
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
              // ===== Top section =====
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
                      // Keep text from overflowing on web
                      Center(
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
                            builder: (context, _) {
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

              // ===== Form fields =====
              Padding(
                // slightly wider inner padding on desktops
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 100.0 : 40.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      const Text(
                        'Optional Document Uploads',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUploadField(
                        context: context,
                        text: "Drivers Abstract (Optional)",
                        image: _driversAbstractImage,
                        imageUrl: _driversAbstractUrl,
                        onTap: () => _pickImage('drivers_abstract'),
                      ),
                      const SizedBox(height: 25),
                      _buildUploadField(
                        context: context,
                        text: "Background Check (Optional)",
                        image: _backgroundCheckImage,
                        imageUrl: _backgroundCheckUrl,
                        onTap: () => _pickImage('background_check'),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Business Number (BN) & GST/HST Registration',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextInputField(
                        context: context,
                        hintText: "What is your Business Number (BN)?",
                        subtext:
                            "15-digit CRA-assigned number used for tax purposes.",
                        controller: _businessNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Are you registered for GST/HST?',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildGstCheckboxes(),
                      const SizedBox(height: 35),
                      const Text(
                        'If your business is not GST/HST registered, you may not be able to reclaim tax credits. Please consult a tax advisor if unsure.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Our app offers a Carbon Footprint Tracking feature. Would you like to earn a \'Go Green\' badge by making eco-friendly choices on the platform?',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildCarbonFootPrintTracking(),

                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: _saving ? null : () => _handleSubmit(),
                          child: Container(
                            width: 314,
                            height: 57,
                            decoration: BoxDecoration(
                              color: const Color(0xFF195529),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF195529),
                                  blurRadius: 10.5,
                                  spreadRadius: -1,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      "Submit",
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
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

      // ===== Bottom Navigation (responsive padding & texture only on mobile) =====
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

  // ===== Methods =====

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
            case 'drivers_abstract':
              _driversAbstractImage = image;
              _driversAbstractUrl =
                  null; // Clear URL when new image is selected
              break;
            case 'background_check':
              _backgroundCheckImage = image;
              _backgroundCheckUrl = null;
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

  Future<void> _handleSubmit() async {
    // Validate required fields
    final businessNumber = _businessNumberController.text.trim();
    if (businessNumber.isEmpty) {
      _showAlertDialog(context, 'Please enter your Business Number (BN).');
      return;
    }

    if (businessNumber.length != 15) {
      _showAlertDialog(
        context,
        'Business Number (BN) must be exactly 15 digits.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier != null) {
        // Upload optional images if new ones were selected
        String? driversAbstractUrl = _driversAbstractUrl;
        if (_driversAbstractImage != null) {
          driversAbstractUrl = await FirebaseService.uploadCarrierDocument(
            carrier.uid,
            'drivers_abstract',
            _driversAbstractImage!,
          );
        }

        String? backgroundCheckUrl = _backgroundCheckUrl;
        if (_backgroundCheckImage != null) {
          backgroundCheckUrl = await FirebaseService.uploadCarrierDocument(
            carrier.uid,
            'background_check',
            _backgroundCheckImage!,
          );
        }

        final response = {
          'driversAbstractUrl': driversAbstractUrl,
          'backgroundCheckUrl': backgroundCheckUrl,
          'businessNumber': _businessNumberController.text.trim(),
          'isGstRegistered': _isGstRegistered,
          'isCarbonFootprintInterested':
              _isCarbonFootprintInterested, // Can be true, false, or null
          'carbonFootprintStatus': _isCarbonFootprintInterested == true
              ? 'interested'
              : _isCarbonFootprintInterested == false
              ? 'maybe_later'
              : 'remind_later',
          'timestamp': DateTime.now().toIso8601String(),
        };

        await FirebaseService.saveCarrierDashboardResponse(
          carrier.uid,
          'dashboard_3_business_number',
          response,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'Network timeout. Please check your internet connection.',
            );
          },
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const CarrierDashboardMainPage(),
        ),
        (route) => false, // Remove all previous routes
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

  // ===== Widgets =====

  Widget _buildTextInputField({
    required BuildContext context,
    required String hintText,
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
                color: Color.fromRGBO(0, 0, 0, 0.39),
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

  Widget _buildGstCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isGstRegistered = true;
            });
          },
          child: Row(
            children: [
              Container(
                width: 34,
                height: 36,
                decoration: BoxDecoration(
                  color: _isGstRegistered
                      ? const Color(0xFF497A57)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(134, 190, 163, 0.8),
                      blurRadius: 6.6,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isGstRegistered
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(width: 18),
              const Text(
                'Yes',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: () {
            setState(() {
              _isGstRegistered = false;
            });
          },
          child: Row(
            children: [
              Container(
                width: 34,
                height: 36,
                decoration: BoxDecoration(
                  color: !_isGstRegistered
                      ? const Color(0xFF497A57)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(134, 190, 163, 0.8),
                      blurRadius: 6.6,
                    ),
                  ],
                ),
                child: !_isGstRegistered
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(width: 18),
              const Text(
                'No',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarbonFootPrintTracking() {
    Widget buildOption({
      required bool isSelected,
      required String text,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF497A57)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(134, 190, 163, 0.8),
                      blurRadius: 6.6,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildOption(
          isSelected: _isCarbonFootprintInterested == true,
          text: 'Yes, I\'m interested in earning the Go Green badge',
          onTap: () {
            setState(() {
              _isCarbonFootprintInterested = true;
            });
          },
        ),
        buildOption(
          isSelected: _isCarbonFootprintInterested == false,
          text: 'Maybe later',
          onTap: () {
            setState(() {
              _isCarbonFootprintInterested = false;
            });
          },
        ),
        buildOption(
          isSelected: _isCarbonFootprintInterested == null,
          text: 'Remind me in the future',
          onTap: () {
            setState(() {
              _isCarbonFootprintInterested = null;
            });
          },
        ),
      ],
    );
  }
}
