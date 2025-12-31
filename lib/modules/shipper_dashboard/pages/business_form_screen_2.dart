// import 'package:remiles/shipper_dashboard/shipper_dashboard_2.dart';
// import 'package:flutter/material.dart';
//
// class BusinessFormScreen_2 extends StatefulWidget {
//   const BusinessFormScreen_2({super.key});
//
//   @override
//   State<BusinessFormScreen_2> createState() =>
//       _BusinessFormScreen_2State();
// }
//
// class _BusinessFormScreen_2State extends State<BusinessFormScreen_2> {
//   final _formKey = GlobalKey<FormState>();
//
//   String? gstStatus;
//   String? goGreenChoice;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFAF8F0),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF145A32),
//                   borderRadius: BorderRadius.vertical(
//                     bottom: Radius.circular(16),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       "Please answer the fields below",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),
//                     LinearProgressIndicator(
//                       value: 0.6,
//                       minHeight: 6,
//                       borderRadius: BorderRadius.circular(8),
//                       color: Colors.yellow.shade600,
//                       backgroundColor: Colors.white,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Form
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Business Number (BN) & GST/HST Registration",
//                       style:
//                       TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     const SizedBox(height: 10),
//
//                     TextFormField(
//                       decoration: InputDecoration(
//                         hintText: "What is your Business Number (BN)?",
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       keyboardType: TextInputType.number,
//                     ),
//                     const SizedBox(height: 6),
//                     const Text(
//                       "9-digit CRA-assigned number used for tax purposes.",
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 20),
//
//                     const Text(
//                       "Are you registered for GST/HST?",
//                       style:
//                       TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     const SizedBox(height: 10),
//
//                     _buildRadioOption("Yes", "gst"),
//                     _buildRadioOption("No", "gst"),
//
//                     const SizedBox(height: 8),
//                     const Text(
//                       "If your business is not GST/HST registered, you may not be able to reclaim tax credits. Please consult a tax advisor if unsure.",
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 20),
//
//                     const Text(
//                       "Our app offers a Carbon Footprint Tracking feature. Would you like to earn a ‘Go Green’ badge by making eco-friendly choices on the platform?",
//                       style:
//                       TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//                     ),
//                     const SizedBox(height: 12),
//
//                     _buildRadioOption("Yes, I’m interested in earning the Go Green badge", "goGreen"),
//                     _buildRadioOption("Maybe later", "goGreen"),
//                     _buildRadioOption("Remind me in the future", "goGreen"),
//
//                     const SizedBox(height: 30),
//                     Center(
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF145A32),
//                           minimumSize: const Size(double.infinity, 50),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         onPressed: () {
//                           Navigator.push(context, MaterialPageRoute(builder: (context) => ShipperDashboard2()));
//                         },
//                         child: const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildRadioOption(String label, String group) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           Radio<String>(
//             value: label,
//             groupValue: group == "gst" ? gstStatus : goGreenChoice,
//             activeColor: const Color(0xFF145A32),
//             onChanged: (value) {
//               setState(() {
//                 if (group == "gst") {
//                   gstStatus = value;
//                 } else {
//                   goGreenChoice = value;
//                 }
//               });
//             },
//           ),
//           Expanded(
//             child: Text(
//               label,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
