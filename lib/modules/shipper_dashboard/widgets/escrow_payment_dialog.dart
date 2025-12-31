import 'package:flutter/material.dart';
import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/core/stripe_service.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:remiles/providers/auth_provider.dart';

class EscrowPaymentDialog extends StatefulWidget {
  final String loadId;
  final String carrierId;
  final double amount;
  final String? loadNumber;

  const EscrowPaymentDialog({
    super.key,
    required this.loadId,
    required this.carrierId,
    required this.amount,
    this.loadNumber,
  });

  @override
  State<EscrowPaymentDialog> createState() => _EscrowPaymentDialogState();
}

class _EscrowPaymentDialogState extends State<EscrowPaymentDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shipper = authProvider.shipperUser;
      
      if (shipper == null) {
        throw Exception('Shipper not found. Please log in again.');
      }

      // Process escrow payment (this creates the payment intent and processes payment)
      final success = await StripeService.processEscrowPayment(
        amountInCents: (widget.amount * 100).toInt(),
        loadId: widget.loadId,
        carrierId: widget.carrierId,
        shipperId: shipper.uid,
      );

      if (success) {
        // Get payment intent ID from escrow payment record (created by backend)
        // Wait a moment for the backend to create the record
        await Future.delayed(const Duration(milliseconds: 500));
        final escrowPayment = await FirebaseService.getEscrowPayment(widget.loadId);
        if (escrowPayment != null && escrowPayment['paymentIntentId'] != null) {
          // Mark as deposited
          await FirebaseService.markEscrowPaymentDeposited(
            paymentIntentId: escrowPayment['paymentIntentId'] as String,
            loadId: widget.loadId,
          );
        }

        if (mounted) {
          Navigator.of(context).pop(true); // Return success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment deposited successfully! Funds are held in escrow.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Payment was canceled');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted && !_errorMessage!.contains('canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $_errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.lock, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deposit Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Escrow Protection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment will be securely held in escrow until the carrier completes the shipment and you verify the proof of delivery. You can then release the payment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Load Info
            if (widget.loadNumber != null) ...[
              _buildInfoRow('Load Number', widget.loadNumber!),
              const SizedBox(height: 8),
            ],
            _buildInfoRow('Load ID', widget.loadId.substring(0, 8)),
            const SizedBox(height: 8),
            _buildInfoRow('Payment Amount', '\$${widget.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 20),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Deposit Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
