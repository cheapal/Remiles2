import 'package:flutter/material.dart';

class ShipperCreateListing extends StatefulWidget {
  const ShipperCreateListing({super.key});

  @override
  State<ShipperCreateListing> createState() => _ShipperCreateListingState();
}

class _ShipperCreateListingState extends State<ShipperCreateListing> {
  String selectedCondition = "New";

  final List<String> conditions = [
    "New",
    "Used - Like New",
    "Used - Good",
    "Used - Fair",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row for photos & video
                Row(
                  children: [
                    Expanded(
                      child: _uploadCard(Icons.camera_alt, "Product Photos"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _uploadCard(Icons.videocam, "Product Video"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                _inputField("Name of Product"),
                const SizedBox(height: 12),

                // Description
                _inputField("Product Description", maxLines: 3),
                const SizedBox(height: 12),

                // Price
                _inputField("Price", keyboard: TextInputType.number),
                const SizedBox(height: 12),

                // Location
                TextField(
                  decoration: InputDecoration(
                    hintText: "Select Location",
                    suffixIcon: const Icon(Icons.filter_alt_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Condition
                const Text(
                  "Condition",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: conditions.map((condition) {
                    final isSelected = selectedCondition == condition;
                    return ChoiceChip(
                      label: Text(condition),
                      selected: isSelected,
                      selectedColor: Colors.green.shade700,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedCondition = condition;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Publish Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Publish",
                    style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _inputField(String hint,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}
