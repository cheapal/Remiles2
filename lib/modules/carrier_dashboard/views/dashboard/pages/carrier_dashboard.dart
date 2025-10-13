import 'package:Remiles/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../common/widgets/recommended_load.dart';
import '../../common/widgets/top_navigation_bar.dart';


class CarrierDashboardScreen extends StatelessWidget {
   CarrierDashboardScreen({super.key});

  final primaryColor = Color(0xFF1C6B4A);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final carrier = authProvider.carrierUser;
        
        // Use company name if available, otherwise use display name, otherwise fallback to 'User'
        final displayName = carrier?.companyName ?? 
                           user?.displayName ?? 
                           'User';
        
        return _buildDashboard(context, displayName);
      },
    );
  }
  
  Widget _buildDashboard(BuildContext context, String displayName) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:

      SingleChildScrollView(
        child: Column(
          children: [
            /// Top Navigation Bar
            TopNavigationBar(context),

            const SizedBox(height: 20),

            /// Welcome Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Welcome\n$displayName",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  [
                      SvgPicture.asset('assets/eco.svg',
                          width: 50, height: 50,),

                      SizedBox(width: 20),
                      SvgPicture.asset('assets/person.svg',
                          width: 75, height: 65,),
                      SizedBox(width: 20),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Action Buttons
            Padding(
              padding: const EdgeInsets.only(left:15, right: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellowColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 42, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Find Loads",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 42, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "\$ Payment",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Carrier Preferences
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:  [
                  Text(
                    "Carrier Preferences",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SvgPicture.asset('assets/filter.svg',
                      width: 20, height: 20, color: Colors.black54),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Recommended Load Caimport 'package:flutter/material.dart';
            // import 'package:flutter_svg/flutter_svg.dart';
            //
            // class LoadCard extends StatelessWidget {
            //   const LoadCard({super.key});
            //
            //   @override
            //   Widget build(BuildContext context) {
            //     return Card(
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //       elevation: 3,
            //       margin: const EdgeInsets.all(12),
            //       child: Container(
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(16),
            //           border: Border.all(color: Colors.green.shade200, width: 2),
            //         ),
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             // Top Row
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children: [
            //                 Row(
            //                   children: [
            //                     const Text(
            //                       "\$1500",
            //                       style: TextStyle(
            //                         fontSize: 20,
            //                         fontWeight: FontWeight.bold,
            //                         color: Colors.green,
            //                       ),
            //                     ),
            //                     const SizedBox(width: 12),
            //                     const Text(
            //                       "215 (mi)",
            //                       style: TextStyle(fontSize: 16),
            //                     ),
            //                   ],
            //                 ),
            //                 Container(
            //                   padding:
            //                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //                   decoration: BoxDecoration(
            //                     color: Colors.green,
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                   child: const Text(
            //                     "Available",
            //                     style: TextStyle(color: Colors.white),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 12),
            //
            //             // Route Info
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/location.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("From : Toronto, ON"),
            //               ],
            //             ),
            //             const SizedBox(height: 6),
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/location.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("To : Montreal, QC"),
            //                 const Spacer(),
            //                 const Text(
            //                   "Load ID #1234",
            //                   style: TextStyle(fontWeight: FontWeight.bold),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 12),
            //
            //             // Pickup & Delivery Dates
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/calendar.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("Pickup : Sep 1st, 2025"),
            //               ],
            //             ),
            //             const SizedBox(height: 6),
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/calendar.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("Delivery : Sep 3rd, 2025"),
            //                 const Spacer(),
            //                 ElevatedButton(
            //                   onPressed: () {},
            //                   style: ElevatedButton.styleFrom(
            //                     backgroundColor: Colors.green,
            //                     shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(12)),
            //                   ),
            //                   child: const Text("Book Now"),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 12),
            //             const Divider(),
            //
            //             // Bottom Row
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/truck.svg",
            //                     width: 20, height: 20, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("15,000 lb"),
            //                 const Spacer(),
            //                 const Text("Equipment Needed: Flatbed"),
            //                 const Spacer(),
            //                 const Text(
            //                   "2 Docs",
            //                   style: TextStyle(
            //                       fontWeight: FontWeight.bold, color: Colors.green),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     );
            //   }
            // }rd
            RecommendedLoad(),
            // Padding(
            //   padding: const EdgeInsets.all(23.0),
            //   child: aiMatchCard(
            //     context,
            //     recommended: true,
            //     matchPercent: 97,
            //     loadId: '#1234',
            //     from: 'Toronto, ON',
            //     to: 'Montreal. QC',
            //     pickup: 'Sep 1st, 2025',
            //     delivery: 'Sep 3rd, 2025',
            //     weight: '15,000 lb',
            //     docs: '2 Docs',
            //     equipment: 'Flatbed',
            //   ),
            // ),
            const SizedBox(height: 20),

            /// View All Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 26),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CAFFF),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text("View All", style: TextStyle(color: Colors.black,fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(26)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A)
                                .withOpacity(0.5),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFBFF497),
                                ),
                                child:  Center(
                                  child:Icon(Icons.attach_money_outlined),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '2000',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight
                                          .bold, // Updated font weight
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Total Revenue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight
                                  .bold, // Updated font weight
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(26)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A)
                                .withOpacity(0.5),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration:  BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFE0B3),
                                ),
                                child:  Center(
                                  child: Icon(Icons.check),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '50',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight
                                          .bold, // Updated font weight
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Loads Delivered',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight
                                  .bold, // Updated font weight
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _statCard(Icons.card_giftcard, "", "Special Offers"),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(26)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A)
                                .withOpacity(0.5),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                child:  Center(
                                  child:Icon(Icons.star, color: Colors.amber, ),
                                ),
                              ),
                              const SizedBox(width: 0),
                              const Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "3.8/5",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight
                                          .bold, // Updated font weight
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Carrier Ratings",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight
                                  .bold, // Updated font weight
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 80), // space for bottom nav
          ],
        ),
      ),


    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A)
                .withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(

              child: Icon(icon, color: Colors.green, size: 28)),
          const SizedBox(height: 4),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14,  fontWeight: FontWeight.bold,color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
