import 'package:Remiles/core/stripe_service.dart';
import 'package:Remiles/core/payment_logo_service.dart';
import 'package:Remiles/providers/payment_methods_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarrierAddPaymentMethod extends StatefulWidget {
  const CarrierAddPaymentMethod({super.key});

  @override
  State<CarrierAddPaymentMethod> createState() => _CarrierAddPaymentMethodState();
}

class _CarrierAddPaymentMethodState extends State<CarrierAddPaymentMethod> {
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
            backgroundColor: Color(0xFF4B744F),
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
            backgroundColor: Color(0xFF4B744F),
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
    if (isDefault && paymentMethods.length > 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set another payment method as default first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Payment Method',
          style: TextStyle(color: Color(0xFF186230)),
        ),
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

    try {
      final provider = context.read<PaymentMethodsProvider>();
      await provider.deletePaymentMethod(paymentMethodId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method deleted!'),
            backgroundColor: Color(0xFF4B744F),
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
      backgroundColor: const Color(0xFFFFFEF6),
      body: SafeArea(
        child: Consumer<PaymentMethodsProvider>(
          builder: (context, provider, child) {
            final paymentMethods = provider.paymentMethods;
            final isLoading = provider.isLoading && paymentMethods.isEmpty;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    const CarrierPaymentMethodHeader(),
                    const SizedBox(height: 32),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43975A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF43975A), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF186230), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add payment methods to receive payments from shippers',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF186230),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Loading state
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
                                Icons.account_balance_wallet_outlined,
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
                                'Add a payment method to receive payments',
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
                          child: CarrierPaymentCard(
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
                    CarrierAddPaymentMethodButton(
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

class CarrierPaymentMethodHeader extends StatelessWidget {
  const CarrierPaymentMethodHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  "Payment Methods",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF186230),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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

class CarrierPaymentCard extends StatelessWidget {
  final Widget cardLogo;
  final String cardLastFour;
  final String expiryDate;
  final bool isDefault;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const CarrierPaymentCard({
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? const Color(0xFF43975A) : Colors.grey.shade300,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF186230),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '****$cardLastFour',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline, color: Color(0xFF186230), size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Set as Default',
                            style: const TextStyle(fontSize: 16, color: Color(0xFF186230)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isDefault && onSetDefault != null) const SizedBox(width: 12),
              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDefault ? const Color(0xFF43975A).withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDefault ? 'Default' : 'Secondary',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDefault ? const Color(0xFF186230) : Colors.black54,
                    fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                  ),
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
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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

class CarrierAddPaymentMethodButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const CarrierAddPaymentMethodButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF43975A), width: 2),
      ),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF186230)),
              )
            : const Icon(Icons.add_outlined, color: Color(0xFF186230), size: 24),
        label: Text(
          isLoading ? 'Adding...' : 'Add Payment Method',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF186230),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
