import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_profile_doc_upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShipperProfileDocumentManagment extends StatelessWidget {
  const ShipperProfileDocumentManagment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Document Management System',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.black, // ✅ Black text
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Search Box
              TextField(
                decoration: InputDecoration(
                  hintText: "Search by Document Name, Load ID or",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    //ShipperProfileDocUpload
                    showDialog(
                      context: context,
                      builder: (context) {
                        return ShipperProfileDocUpload();
                      },
                    );
                  },
                  child: const Text(
                    "+ Upload",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip("All", true),
                  _buildFilterChip("Proof of Delivery", false),
                  _buildFilterChip("Safety", false),
                  _buildFilterChip("Tax", false),
                  _buildFilterChip("Active", false),
                  _buildFilterChip("Expired", false),
                  _buildFilterChip("Pending", false),
                  _buildFilterChip("Percent", false),
                ],
              ),
              const SizedBox(height: 20),

              // Proof Of Delivery Card
              _buildDocumentCard(
                title: "Proof Of Delivery",
                subtitle: "Date: 04/09/24\nAssociated Load:  Load 1234",
                actions: [
                  _buildActionButton("Download"),
                  _buildActionButton("View"),
                ],
              ),
              const SizedBox(height: 16),

              // Safety Certificate Card
              _build_content_card(
                actions: [
                  SvgPicture.asset(
                    'assets/caution.svg',
                    color: yellowColor,
                    height: 40,
                    width: 40,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Safety Certificate",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Expires on 12/15/24",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w300),),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      selectedColor: Colors.blue.shade100,
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: actions
                    .map(
                      (btn) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: btn,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _build_content_card({required List<Widget> actions}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: actions
                    .map(
                      (btn) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: btn,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text) {
    return OutlinedButton(
      onPressed: () {},
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
