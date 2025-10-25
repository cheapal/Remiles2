import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/load_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RecommendedLoad extends StatelessWidget {
  final LoadModel load;
  
  const RecommendedLoad({super.key, required this.load});

  @override
  Widget build(BuildContext context) {
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
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:  [
                Text(
                  "Recommended Load",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${load.matchPercentage?.toStringAsFixed(0) ?? '0'}% Match",
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
              children: [
                Text(
                  "\$${load.price.toStringAsFixed(0)}   ${load.distance.toStringAsFixed(0)}(mi)",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Load ID #${load.id.substring(0, 8)}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// From/To
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 6),
                Text("From : ${load.originCity}, ${load.originState}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
              ],
            ),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 6),
                 Text("To : ${load.destinationCity}, ${load.destinationState}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
              ],
            ),
            Row(
              children: [
               SvgPicture.asset("assets/calender.svg",
                    width: 18, height: 18, color: primaryColor),
                const SizedBox(width: 6),
                 Text("Pickup : ${_formatDate(load.pickupDate)}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
              ],
            ),
            Row(
              children:  [
                SvgPicture.asset("assets/calender.svg",
                    width: 18, height: 18, color: primaryColor),
                const SizedBox(width: 6),
                Text("Delivery : ${_formatDate(load.deliveryDate)}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
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
                const SizedBox(width: 6),
                Text("${load.weight.toStringAsFixed(0)} lb",style: TextStyle(fontWeight: FontWeight.w800,color:primaryColor),),
                const Spacer(),
                Text("Equipment: ${load.equipmentNeeded}",style: TextStyle(fontWeight: FontWeight.w500,color:primaryColor),),
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
                onPressed: () => _bookLoad(context),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _bookLoad(BuildContext context) async {
  try {
    final user = FirebaseService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book loads')),
      );
      return;
    }

    // Show loading dialog
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) => const Center(
    //     child: CircularProgressIndicator(),
    //   ),
    // );

    final success = await FirebaseService.bookLoad(
      loadId: load.id,
      carrierUid: user.uid,
    );

    // Hide loading dialog
    // Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book load. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // Hide loading dialog
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
  }
}
