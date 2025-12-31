import 'package:remiles/core/stripe_service.dart';
import 'package:remiles/core/payment_logo_service.dart';
import 'package:remiles/providers/payment_methods_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShipperAddPaymentMethod extends StatefulWidget {
  const ShipperAddPaymentMethod({super.key});

  @override
  State<ShipperAddPaymentMethod> createState() => _ShipperAddPaymentMethodState();
}

class _ShipperAddPaymentMethodState extends State<ShipperAddPaymentMethod> {
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    // Load payment methods (uses cache if available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodsProvider>().loadPaymentMethods();
    });
  }

  Future<void> _addPaymentMethod() async {
    setState(() => _isAdding = true);
    try {
      final provider = context.read<PaymentMethodsProvider>();
      final success = await provider.addPaymentMethod();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add payment method: ${StripeService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final provider = context.read<PaymentMethodsProvider>();
      await provider.setDefaultPaymentMethod(paymentMethodId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default payment method updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default: ${StripeService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePaymentMethod(String paymentMethodId, bool isDefault, List<Map<String, dynamic>> paymentMethods) async {
    // Prevent deleting the only payment method
    if (paymentMethods.length == 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete the only payment method. Please add another one first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // If deleting default and there are other methods, warn user
    if (isDefault && paymentMethods.length > 1) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Default Payment Method'),
          content: const Text('This is your default payment method. Another payment method will be set as default. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    } else {
      // For non-default methods, just confirm deletion
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Payment Method'),
          content: const Text('Are you sure you want to delete this payment method?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      final provider = context.read<PaymentMethodsProvider>();
      await provider.deletePaymentMethod(paymentMethodId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method deleted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${StripeService.getErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatExpiryDate(int month, int year) {
    final monthStr = month.toString().padLeft(2, '0');
    final yearStr = year.toString().substring(2);
    return '$monthStr/ $yearStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PaymentMethodsProvider>(
          builder: (context, provider, child) {
            final paymentMethods = provider.paymentMethods;
            final isLoading = provider.isLoading && paymentMethods.isEmpty; // Only show loading if no cached data

            return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                const Header(),
                const SizedBox(height: 32),

                    // Loading state (only if no cached data)
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (paymentMethods.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.credit_card_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No payment methods',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a payment method to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Payment Methods List
                      ...paymentMethods.map((method) {
                        final card = method['card'] as Map<String, dynamic>;
                        final brand = card['brand'] as String? ?? 'visa';
                        final last4 = card['last4'] as String? ?? '0000';
                        final expMonth = card['expMonth'] as int? ?? 1;
                        final expYear = card['expYear'] as int? ?? 2025;
                        final isDefault = method['isDefault'] as bool? ?? false;
                        final paymentMethodId = method['id'] as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: PaymentCard(
                            cardLogo: CardBrandLogo(brand: brand),
                            cardLastFour: last4,
                            expiryDate: _formatExpiryDate(expMonth, expYear),
                            isDefault: isDefault,
                            onSetDefault: () => _setDefaultPaymentMethod(paymentMethodId),
                            onDelete: () => _deletePaymentMethod(paymentMethodId, isDefault, paymentMethods),
                          ),
                        );
                      }),

                const SizedBox(height: 32),

                // Add Payment Method Button
                    AddPaymentMethodButton(
                      onPressed: _isAdding ? null : _addPaymentMethod,
                      isLoading: _isAdding,
                    ),
              ],
            ),
          ),
            );
          },
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return   Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                              tooltip: 'Back',
                            ),
                            const SizedBox(width: 8),
        const Text(
                              "Payment Methods",
          style: TextStyle(
                                fontSize: 26,
            fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.person, color: Colors.green, size: 28),
        ),
      ],
    );
                  
  }
}

class PaymentCard extends StatelessWidget {
  final Widget cardLogo;
  final String cardLastFour;
  final String expiryDate;
  final bool isDefault;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const PaymentCard({
    super.key,
    required this.cardLogo,
    required this.cardLastFour,
    required this.expiryDate,
    required this.isDefault,
    this.onSetDefault,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Brand and Number
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Card',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '****$cardLastFour',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(width: 12),
            cardLogo,
          ],
        ),
        const SizedBox(height: 20),

        // Expiry Date
        const Text(
          'Expiry Date',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          expiryDate,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            // Set Default Button (only if not default)
            if (!isDefault && onSetDefault != null)
              Expanded(
                child: GestureDetector(
                  onTap: onSetDefault,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_outline, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Set as Default',
              style: TextStyle(fontSize: 16, color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ),
            if (!isDefault && onSetDefault != null) const SizedBox(width: 12),
            // Status Tag
            Text(
              isDefault ? 'Default' : 'Secondary',
              style: TextStyle(
                fontSize: 16,
                color: isDefault ? Colors.green.shade700 : Colors.black54,
                fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Remove Button
        if (onDelete != null)
          GestureDetector(
            onTap: onDelete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, color: Colors.red, size: 20),
            const SizedBox(width: 8),
                Flexible(
                  child: Text(
              'Remove Payment Method',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ],
            ),
          ),
      ],
    );
  }
}

class CardBrandLogo extends StatelessWidget {
  final String brand;
  final double? width;
  final double? height;

  const CardBrandLogo({
    super.key,
    required this.brand,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return PaymentLogoService().getLogoWidget(brand, width: width, height: height);
  }
}

class AddPaymentMethodButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const AddPaymentMethodButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add, color: Colors.black54),
        label: Text(
          isLoading ? 'Adding...' : 'Add Payment Method',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
      ),
    );
  }
}
