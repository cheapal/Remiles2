import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../../../../core/firebase_service.dart';
import '../../../../../../models/academy_content.dart';
import '../../../../../../core/theme/colors.dart';
import '../../../../../../providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class AcademyContentForm extends StatefulWidget {
  final AcademyContent? contentToEdit;

  const AcademyContentForm({super.key, this.contentToEdit});

  @override
  State<AcademyContentForm> createState() => _AcademyContentFormState();
}

class _AcademyContentFormState extends State<AcademyContentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _thumbnailFile;
  String? _existingThumbnailUrl;
  File? _videoFile;
  String? _existingVideoUrl;
  File? _documentFile;
  String? _existingDocumentUrl;

  String _contentType = 'video';
  List<String> _tags = [];
  String? _selectedPlaylistId;
  String? _selectedPlaylistName;
  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = false;
  bool _isLoadingPlaylists = true;

  bool get _isEditing => widget.contentToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    if (_isEditing && widget.contentToEdit != null) {
      _prefillForm(widget.contentToEdit!);
    }
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await FirebaseService.getAcademyPlaylists();
      setState(() {
        _playlists = playlists;
        _isLoadingPlaylists = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  void _prefillForm(AcademyContent content) {
    _titleController.text = content.title;
    _descriptionController.text = content.description;
    _tags = List<String>.from(content.tags);
    _contentType = content.contentType;
    _existingThumbnailUrl = content.thumbnailUrl;
    _existingVideoUrl = content.videoUrl;
    _existingDocumentUrl = content.documentUrl;
    _selectedPlaylistId = content.playlistId;
    _selectedPlaylistName = content.playlistName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        final file = File(image.path);
        // Validate image size (5MB limit)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size must be less than 5MB')),
            );
          }
          return;
        }
        
        setState(() {
          _thumbnailFile = file;
          _existingThumbnailUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      // Use image_picker for better iOS compatibility
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final file = File(video.path);
        // Validate video size (50MB limit)
        final fileSize = await file.length();
        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video size must be less than 50MB')),
            );
          }
          return;
        }
        
        setState(() {
          _videoFile = file;
          _existingVideoUrl = null;
          _contentType = 'video';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        // Validate document size (10MB limit)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document size must be less than 10MB')),
            );
          }
          return;
        }
        
        setState(() {
          _documentFile = file;
          _existingDocumentUrl = null;
          _contentType = 'document';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: $e')),
        );
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_contentType == 'video' && _videoFile == null && _existingVideoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file')),
      );
      return;
    }

    if (_contentType == 'document' && _documentFile == null && _existingDocumentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showLoadingWithMessage('Saving content...');

      String? thumbnailUrl = _existingThumbnailUrl;
      String? videoUrl = _existingVideoUrl;
      String? documentUrl = _existingDocumentUrl;

      // Upload thumbnail if new
      if (_thumbnailFile != null) {
        thumbnailUrl = await FirebaseService.uploadAcademyThumbnail(_thumbnailFile!);
        if (thumbnailUrl == null) {
          throw Exception('Failed to upload thumbnail');
        }
      }

      // Upload video if new
      if (_videoFile != null) {
        videoUrl = await FirebaseService.uploadAcademyVideo(_videoFile!);
        if (videoUrl == null) {
          throw Exception('Failed to upload video');
        }
      }

      // Upload document if new
      if (_documentFile != null) {
        documentUrl = await FirebaseService.uploadAcademyDocument(_documentFile!);
        if (documentUrl == null) {
          throw Exception('Failed to upload document');
        }
      }

      final content = AcademyContent(
        id: _isEditing ? widget.contentToEdit!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        thumbnailUrl: thumbnailUrl,
        videoUrl: _contentType == 'video' ? videoUrl : null,
        documentUrl: _contentType == 'document' ? documentUrl : null,
        contentType: _contentType,
        tags: _tags,
        playlistId: _selectedPlaylistId,
        playlistName: _selectedPlaylistName,
        createdAt: _isEditing ? widget.contentToEdit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        order: _isEditing ? widget.contentToEdit!.order : 0,
      );

      await FirebaseService.saveAcademyContent(content);
      appStateProvider.showSuccess();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to save content');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Content' : 'Add New Content',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content Type Selection
                      Text(
                        'Content Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              'Video',
                              Icons.video_library,
                              'video',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeButton(
                              'Document',
                              Icons.description,
                              'document',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(color: primaryColor),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: primaryColor),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Thumbnail
                      Text(
                        'Thumbnail (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickThumbnail,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          child: _thumbnailFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _thumbnailFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _existingThumbnailUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _existingThumbnailUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildPlaceholder(Icons.image);
                                        },
                                      ),
                                    )
                                  : _buildPlaceholder(Icons.add_photo_alternate),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Video/Document Upload
                      if (_contentType == 'video') ...[
                        Text(
                          'Video File',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFileButton(
                          'Select Video',
                          Icons.video_file,
                          _videoFile != null || _existingVideoUrl != null,
                          _pickVideo,
                          _videoFile?.path ?? (_existingVideoUrl != null ? 'Video uploaded' : null),
                        ),
                      ] else ...[
                        Text(
                          'Document File',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFileButton(
                          'Select Document',
                          Icons.description,
                          _documentFile != null || _existingDocumentUrl != null,
                          _pickDocument,
                          _documentFile?.path.split('/').last ?? (_existingDocumentUrl != null ? 'Document uploaded' : null),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Tags
                      Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                hintText: 'Enter tag and press +',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onFieldSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addTag,
                            icon: Icon(Icons.add_circle, color: primaryColor, size: 32),
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removeTag(tag),
                              backgroundColor: yellowColor.withOpacity(0.3),
                              labelStyle: TextStyle(color: textColor),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Playlist Selection
                      Text(
                        'Playlist (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingPlaylists)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedPlaylistId,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
                            ),
                            ..._playlists.map((playlist) {
                              return DropdownMenuItem<String>(
                                value: playlist['id'],
                                child: Text(playlist['name'] ?? ''),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPlaylistId = value;
                              if (value != null) {
                                final playlist = _playlists.firstWhere((p) => p['id'] == value);
                                _selectedPlaylistName = playlist['name'];
                              } else {
                                _selectedPlaylistName = null;
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveContent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Content',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, String type) {
    final isSelected = _contentType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _contentType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primaryColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            'Tap to select',
            style: TextStyle(color: primaryColor, fontFamily: 'Roboto'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileButton(
    String label,
    IconData icon,
    bool hasFile,
    VoidCallback onTap,
    String? fileName,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? yellowColor.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  if (fileName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.upload_file, color: primaryColor),
          ],
        ),
      ),
    );
  }
}

