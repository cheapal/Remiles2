import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/firebase_service.dart';
import '../../../models/product_listing.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

// Helper class to represent images (either existing URL or new file)
class _ImageItem {
  final String? url;
  final File? file;
  final bool isExisting;
  
  _ImageItem({
    this.url,
    this.file,
    required this.isExisting,
  }) : assert(
    (url != null && file == null) || (url == null && file != null),
    'Either url or file must be provided, but not both',
  );
}

class ShipperCreateListing extends StatefulWidget {
  final ProductListing? listingToEdit;
  
  const ShipperCreateListing({super.key, this.listingToEdit});

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
  
  // Existing image/video URLs (from listing being edited)
  List<String> _existingImageUrls = [];
  String? _existingVideoUrl;

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

  bool get _isEditing => widget.listingToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.listingToEdit != null) {
      _prefillForm(widget.listingToEdit!);
    }
  }

  void _prefillForm(ProductListing listing) {
    _titleController.text = listing.title;
    _descriptionController.text = listing.description;
    _priceController.text = listing.price.toStringAsFixed(0);
    _selectedLocation = listing.location;
    _locationController.text = listing.location;
    selectedCondition = listing.condition;
    _existingImageUrls = List<String>.from(listing.imageUrls);
    _existingVideoUrl = listing.videoUrl;
  }

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
                    Text(
                      _isEditing ? 'Edit Listing' : 'Create Listing',
                      style: const TextStyle(
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
                
                // Images section
                if (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildImagesGrid(),
                      const SizedBox(height: 12),
                    ],
                  ),
                
                // Upload photo button
                if (_existingImageUrls.length + _selectedImages.length < 10)
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add More Photos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Video section
                Row(
                  children: [
                    Expanded(
                      child: _uploadCard(
                        Icons.videocam, 
                        "Product Video",
                        onTap: _pickVideo,
                        hasVideo: _selectedVideo != null || _existingVideoUrl != null,
                      ),
                    ),
                    if (_existingVideoUrl != null || _selectedVideo != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVideoPreview(),
                      ),
                    ],
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
                    // Publish/Update button
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
                            : Text(
                                _isEditing ? "Update" : "Publish",
                                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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

    // Validate images (must have images or existing images when editing)
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
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
        _showErrorSnackBar('Please log in to ${_isEditing ? 'update' : 'create'} a listing');
        return;
      }

      // Use existing listing ID if editing, otherwise create new one
      final listingId = _isEditing ? widget.listingToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString();
      
      // If editing, find and delete removed images
      if (_isEditing && widget.listingToEdit != null) {
        final originalImageUrls = widget.listingToEdit!.imageUrls;
        final removedImageUrls = originalImageUrls.where((url) => !_existingImageUrls.contains(url)).toList();
        
        // Delete removed images from Storage
        if (removedImageUrls.isNotEmpty) {
          try {
            await _deleteOldImages(removedImageUrls);
          } catch (e) {
            print('Warning: Failed to delete removed images: $e');
            // Continue anyway
          }
        }
      }
      
      // Upload new images if any selected
      List<String> imageUrls = List<String>.from(_existingImageUrls);
      if (_selectedImages.isNotEmpty) {
        try {
          final newImageUrls = await FirebaseService.uploadProductImages(
            user.uid,
            listingId,
            _selectedImages,
          );
          if (newImageUrls.isNotEmpty) {
            // Combine existing (kept) images with new uploaded images
            imageUrls = [..._existingImageUrls, ...newImageUrls];
          } else if (!_isEditing) {
            _showErrorSnackBar('Failed to upload images. Please try again.');
            return;
          }
        } catch (e) {
          _showErrorSnackBar('Failed to upload images: ${e.toString()}');
          return;
        }
      }

      // If editing and new video selected, delete old video
      if (_isEditing && _selectedVideo != null && _existingVideoUrl != null) {
        try {
          await _deleteOldVideo(_existingVideoUrl!);
        } catch (e) {
          print('Warning: Failed to delete old video: $e');
        }
      }

      // Upload new video if selected
      String? videoUrl = _existingVideoUrl;
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

      // Create or update product listing
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
        createdAt: _isEditing ? widget.listingToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firebase
      if (_isEditing) {
        await FirebaseService.updateProductListing(listingId, listing);
        _showSuccessSnackBar('Listing updated successfully!');
      } else {
        await FirebaseService.createProductListing(listing);
        _showSuccessSnackBar('Listing published successfully!');
      }
      
      // Close dialog
      Navigator.pop(context, true); // Return true to indicate success
      
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

  // Build images grid widget
  Widget _buildImagesGrid() {
    final allImages = <_ImageItem>[];
    
    // Add existing images
    for (var url in _existingImageUrls) {
      allImages.add(_ImageItem(url: url, isExisting: true));
    }
    
    // Add new selected images
    for (var file in _selectedImages) {
      allImages.add(_ImageItem(file: file, isExisting: false));
    }
    
    if (allImages.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No images selected',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        final item = allImages[index];
        return _buildImageItem(item, index);
      },
    );
  }
  
  Widget _buildImageItem(_ImageItem item, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.isExisting
              ? Image.network(
                  item.url!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                )
              : Image.file(
                  item.file!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index, item.isExisting),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Remove image (either existing or new)
  void _removeImage(int gridIndex, bool isExisting) {
    setState(() {
      if (isExisting) {
        // This is an existing image - find its index in _existingImageUrls
        // Grid index matches existing image index directly since existing images come first
        if (gridIndex < _existingImageUrls.length) {
          _existingImageUrls.removeAt(gridIndex);
        }
      } else {
        // This is a new image - find its index in _selectedImages
        int newIndex = gridIndex - _existingImageUrls.length;
        if (newIndex >= 0 && newIndex < _selectedImages.length) {
          _selectedImages.removeAt(newIndex);
        }
      }
    });
  }
  
  Widget _buildVideoPreview() {
    String? videoPath;
    bool isExisting = false;
    
    if (_selectedVideo != null) {
      videoPath = _selectedVideo!.path;
    } else if (_existingVideoUrl != null) {
      videoPath = _existingVideoUrl;
      isExisting = true;
    }
    
    if (videoPath == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 80,
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isExisting) {
                    _existingVideoUrl = null;
                  } else {
                    _selectedVideo = null;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delete old images from Storage
  Future<void> _deleteOldImages(List<String> imageUrls) async {
    for (final imageUrl in imageUrls) {
      try {
        await FirebaseService.deleteFileFromURL(imageUrl);
      } catch (e) {
        print('Failed to delete image: $imageUrl - $e');
        // Continue deleting other images even if one fails
      }
    }
  }

  // Delete old video from Storage
  Future<void> _deleteOldVideo(String videoUrl) async {
    try {
      await FirebaseService.deleteFileFromURL(videoUrl);
    } catch (e) {
      print('Failed to delete video: $videoUrl - $e');
    }
  }


  // Check if there are any unsaved changes
  bool _hasUnsavedChanges() {
    if (_isEditing && widget.listingToEdit != null) {
      final listing = widget.listingToEdit!;
      return _titleController.text.trim() != listing.title ||
             _descriptionController.text.trim() != listing.description ||
             _priceController.text.trim() != listing.price.toStringAsFixed(0) ||
             _selectedLocation != listing.location ||
             selectedCondition != listing.condition ||
             _selectedImages.isNotEmpty ||
             (_selectedVideo != null && _existingVideoUrl != listing.videoUrl);
    }
    
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
