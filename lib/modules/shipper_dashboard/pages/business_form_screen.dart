// import 'package:remiles/shipper_dashboard/business_form_screen_2.dart';
// import 'package:flutter/material.dart';
//
// class BusinessFormScreen extends StatefulWidget {
//   const BusinessFormScreen({super.key});
//
//   @override
//   State<BusinessFormScreen> createState() => _BusinessFormScreenState();
// }
//
// class _BusinessFormScreenState extends State<BusinessFormScreen> {
//   final _formKey = GlobalKey<FormState>();
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
//                       value: 0.4,
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
//                   children: [
//                     _buildTextField("Business Address"),
//                     _buildTextField("Operating Province(s)"),
//                     _buildTextField("Industry Type", hint: "(manufacturing, retail, agriculture etc.)"),
//                     _buildTextField("Frequent shipment type", hint: "(pallets, containers, oversized loads, etc.)"),
//
//                     const SizedBox(height: 10),
//                     const Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Required Business Documents *",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     _buildUploadTile("Business Registration (Articles of Incorporation or Sole Proprietor Certificate)"),
//                     _buildUploadTile("Upload Proof of Business Insurance (Commercial General Liability, Cargo Insurance, etc.)"),
//
//                     const SizedBox(height: 8),
//                     const Text(
//                       "For safety and compliance, all Re-Miles shippers must provide documentation of valid insurance coverage. This protects your freight and helps us maintain a trusted shipping network.",
//                       style: TextStyle(fontSize: 12, color: Colors.black54),
//                     ),
//                     const SizedBox(height: 10),
//
//                     _buildTextField("Insurance provider"),
//                     _buildTextField("Policy Number"),
//                     _buildTextField("Expiry Date"),
//                     _buildTextField("Coverage Limit"),
//
//                     Row(
//                       children: [
//                         Checkbox(value: false, onChanged: (val) {}),
//                         const Expanded(
//                           child: Text(
//                             "I confirm that my business maintains valid insurance coverage and that all uploaded documents are true and accurate.",
//                             style: TextStyle(color: Colors.red, fontSize: 12),
//                           ),
//                         ),
//                       ],
//                     ),
//                     _buildUploadTile("Government-Issued ID (for business owner or authorized user)"),
//                     _buildUploadTile("Proof of Address (e.g., Utility bill)"),
//
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF145A32),
//                         minimumSize: const Size(double.infinity, 50),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       onPressed: () {
//                         ///business form screen 2 navigate
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const BusinessFormScreen_2()),
//                         );
//                       },
//                       child: const Text("Next", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
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
//   Widget _buildTextField(String label, {String? hint}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: TextFormField(
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: hint,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//           prefixIcon: const Icon(Icons.edit_location_alt_outlined),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildUploadTile(String label) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: () {
//               // Handle file upload
//
//             },
//             child: Container(
//               height: 60,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade400),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Center(
//                 child: Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey),
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
//         ],
//       ),
//     );
//   }
// }
