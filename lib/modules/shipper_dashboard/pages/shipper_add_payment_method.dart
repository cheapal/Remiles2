import 'package:Remiles/core/theme/colors.dart';
import 'package:flutter/material.dart';



class ShipperAddPaymentMethod extends StatelessWidget {
  const ShipperAddPaymentMethod({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                const Header(),
                const SizedBox(height: 32),

                // First Payment Card (Default)
                const PaymentCard(
                  cardLogo: VisaLogo(),
                  cardLastFour: '1280',
                  expiryDate: '08/ 2030',
                  isDefault: true,
                ),
                const SizedBox(height: 24),

                // Second Payment Card (Secondary)
                const PaymentCard(
                  cardLogo: VisaLogo(),
                  cardLastFour: '1456',
                  expiryDate: '04/ 2030',
                  isDefault: false,
                ),
                const SizedBox(height: 32),

                // Add Payment Method Button
                AddPaymentMethodButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor, width: 4),
          ),
          child: Icon(
            Icons.person_outline,
            size: 48,
            color: primaryColor,
          ),
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

  const PaymentCard({
    super.key,
    required this.cardLogo,
    required this.cardLastFour,
    required this.expiryDate,
    required this.isDefault,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visa',
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
            // Edit Button
            const Icon(Icons.edit, color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Edit',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(width: 24),


            const Spacer(),

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
       Row(
          children: [
            const Icon(Icons.close, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Remove Payment Method',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
       )
      ],
    );
  }
}


class VisaLogo extends StatelessWidget {
  const VisaLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F71), // Visa Blue
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class AddPaymentMethodButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Handle add payment method action
        },
        icon: const Icon(Icons.add, color: Colors.black54),
        label: const Text(
          'Add Payment Method',
          style: TextStyle(
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