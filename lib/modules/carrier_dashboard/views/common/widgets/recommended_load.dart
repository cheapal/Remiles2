import 'package:Remiles/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget RecommendedLoad() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
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
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              Text(
                "Recommended Load",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "97% Match",
                style: TextStyle(
                  fontSize: 17,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Price and Load ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "\$1500   215(mi)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Load ID #1234",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// From/To
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: primaryColor),
              const SizedBox(width: 6),
              Text("From : Toronto, ON", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
            ],
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: primaryColor),
              const SizedBox(width: 6),
               Text("To : Montreal, QC", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
            ],
          ),
          Row(
            children: [
             SvgPicture.asset("assets/calender.svg",
                  width: 18, height: 18, color: primaryColor),
              const SizedBox(width: 6),
               Text("Pickup : Sep 1st, 2025", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
            ],
          ),
          Row(
            children:  [
              SvgPicture.asset("assets/calender.svg",
                  width: 18, height: 18, color: primaryColor),
              SizedBox(width: 6),
              Text("Delivery : Sep 3rd, 2025", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 12,color: Colors.grey,),
          const SizedBox(height: 12),

          /// Weight
          Row(
            children:  [
              SvgPicture.asset("assets/truck.svg",
                  width: 18, height: 18, color: primaryColor),
              SizedBox(width: 6),
              Text("15,000 lb",style: TextStyle(fontWeight: FontWeight.w800,color:primaryColor),),
              Spacer(),
              Text("Equipment Needed: Flatbed",style: TextStyle(fontWeight: FontWeight.w500,color:primaryColor),),
            ],
          ),

          const SizedBox(height: 12),

          /// Instant Booking
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCA4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                shadowColor: Colors.black.withOpacity(1),
                elevation: 1,
                padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              ),
              onPressed: () {},
              child: const Text(
                "Instant Booking",
                style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
