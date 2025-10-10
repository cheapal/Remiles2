import 'package:Remiles/modules/shipper_dashboard/pages/shipper_add_payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Payment Methods",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.person, color: Colors.green, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              /// Card Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                   Image.asset(
                      'assets/visa.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Visa ****1180",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              /// Add Payment Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ShipperAddPaymentMethod()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  "Add Payment Method",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),

              /// Search + Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: SvgPicture.asset('assets/filter_2.svg', fit: BoxFit.scaleDown),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(),
                ],
              ),
              const SizedBox(height: 16),

              /// Date Filters
              Row(
                children: [
                  Expanded(
                    child: _buildDateField("From Date"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField("To Date"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// Transactions List
              _buildTransactionCard("RM-1034", "Sept 18, 2025", 1500, "Paid", Colors.green),
              _buildTransactionCard("RM-1035", "Sept 19, 2025", 1000, "Pending", Colors.orange),
              _buildTransactionCard("RM-1035", "Sept 20, 2025", 1000, "Issue", Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: "dd mm yy",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
      String id, String date, int amount, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("\$$amount",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green)),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
