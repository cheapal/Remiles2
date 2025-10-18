import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';

class ShipperDashboardPostLoad extends StatefulWidget {
  const ShipperDashboardPostLoad({super.key});

  @override
  State<ShipperDashboardPostLoad> createState() => _ShipperDashboardPostLoadState();
}

class _ShipperDashboardPostLoadState extends State<ShipperDashboardPostLoad> with TickerProviderStateMixin {
  late AnimationController _progressController1;
  
  // Form controllers
  final TextEditingController _originAddressController = TextEditingController();
  final TextEditingController _destinationAddressController = TextEditingController();
  final TextEditingController _loadTypeController = TextEditingController();
  final TextEditingController _loadSensitivityController = TextEditingController();
  final TextEditingController _loadDescriptionController = TextEditingController();
  final TextEditingController _declaredValueController = TextEditingController();
  final TextEditingController _pickupDateTimeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _deliveryWindowController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _equipmentNeededController = TextEditingController();
  final TextEditingController _quoteBudgetController = TextEditingController();
  
  // State variables
  bool _isPosting = false;
  bool _isSavingDraft = false;
  File? _additionalDocument;
  final ImagePicker _picker = ImagePicker();

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
    _quoteBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;
    const topPanelColor = Color(0xFF386544);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: topPanelColor,
        elevation: 0,
        toolbarHeight: 60,
        title:Text('Post Load',
        ),
      ),
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Form fields
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? 100.0 : 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        const Text(
                          'Post a New Load',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 32,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset('assets/yellow_trolly.png', width: 30, height: 30),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Origin Address", _originAddressController)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Destination Address", _destinationAddressController)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Load Type", _loadTypeController)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Load Sensitivity", _loadSensitivityController)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildTextArea(context, "Please Provide a Specific Load Description", _loadDescriptionController),
                    const SizedBox(height: 25),
                    _buildInputField(context, "Declared Value (For Insurance) (CAD)", _declaredValueController),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Pick Up Date/Time", _pickupDateTimeController)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Weight Kg / lbs", _weightController)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Delivery Window", _deliveryWindowController)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Dimensions (Optional)", _dimensionsController)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildInputField(context, "Equipment Needed (Optional)", _equipmentNeededController),
                    const SizedBox(height: 25),
                    _buildInputField(context, "Quote/Budget", _quoteBudgetController),
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
                          "Save As Draft",
                          const Color(0xFF195529),
                          Colors.white,
                              () => _saveAsDraft(),
                          width: 110.45,
                          height: 42.55,
                        ),
                        const SizedBox(width: 15),
                        _buildActionButton(
                          "Post",
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
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea(BuildContext context, String hintText, TextEditingController controller) {
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
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadField(BuildContext context, String text, {VoidCallback? onTap}) {
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
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
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
          _additionalDocument = File(document.path);
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
        
        await FirebaseService.saveShipperLoad(
          shipper.uid,
          loadData,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load saved as draft successfully'),
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
        
        // Upload document if provided
        if (_additionalDocument != null) {
          final documentUrl = await FirebaseService.uploadImage(
            shipper.uid,
            'load_documents_${DateTime.now().millisecondsSinceEpoch}',
            _additionalDocument!,
          );
          if (documentUrl != null) {
            loadData['additionalDocumentUrl'] = documentUrl;
          }
        }
        
        await FirebaseService.saveShipperLoad(
          shipper.uid,
          loadData,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load posted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Clear form
          _clearForm();
          
          // Navigate back or to a success screen
          Navigator.of(context).pop();
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
    final hasContent = _originAddressController.text.trim().isNotEmpty ||
        _destinationAddressController.text.trim().isNotEmpty ||
        _loadTypeController.text.trim().isNotEmpty ||
        _loadSensitivityController.text.trim().isNotEmpty ||
        _loadDescriptionController.text.trim().isNotEmpty ||
        _declaredValueController.text.trim().isNotEmpty ||
        _pickupDateTimeController.text.trim().isNotEmpty ||
        _weightController.text.trim().isNotEmpty ||
        _deliveryWindowController.text.trim().isNotEmpty ||
        _dimensionsController.text.trim().isNotEmpty ||
        _equipmentNeededController.text.trim().isNotEmpty ||
        _quoteBudgetController.text.trim().isNotEmpty ||
        _additionalDocument != null;
    
    if (!hasContent) {
      _showAlertDialog(context, 'Please fill in at least one field before saving as draft.');
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
      _showAlertDialog(context, 'Please enter load type.');
      return false;
    }
    
    if (_loadSensitivityController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter load sensitivity.');
      return false;
    }
    
    if (_loadDescriptionController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please provide a load description.');
      return false;
    }
    
    if (_declaredValueController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter declared value.');
      return false;
    }
    
    if (_pickupDateTimeController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter pickup date/time.');
      return false;
    }
    
    if (_weightController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter weight.');
      return false;
    }
    
    if (_deliveryWindowController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter delivery window.');
      return false;
    }
    
    if (_quoteBudgetController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter quote/budget.');
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> _buildLoadData({required bool isDraft}) {
    return {
      'originAddress': _originAddressController.text.trim(),
      'destinationAddress': _destinationAddressController.text.trim(),
      'loadType': _loadTypeController.text.trim(),
      'loadSensitivity': _loadSensitivityController.text.trim(),
      'loadDescription': _loadDescriptionController.text.trim(),
      'declaredValue': _declaredValueController.text.trim(),
      'pickupDateTime': _pickupDateTimeController.text.trim(),
      'weight': _weightController.text.trim(),
      'deliveryWindow': _deliveryWindowController.text.trim(),
      'dimensions': _dimensionsController.text.trim(),
      'equipmentNeeded': _equipmentNeededController.text.trim(),
      'quoteBudget': _quoteBudgetController.text.trim(),
      'isDraft': isDraft,
      'status': isDraft ? 'draft' : 'active',
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
    _quoteBudgetController.clear();
    setState(() {
      _additionalDocument = null;
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
