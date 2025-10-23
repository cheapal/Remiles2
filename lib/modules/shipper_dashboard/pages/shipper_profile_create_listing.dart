import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/firebase_service.dart';
import '../../../models/product_listing.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ShipperCreateListing extends StatefulWidget {
  const ShipperCreateListing({super.key});

  @override
  State<ShipperCreateListing> createState() => _ShipperCreateListingState();
}

class _ShipperCreateListingState extends State<ShipperCreateListing> {
  String selectedCondition = "New";
  bool _isLoading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  File? _selectedVideo;

  // Location picker
  String? _selectedLocation;
  final List<String> _locations = [
    'Vancouver, BC',
    'Toronto, ON',
    'Montreal, QC',
    'Calgary, AB',
    'Edmonton, AB',
    'Ottawa, ON',
    'Winnipeg, MB',
    'Quebec City, QC',
    'Hamilton, ON',
    'Kitchener, ON',
  ];

  final List<String> conditions = [
    "New",
    "Used - Like New",
    "Used - Good",
    "Used - Fair",
    "Refurbished",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleClose();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Header with close button
                Row(
                  children: [
                    const Text(
                      'Create Listing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _handleClose,
                      icon: const Icon(Icons.close, color: Colors.grey),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Row for photos & video
                Row(
                  children: [
                    Expanded(
                      child: _uploadCard(
                        Icons.camera_alt, 
                        "Product Photos",
                        onTap: _pickImages,
                        count: _selectedImages.length,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _uploadCard(
                        Icons.videocam, 
                        "Product Video",
                        onTap: _pickVideo,
                        hasVideo: _selectedVideo != null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                _inputField(
                  "Name of Product",
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Product name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Product name must be at least 3 characters';
                    }
                    if (value.trim().length > 100) {
                      return 'Product name must be less than 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                _inputField(
                  "Product Description", 
                  maxLines: 3,
                  controller: _descriptionController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Product description is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    if (value.trim().length > 500) {
                      return 'Description must be less than 500 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Price
                _inputField(
                  "Price", 
                  keyboard: TextInputType.number,
                  controller: _priceController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null) {
                      return 'Please enter a valid number';
                    }
                    if (price <= 0) {
                      return 'Price must be greater than 0';
                    }
                    if (price > 1000000) {
                      return 'Price must be less than \$1,000,000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Location
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a location';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Select Location",
                    suffixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                  items: _locations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue;
                      _locationController.text = newValue ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Condition
                const Text(
                  "Condition",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: conditions.map((condition) {
                    final isSelected = selectedCondition == condition;
                    return ChoiceChip(
                      label: Text(condition),
                      selected: isSelected,
                      selectedColor: Colors.green.shade700,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCondition = condition;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Action buttons row
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        onPressed: _handleClose,
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Publish button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _publishListing,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Publish",
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _uploadCard(
    IconData icon, 
    String label, {
    VoidCallback? onTap,
    int count = 0,
    bool hasVideo = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (count > 0 || hasVideo) ? Colors.green.shade700 : Colors.green.shade100, 
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              size: 36, 
              color: (count > 0 || hasVideo) ? Colors.green.shade700 : Colors.black87,
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: (count > 0 || hasVideo) ? Colors.green.shade700 : Colors.black87,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$count selected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (hasVideo) ...[
              const SizedBox(height: 4),
              Text(
                'Video selected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String hint, {
    int maxLines = 1, 
    TextInputType keyboard = TextInputType.text,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  // Image picker methods
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        // Validate image count
        if (images.length > 10) {
          _showErrorSnackBar('You can select maximum 10 images');
          return;
        }

        // Validate image sizes
        for (final image in images) {
          final file = File(image.path);
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) { // 5MB limit
            _showErrorSnackBar('Image size must be less than 5MB');
            return;
          }
        }

        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick images. Please try again.');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        // Validate video size
        final file = File(video.path);
        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) { // 50MB limit
          _showErrorSnackBar('Video size must be less than 50MB');
          return;
        }

        setState(() {
          _selectedVideo = file;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick video. Please try again.');
    }
  }

  // Form submission
  Future<void> _publishListing() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    // Validate images
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please select at least one product photo');
      return;
    }

    // Validate price
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showErrorSnackBar('Please enter a valid price');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showErrorSnackBar('Please enter a valid price greater than 0');
      return;
    }

    // Validate location
    if (_selectedLocation == null || _selectedLocation!.isEmpty) {
      _showErrorSnackBar('Please select a location');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        _showErrorSnackBar('Please log in to create a listing');
        return;
      }

      // Create listing ID
      final listingId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload images with progress indication
      List<String> imageUrls = [];
      try {
        imageUrls = await FirebaseService.uploadProductImages(
          user.uid,
          listingId,
          _selectedImages,
        );
        if (imageUrls.isEmpty) {
          _showErrorSnackBar('Failed to upload images. Please try again.');
          return;
        }
      } catch (e) {
        _showErrorSnackBar('Failed to upload images: ${e.toString()}');
        return;
      }

      // Upload video if selected
      String? videoUrl;
      if (_selectedVideo != null) {
        try {
          videoUrl = await FirebaseService.uploadProductVideo(
            user.uid,
            listingId,
            _selectedVideo!,
          );
        } catch (e) {
          _showErrorSnackBar('Failed to upload video: ${e.toString()}');
          return;
        }
      }

      // Create product listing
      final listing = ProductListing(
        id: listingId,
        shipperUid: user.uid,
        shipperName: user.displayName ?? 'Unknown',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        condition: selectedCondition,
        location: _selectedLocation ?? _locationController.text.trim(),
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      await FirebaseService.createProductListing(listing);

      // Show success message
      _showSuccessSnackBar('Listing published successfully!');
      
      // Close dialog
      Navigator.pop(context);
      
    } catch (e) {
      String errorMessage = 'Failed to publish listing';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please try again.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage error. Please try again with smaller files.';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Check if there are any unsaved changes
  bool _hasUnsavedChanges() {
    return _titleController.text.isNotEmpty ||
           _descriptionController.text.isNotEmpty ||
           _priceController.text.isNotEmpty ||
           _locationController.text.isNotEmpty ||
           _selectedImages.isNotEmpty ||
           _selectedVideo != null;
  }

  // Handle close button press
  Future<void> _handleClose() async {
    if (_hasUnsavedChanges()) {
      final shouldClose = await _showDiscardChangesDialog();
      if (shouldClose == true) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  // Show confirmation dialog for discarding changes
  Future<bool?> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }
}
