
import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/booked_now.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class LoadCardInfo extends StatelessWidget {
  const LoadCardInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
            BoxShadow(
              color: Colors.white,
              spreadRadius: -2,
              blurRadius: 5,
              offset: const Offset(-3, -3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                     Text(
                      "\$1500",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                     Text(
                      "215 (mi)",
                      style: TextStyle(fontSize: 16,color: primaryColor,),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Available",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route Info
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                 Text("From : Toronto, ON", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                 Text("To : Montreal, QC", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700)),
                const Spacer(),
                const Text(
                  "Load ID #1234",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pickup & Delivery Dates
            Row(
              children: [
                SvgPicture.asset("assets/calender.svg",
                    width: 18, height: 18, color: primaryColor),
                const SizedBox(width: 8),
                 Text("Pickup : Sep 1st, 2025", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700)),
              ],
            ),
            Row(
              children: [
                SvgPicture.asset("assets/calender.svg",
                    width: 18, height: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text("Delivery : Sep 3rd, 2025", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        final screenHeight = MediaQuery.of(ctx).size.height;
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          insetPadding: const EdgeInsets.all(16), // margin from screen edges
                          child:
                          // SizedBox(
                          //   height: screenHeight * 0.7, // 90% of screen height
                          //   child:
                            const SingleChildScrollView(
                              child: BookedNow(),
                          //   ),
                           ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Book Now", style: TextStyle(color: Colors.white),),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Bottom Row
            Row(
              children: [
                SvgPicture.asset("assets/truck.svg",
                    width: 20, height: 20, color: primaryColor),
                const SizedBox(width: 8),
                const Text("15,000 lb"),
                const Spacer(),
                const Text("Equipment Needed: Flatbed"),
                const Spacer(),
                 Text(
                  "2 Docs",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
