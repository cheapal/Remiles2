import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';

class ShipperLoadDetailsPage extends StatelessWidget {
  final Map<String, dynamic> load;

  const ShipperLoadDetailsPage({
    super.key,
    required this.load,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TopNavigationBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Load Details',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 13.4,
                          spreadRadius: 0,
                          offset: Offset(0, 13.4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Load ID', '#${load['id']?.toString().length != null && load['id']!.toString().length >= 8 ? load['id']!.toString().substring(0, 8) : load['id'] ?? 'N/A'}'),
                          _buildDetailRow('Origin', load['originAddress'] ?? 'N/A'),
                          _buildDetailRow('Destination', load['destinationAddress'] ?? 'N/A'),
                          _buildDetailRow('Load Type', load['loadType'] ?? 'N/A'),
                          _buildDetailRow('Load Sensitivity', load['loadSensitivity'] ?? 'N/A'),
                          _buildDetailRow('Description', load['loadDescription'] ?? 'N/A'),
                          _buildDetailRow('Weight', '${load['weight'] ?? 'N/A'} ${load['weightUnit'] ?? 'kg'}'),
                          _buildDetailRow('Dimensions', load['dimensions'] ?? 'N/A'),
                          _buildDetailRow('Equipment Needed', load['equipmentNeeded'] ?? 'N/A'),
                          _buildDetailRow('Declared Value', '\$${load['declaredValue'] ?? 'N/A'}'),
                          _buildDetailRow('Quote/Budget', '\$${load['quoteBudget'] ?? 'N/A'}'),
                          _buildDetailRow('Pickup Date/Time', _formatDate(load['pickupDateTime'], includeTime: true)),
                          _buildDetailRow('Delivery Window', _formatDeliveryWindow(load)),
                          if (load['additionalDocument'] != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Document',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _viewDocument(context, load['additionalDocument']),
                                    icon: const Icon(Icons.visibility, size: 18),
                                    label: const Text('View Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF386544),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue, {bool includeTime = false}) {
    if (dateValue == null) return 'N/A';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'N/A';
      }
      
      if (includeTime) {
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDeliveryWindow(Map<String, dynamic> load) {
    // Try new DateTime fields first
    if (load['deliveryWindowStart'] != null && load['deliveryWindowEnd'] != null) {
      final startDate = _formatDate(load['deliveryWindowStart'], includeTime: true);
      final endDate = _formatDate(load['deliveryWindowEnd'], includeTime: true);
      if (startDate == endDate) {
        return startDate;
      }
      return '$startDate - $endDate';
    }
    
    // Fallback to old string field
    if (load['deliveryWindow'] != null) {
      return _formatDate(load['deliveryWindow'], includeTime: true);
    }
    
    return 'N/A';
  }

  void _viewDocument(BuildContext context, String? documentUrl) async {
    if (documentUrl == null || documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check if it's an image (common image extensions)
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      final isImage = imageExtensions.any((ext) => documentUrl.toLowerCase().contains(ext));

      if (isImage) {
        // Navigate to full-screen image viewer
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Document',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: PhotoView(
                imageProvider: NetworkImage(documentUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load document',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, event) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } else {
        // For non-image documents, open in browser or external app
        final uri = Uri.parse(documentUrl);
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open document'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

