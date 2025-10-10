import 'package:flutter/material.dart';

class ShipperBoostMyPage extends StatefulWidget {
  const ShipperBoostMyPage({super.key});

  @override
  State<ShipperBoostMyPage> createState() => _ShipperBoostMyPageState();
}

class _ShipperBoostMyPageState extends State<ShipperBoostMyPage> {
  String selectedPlan = "Starter Bundle";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ White background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Boost My Load',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black, // ✅ Black text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _remainingPostsCard(),
            const SizedBox(height: 20),

            // Starter Bundle
            _planCard(
              title: "Starter Bundle",
              price: "\$99/month",
              details: ["10 load postings + 1 Boost"],
              renewal: "Sept 30*",
              selected: selectedPlan == "Starter Bundle",
              onTap: () {
                setState(() => selectedPlan = "Starter Bundle");
              },
            ),
            const SizedBox(height: 16),

            // Pro Bundle
            _planCard(
              title: "Pro Bundle",
              price: "\$249/month",
              details: ["25 Load Postings + 5 Boost Credits"],
              tag: "Best Value",
              selected: selectedPlan == "Pro Bundle",
              onTap: () {
                setState(() => selectedPlan = "Pro Bundle");
              },
            ),
            const SizedBox(height: 16),

            // Enterprise Bundle
            _planCard(
              title: "Enterprise Bundle",
              price: "\$449/month",
              details: ["Unlimited Load Postings + 10 Boost Credits"],
              selected: selectedPlan == "Enterprise Bundle",
              onTap: () {
                setState(() => selectedPlan = "Enterprise Bundle");
              },
            ),
            const Spacer(),

            // Upgrade Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                //pop
                Navigator.pop(context);
                debugPrint("Selected Plan: $selectedPlan");
              },
              child: const Text(
                "Upgrade My Plan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remainingPostsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // ✅ Light card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Remaining Posts",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          SizedBox(height: 4),
          Text(
            "7/10",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required List<String> details,
    String? renewal,
    String? tag,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // ✅ Light card
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 6),
                Text(price,
                    style:
                    const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 6),
                ...details
                    .map((e) => Text(
                  e,
                  style: const TextStyle(color: Colors.black54),
                ))
                    .toList(),
                if (renewal != null) ...[
                  const SizedBox(height: 6),
                  Text("Renewal Date: $renewal",
                      style: const TextStyle(color: Colors.black54)),
                ],
              ],
            ),

            // Best Value Tag
            if (tag != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
