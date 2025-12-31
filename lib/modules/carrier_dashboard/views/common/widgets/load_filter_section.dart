import 'package:remiles/modules/shipper_dashboard/pages/shipper_load_ai_match.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadsFilterSection extends StatelessWidget {
  const LoadsFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Search bar (Search My Loads)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: searchBar(hint: 'Search My Loads',showTrail: true),
        ),


        // Big buttons row: Available Loads | My Bookings
        const SizedBox(height: 16),

        // Status row: In-Transit (active), Cancelled Loads, Completed Loads
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Row(
            children: [
              mediumPills("Available Loads",0, active: true),
              mediumPills("My Bookings",2),

            ],
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              mediumPills("In-Transit",1),
              mediumPills("Cancelled Loads",1),
              mediumPills("Completed Loads",1),
            ],
          ),
        ),
        const SizedBox(height: 16),

      ],
    );
  }

  Widget _buildCategoryButton(String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(24),
        color: isPrimary ? Colors.white : Colors.white,
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }
}

Widget mediumPills(String text, int index, {bool active = false}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.03),
      child: Container(
        height: 40,
        width: 29,
        decoration: BoxDecoration(
          color: active ? brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(25, 85, 41, 0.36),
              blurRadius: 2.0412,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );
}
