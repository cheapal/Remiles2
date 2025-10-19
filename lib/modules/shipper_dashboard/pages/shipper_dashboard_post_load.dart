import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';

class ShipperDashboardPostLoad extends StatefulWidget {
  final Map<String, dynamic>? editLoadData;
  
  const ShipperDashboardPostLoad({super.key, this.editLoadData});

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
  
  // DateTime variables
  DateTime? _pickupDateTime;
  DateTime? _deliveryWindowStart;
  DateTime? _deliveryWindowEnd;
  
  // For editing existing loads
  String? _previousDocumentUrl;
  String? _previousDocumentName;
  bool _isPreviousDocumentImage = false;

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
    _destinationAddressController.text = data['destinationAddress']?.toString() ?? '';
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
    
    // Parse delivery window
    if (data['deliveryWindowStart'] != null && data['deliveryWindowEnd'] != null) {
      try {
        _deliveryWindowStart = data['deliveryWindowStart'] is DateTime 
            ? data['deliveryWindowStart'] 
            : DateTime.parse(data['deliveryWindowStart'].toString());
        _deliveryWindowEnd = data['deliveryWindowEnd'] is DateTime 
            ? data['deliveryWindowEnd'] 
            : DateTime.parse(data['deliveryWindowEnd'].toString());
        _deliveryWindowController.text = _deliveryWindowStart != null && _deliveryWindowEnd != null
            ? '${_deliveryWindowStart!.day}/${_deliveryWindowStart!.month}/${_deliveryWindowStart!.year} - ${_deliveryWindowEnd!.day}/${_deliveryWindowEnd!.month}/${_deliveryWindowEnd!.year}'
            : '';
      } catch (e) {
        _deliveryWindowStart = null;
        _deliveryWindowEnd = null;
        _deliveryWindowController.text = data['deliveryWindow']?.toString() ?? '';
      }
    } else {
      _deliveryWindowController.text = data['deliveryWindow']?.toString() ?? '';
    }
    _dimensionsController.text = data['dimensions']?.toString() ?? '';
    _equipmentNeededController.text = data['equipmentNeeded']?.toString() ?? '';
    _quoteBudgetController.text = data['quoteBudget']?.toString() ?? '';
    
    // Handle additional document if it exists
    if (data['additionalDocument'] != null) {
      _previousDocumentUrl = data['additionalDocument'].toString();
      
      // Extract filename from URL (get the part after the last '/')
      final urlParts = _previousDocumentUrl!.split('/');
      _previousDocumentName = urlParts.isNotEmpty ? urlParts.last : 'Previous Document';
      
      // Check if it's an image based on file extension
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
      final urlLower = _previousDocumentUrl!.toLowerCase();
      
      // Check both endsWith and contains for more flexible detection
      _isPreviousDocumentImage = imageExtensions.any((ext) => 
        urlLower.endsWith(ext) || urlLower.contains(ext));
      
      // If we can't determine if it's an image, assume it might be and let the UI handle it
      if (!_isPreviousDocumentImage && (urlLower.contains('image') || urlLower.contains('photo'))) {
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
    _quoteBudgetController.dispose();
    super.dispose();
  }

  // Date/Time picker methods
  Future<void> _selectPickupDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _pickupDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _pickupDateTime != null 
            ? TimeOfDay.fromDateTime(_pickupDateTime!)
            : TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        setState(() {
          _pickupDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _pickupDateTimeController.text = '${_pickupDateTime!.day}/${_pickupDateTime!.month}/${_pickupDateTime!.year} ${_pickupDateTime!.hour.toString().padLeft(2, '0')}:${_pickupDateTime!.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  Future<void> _selectDeliveryWindow() async {
    // Select start date
    final DateTime? startDate = await showDatePicker(
      context: context,
      initialDate: _deliveryWindowStart ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (startDate != null) {
      // Select end date
      final DateTime? endDate = await showDatePicker(
        context: context,
        initialDate: _deliveryWindowEnd ?? startDate.add(const Duration(days: 1)),
        firstDate: startDate,
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      
      if (endDate != null) {
        setState(() {
          _deliveryWindowStart = startDate;
          _deliveryWindowEnd = endDate;
          _deliveryWindowController.text = '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
        });
      }
    }
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
        title: Text(
          widget.editLoadData != null ? 'Edit Load' : 'Post Load',
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
                        Expanded(child: _buildDateTimeField(context, "Pick Up Date/Time", _pickupDateTimeController, _selectPickupDateTime)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Weight Kg / lbs", _weightController)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildDateTimeField(context, "Delivery Window", _deliveryWindowController, _selectDeliveryWindow)),
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
                          widget.editLoadData != null ? "Update Draft" : "Save As Draft",
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
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ),
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
                      color: controller.text.isEmpty ? const Color(0xFF959595) : Colors.black,
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
                  : _previousDocumentUrl != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Show small image preview if it's an image
                            if (_isPreviousDocumentImage)
                              Container(
                                width: 32,
                                height: 32,
                                margin: EdgeInsets.only(right: 8),
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
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                              Icon(
                                Icons.description,
                                color: Colors.blue,
                                size: 24,
                              ),
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
              throw Exception('Network timeout. Please check your internet connection.');
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
          
          await FirebaseService.saveShipperLoad(
            shipper.uid,
            loadData,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Network timeout. Please check your internet connection.');
            },
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.editLoadData != null ? 'Load draft updated successfully!' : 'Load saved as draft successfully'),
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
              throw Exception('Network timeout. Please check your internet connection.');
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
          
          await FirebaseService.saveShipperLoad(
            shipper.uid,
            loadData,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Network timeout. Please check your internet connection.');
            },
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.editLoadData != null ? 'Load updated successfully!' : 'Load posted successfully!'),
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
    final hasContent = _originAddressController.text.trim().isNotEmpty ||
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
    
    if (_pickupDateTime == null) {
      _showAlertDialog(context, 'Please select pickup date/time.');
      return false;
    }
    
    if (_weightController.text.trim().isEmpty) {
      _showAlertDialog(context, 'Please enter weight.');
      return false;
    }
    
    if (_deliveryWindowStart == null || _deliveryWindowEnd == null) {
      _showAlertDialog(context, 'Please select delivery window.');
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
      'pickupDateTime': _pickupDateTime?.toIso8601String(),
      'weight': _weightController.text.trim(),
      'deliveryWindowStart': _deliveryWindowStart?.toIso8601String(),
      'deliveryWindowEnd': _deliveryWindowEnd?.toIso8601String(),
      'deliveryWindow': _deliveryWindowController.text.trim(), // Keep for backward compatibility
      'dimensions': _dimensionsController.text.trim(),
      'equipmentNeeded': _equipmentNeededController.text.trim(),
      'quoteBudget': _quoteBudgetController.text.trim(),
      'isDraft': isDraft,
      'status': isDraft ? 'draft' : 'active',
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
    _quoteBudgetController.clear();
    setState(() {
      _additionalDocument = null;
      _pickupDateTime = null;
      _deliveryWindowStart = null;
      _deliveryWindowEnd = null;
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
