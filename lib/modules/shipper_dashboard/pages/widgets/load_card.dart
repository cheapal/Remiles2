import 'package:flutter/material.dart';

class LoadCard extends StatelessWidget {
  final String from;
  final String to;
  final String pickupDate;
  final String deliveryDate;
  final String status;
  final String loadId;
  final String equipment;
  final String weight;
  final String price;
  final String distance;
  final String docs;

  const LoadCard({
    super.key,
    required this.from,
    required this.to,
    required this.pickupDate,
    required this.deliveryDate,
    required this.status,
    required this.loadId,
    required this.equipment,
    required this.weight,
    required this.price,
    required this.distance,
    required this.docs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tabs (Active Loads, In-Transit, Completed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab("Active Loads", true),
                const SizedBox(width: 8),
                _buildTab("In-Transit", false),
                const SizedBox(width: 8),
                _buildTab("Completed", false),
              ],
            ),
            const SizedBox(height: 16),

            // From / To
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 4),
                Text("From : $from"),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 4),
                Text("To : $to"),
              ],
            ),
            const SizedBox(height: 8),

            // Pickup & Delivery
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text("Pickup : $pickupDate"),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text("Delivery : $deliveryDate"),
              ],
            ),
            const SizedBox(height: 12),

            // Status + LoadId
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "#$loadId",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "Equipment Needed: $equipment",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 24),

            // Bottom Row Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bottomInfo(Icons.local_shipping, weight),
                _bottomInfo(Icons.attach_money, price),
                _bottomInfo(Icons.directions_car, "$distance (mi)"),
                _bottomInfo(Icons.insert_drive_file, "$docs Docs"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 3),
                blurRadius: 5,
              )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _bottomInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
