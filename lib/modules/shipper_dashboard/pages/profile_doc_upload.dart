import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:Remiles/models/user_model.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/providers/app_state_provider.dart';

class ProfileDocUpload extends StatefulWidget {
  const ProfileDocUpload({super.key});

  @override
  State<ProfileDocUpload> createState() => _ProfileDocUploadState();
}

class _ProfileDocUploadState extends State<ProfileDocUpload> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  Map<String, DocumentInfo> _documents = {};
  
  // Document definitions for carriers
  static const List<DocumentInfo> _carrierDocuments = [
    DocumentInfo(
      key: 'driversLicenseUrl',
      storageKey: 'drivers_license',
      displayName: 'Drivers License (Front & Back)',
      isRequired: true,
      screenKey: 'dashboard_2_business_info',
    ),
    DocumentInfo(
      key: 'vehicleRegistrationUrl',
      storageKey: 'vehicle_registration',
      displayName: 'Vehicle Registration',
      isRequired: true,
      screenKey: 'dashboard_2_business_info',
    ),
    DocumentInfo(
      key: 'nscUrl',
      storageKey: 'nsc',
      displayName: 'NSC (National Safety Code)',
      isRequired: true,
      screenKey: 'dashboard_2_business_info',
    ),
    DocumentInfo(
      key: 'proofOfInsuranceUrl',
      storageKey: 'proof_of_insurance',
      displayName: 'Proof of Insurance',
      isRequired: true,
      screenKey: 'dashboard_2_business_info',
    ),
    DocumentInfo(
      key: 'driversAbstractUrl',
      storageKey: 'drivers_abstract',
      displayName: 'Drivers Abstract',
      isRequired: false,
      screenKey: 'dashboard_3_business_number',
    ),
    DocumentInfo(
      key: 'backgroundCheckUrl',
      storageKey: 'background_check',
      displayName: 'Background Check',
      isRequired: false,
      screenKey: 'dashboard_3_business_number',
    ),
  ];

  // Document definitions for shippers
  static const List<DocumentInfo> _shipperDocuments = [
    DocumentInfo(
      key: 'businessRegistrationUrl',
      storageKey: 'business_registration',
      displayName: 'Business Registration',
      isRequired: true,
      screenKey: 'dashboard_2_business_info',
    ),
    DocumentInfo(
      key: 'insuranceDocumentUrl',
      storageKey: 'insurance_document',
      displayName: 'Cargo Insurance',
      isRequired: true,
      screenKey: 'dashboard_2_business_info',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userRole = authProvider.userRole;
      
      if (userRole == UserRole.carrier) {
        final carrier = authProvider.carrierUser;
        if (carrier != null) {
          // Load dashboard 2 documents
          final dashboard2 = await FirebaseService.getCarrierDashboardResponse(
            carrier.uid,
            'dashboard_2_business_info',
          );
          
          // Load dashboard 3 documents
          final dashboard3 = await FirebaseService.getCarrierDashboardResponse(
            carrier.uid,
            'dashboard_3_business_number',
          );
          
          final Map<String, DocumentInfo> docs = {};
          for (var docInfo in _carrierDocuments) {
            String? url;
            if (docInfo.screenKey == 'dashboard_2_business_info' && dashboard2 != null) {
              url = dashboard2[docInfo.key];
            } else if (docInfo.screenKey == 'dashboard_3_business_number' && dashboard3 != null) {
              url = dashboard3[docInfo.key];
            }
            
            docs[docInfo.key] = DocumentInfo(
              key: docInfo.key,
              storageKey: docInfo.storageKey,
              displayName: docInfo.displayName,
              isRequired: docInfo.isRequired,
              screenKey: docInfo.screenKey,
              url: url,
            );
          }
          
          setState(() {
            _documents = docs;
            _isLoading = false;
          });
        }
      } else if (userRole == UserRole.shipper) {
        final shipper = authProvider.shipperUser;
        if (shipper != null) {
          // Load dashboard 2 documents
          final dashboard2 = await FirebaseService.getShipperDashboardResponse(
            shipper.uid,
            'dashboard_2_business_info',
          );
          
          final Map<String, DocumentInfo> docs = {};
          for (var docInfo in _shipperDocuments) {
            String? url;
            if (dashboard2 != null) {
              url = dashboard2[docInfo.key];
            }
            
            docs[docInfo.key] = DocumentInfo(
              key: docInfo.key,
              storageKey: docInfo.storageKey,
              displayName: docInfo.displayName,
              isRequired: docInfo.isRequired,
              screenKey: docInfo.screenKey,
              url: url,
            );
          }
          
          setState(() {
            _documents = docs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument(DocumentInfo docInfo) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (image == null) return;

      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final userRole = authProvider.userRole;

      appStateProvider.showLoadingWithMessage('Uploading document...');

      String? newUrl;
      if (userRole == UserRole.carrier) {
        final carrier = authProvider.carrierUser;
        if (carrier != null) {
          newUrl = await FirebaseService.uploadCarrierDocument(
            carrier.uid,
            docInfo.storageKey,
            File(image.path),
          );
        }
      } else if (userRole == UserRole.shipper) {
        final shipper = authProvider.shipperUser;
        if (shipper != null) {
          newUrl = await FirebaseService.uploadImage(
            shipper.uid,
            docInfo.storageKey,
            File(image.path),
          );
        }
      }

      if (newUrl == null) {
        throw Exception('Failed to upload document');
      }

      // Delete old file if exists
      if (docInfo.url != null && docInfo.url!.isNotEmpty) {
        try {
          await FirebaseService.deleteFileFromURL(docInfo.url!);
        } catch (e) {
          print('Error deleting old file: $e');
          // Continue even if deletion fails
        }
      }

      // Update dashboard response
      if (userRole == UserRole.carrier) {
        final carrier = authProvider.carrierUser;
        if (carrier != null) {
          final currentData = await FirebaseService.getCarrierDashboardResponse(
            carrier.uid,
            docInfo.screenKey,
          );
          
          final updatedData = {
            ...?currentData,
            docInfo.key: newUrl,
            'timestamp': DateTime.now().toIso8601String(),
          };
          
          await FirebaseService.saveCarrierDashboardResponse(
            carrier.uid,
            docInfo.screenKey,
            updatedData,
          );
        }
      } else if (userRole == UserRole.shipper) {
        final shipper = authProvider.shipperUser;
        if (shipper != null) {
          final currentData = await FirebaseService.getShipperDashboardResponse(
            shipper.uid,
            docInfo.screenKey,
          );
          
          final updatedData = {
            ...?currentData,
            docInfo.key: newUrl,
            'timestamp': DateTime.now().toIso8601String(),
          };
          
          await FirebaseService.saveShipperDashboardResponse(
            shipper.uid,
            docInfo.screenKey,
            updatedData,
          );
        }
      }

      appStateProvider.showSuccess();

      // Reload documents
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to upload document. Please try again.');
      print('Error uploading document: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(DocumentInfo docInfo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Document',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF186230),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${docInfo.displayName}"? This action cannot be undone.',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final userRole = authProvider.userRole;

      appStateProvider.showLoadingWithMessage('Deleting document...');

      // Delete file from storage
      if (docInfo.url != null && docInfo.url!.isNotEmpty) {
        try {
          await FirebaseService.deleteFileFromURL(docInfo.url!);
        } catch (e) {
          print('Error deleting file from storage: $e');
          // Continue even if deletion fails
        }
      }

      // Update dashboard response
      if (userRole == UserRole.carrier) {
        final carrier = authProvider.carrierUser;
        if (carrier != null) {
          final currentData = await FirebaseService.getCarrierDashboardResponse(
            carrier.uid,
            docInfo.screenKey,
          );
          
          if (currentData != null) {
            final updatedData = {
              ...currentData,
              docInfo.key: null,
              'timestamp': DateTime.now().toIso8601String(),
            };
            
            await FirebaseService.saveCarrierDashboardResponse(
              carrier.uid,
              docInfo.screenKey,
              updatedData,
            );
          }
        }
      } else if (userRole == UserRole.shipper) {
        final shipper = authProvider.shipperUser;
        if (shipper != null) {
          final currentData = await FirebaseService.getShipperDashboardResponse(
            shipper.uid,
            docInfo.screenKey,
          );
          
          if (currentData != null) {
            final updatedData = {
              ...currentData,
              docInfo.key: null,
              'timestamp': DateTime.now().toIso8601String(),
            };
            
            await FirebaseService.saveShipperDashboardResponse(
              shipper.uid,
              docInfo.screenKey,
              updatedData,
            );
          }
        }
      }

      appStateProvider.showSuccess();

      // Reload documents
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to delete document. Please try again.');
      print('Error deleting document: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _viewDocument(String? url) {
    if (url == null || url.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DocumentViewerScreen(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userRole;

    final documents = userRole == UserRole.shipper
        ? _shipperDocuments
        : _carrierDocuments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Document Management",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: documents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final docInfo = documents[index];
                  final currentDoc = _documents[docInfo.key] ?? docInfo;
                  final hasDocument = currentDoc.url != null && currentDoc.url!.isNotEmpty;

                  return _buildDocumentCard(currentDoc, hasDocument);
                },
              ),
            ),
    );
  }

  Widget _buildDocumentCard(DocumentInfo docInfo, bool hasDocument) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: docInfo.isRequired && !hasDocument
              ? Colors.red.withOpacity(0.5)
              : Colors.grey.shade300,
          width: docInfo.isRequired && !hasDocument ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            docInfo.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (docInfo.isRequired) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '*',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            hasDocument ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: hasDocument
                                ? const Color(0xFF4B744F)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasDocument ? 'Uploaded' : 'Not uploaded',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasDocument
                                  ? const Color(0xFF4B744F)
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!docInfo.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasDocument)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        docInfo.url!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasDocument) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewDocument(docInfo.url),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF43975A),
                        side: const BorderSide(color: Color(0xFF43975A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _uploadDocument(docInfo),
                    icon: Icon(
                      hasDocument ? Icons.refresh : Icons.upload,
                      size: 18,
                    ),
                    label: Text(hasDocument ? 'Replace' : 'Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43975A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (hasDocument) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteDocument(docInfo),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentInfo {
  final String key;
  final String storageKey;
  final String displayName;
  final bool isRequired;
  final String screenKey;
  final String? url;

  const DocumentInfo({
    required this.key,
    required this.storageKey,
    required this.displayName,
    required this.isRequired,
    required this.screenKey,
    this.url,
  });
}

class _DocumentViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _DocumentViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
