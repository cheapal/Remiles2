import 'package:flutter/material.dart';

class DeliveryDetailsPage extends StatelessWidget {
  final Map<String, dynamic> load;
  final Map<String, dynamic>? deliveryConfirmationData;
  final String? podUrl;

  const DeliveryDetailsPage({
    super.key,
    required this.load,
    this.deliveryConfirmationData,
    this.podUrl,
  });

  static const Color green = Color(0xFF2E9340);
  static const Color blue = Color(0xFF2265A6);

  @override
  Widget build(BuildContext context) {
    final completionStatus = deliveryConfirmationData?['completionStatus']
        ?.toString()
        .toLowerCase() ??
        '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Delivery Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // POD Image
            if (podUrl != null && podUrl!.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    podUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Confirmation Details Card
            if (deliveryConfirmationData != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          completionStatus == 'complete'
                              ? Icons.check_circle
                              : completionStatus == 'partial'
                                  ? Icons.warning_amber_rounded
                                  : Icons.cancel,
                          color: completionStatus == 'complete'
                              ? green
                              : completionStatus == 'partial'
                                  ? Colors.orange
                                  : Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                completionStatus == 'complete'
                                    ? 'Complete'
                                    : completionStatus == 'partial'
                                        ? 'Partially Complete'
                                        : 'Failed',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: completionStatus == 'complete'
                                      ? green
                                      : completionStatus == 'partial'
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (deliveryConfirmationData!['receiverName'] != null) ...[
                      _buildInfoRow(
                        'Receiver Name',
                        deliveryConfirmationData!['receiverName'],
                        Icons.person,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (deliveryConfirmationData!['reason'] != null ||
                        deliveryConfirmationData!['partialSuccessReason'] !=
                            null) ...[
                      _buildInfoRow(
                        'Reason',
                        deliveryConfirmationData!['reason'] ??
                            deliveryConfirmationData!['partialSuccessReason'] ??
                            'N/A',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (deliveryConfirmationData!['notes'] != null &&
                        deliveryConfirmationData!['notes']
                            .toString()
                            .isNotEmpty) ...[
                      _buildInfoRow(
                        'Notes',
                        deliveryConfirmationData!['notes'],
                        Icons.note,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (deliveryConfirmationData!['paymentAmount'] != null) ...[
                      _buildInfoRow(
                        'Payment Amount',
                        '\$${(_getPaymentAmount()).toStringAsFixed(2)}',
                        Icons.payment,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (deliveryConfirmationData!['confirmedAt'] != null) ...[
                      _buildInfoRow(
                        'Confirmed At',
                        _formatDate(
                          deliveryConfirmationData!['confirmedAt'],
                          includeTime: true,
                        ),
                        Icons.access_time,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getPaymentAmount() {
    final paymentAmount = deliveryConfirmationData!['paymentAmount'];
    if (paymentAmount is num) {
      return paymentAmount.toDouble();
    }
    return double.tryParse(paymentAmount.toString()) ?? 0.0;
  }

  String _formatDate(dynamic timestamp, {bool includeTime = false}) {
    if (timestamp == null) return 'N/A';

    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      // Assume it's a Firestore Timestamp
      dateTime = (timestamp as dynamic).toDate();
    }

    if (includeTime) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
