import 'package:Remiles/core/theme/colors.dart';
import 'package:flutter/material.dart';

class BookedNow extends StatelessWidget {
  const BookedNow({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Load ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DateChip(text: "Sep 1st, 5:00 PM"),
                Text(
                    "Load ID #1234",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            /// From
            Row(
              children:  [
                Icon(Icons.location_on, color: primaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "From : Fredericton, NB E1C 8DG",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DateChip(text: "Sep 3st, 10:00 AM"),
            const SizedBox(height: 12),
            /// To
            Row(
              children:  [
                Icon(Icons.location_on, color: primaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "To : Truro, NS BOP 1RO",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),

            /// Distance & Weight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:  [
                Text(
                  "Distance : 215 (mi)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
                ),
                Text(
                  "Weight : 15,000 lb",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Equipment
             Text(
              "Equipment Needed: Reefer",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
            ),
            const SizedBox(height: 8),

            /// Declared Value
             Text(
              "Declared Value : \$5000 CAD",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
            ),
            const SizedBox(height: 8),

            /// Dimensions
             Text(
              "Dimensions : 10 by 7 ft",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
            ),
            const SizedBox(height: 8),

            /// Description
             Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Description : ",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: "Fresh Produce handle with care",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// Tags
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "FRAGILE",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Temperature Control",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Payment
            Row(
              children: [
                const Text(
                  "Payment:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "\$1500",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(width: 70),
                 Text(
                  "Open Docs",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor ,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Accept",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const NegotiateLoad()),
                  // );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade200 ,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Negotiate",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class DateChip extends StatelessWidget {
  final String text;

  const DateChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

