import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';

class ShipperDashboardMyPreferencePage extends StatefulWidget {
  const ShipperDashboardMyPreferencePage({super.key});

  @override
  State<ShipperDashboardMyPreferencePage> createState() => _ShipperDashboardMyPreferencePageState();
}

class _ShipperDashboardMyPreferencePageState extends State<ShipperDashboardMyPreferencePage> {
  String truckType = "Dry Van";
  String homeBase = "Moncton, NB";
  String radius = "within 250 km of Moncton";
  String loadType = "General Freight";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(

          child: Column(
            children: [
              TopNavigationBar(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 40),
                    /// Title
                    const Text(
                      "My Preferences",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Section: Truck & Equipment
                    const Text(
                      "Truck & Equipment",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField("Truck Type", truckType),
                    const SizedBox(height: 28),

                    /// Section: Service Area / Location
                    const Text(
                      "Service Area / Location",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField("Home Base", homeBase),
                    const SizedBox(height: 16),
                    _buildTextField("Radius", radius),
                    const SizedBox(height: 28),

                    /// Section: Load Preferences
                    const Text(
                      "Load Preferences",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField("Load Type", loadType),
                    const SizedBox(height: 40),

                    /// Save Button
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5D3B),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                         Navigator.pop(context);
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          decoration: InputDecoration(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }
}
