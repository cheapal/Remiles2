import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/ai_miley_page.dart';

import 'package:flutter/material.dart';

class ProductPagePrecise extends StatefulWidget {
  const ProductPagePrecise({Key? key}) : super(key: key);

  @override
  State<ProductPagePrecise> createState() => _ProductPagePreciseState();
}

class _ProductPagePreciseState extends State<ProductPagePrecise> {
  final Color green = const Color(0xFF497A57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // overall white background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              //top nav
              TopNavigationBar(context),
              // ---------- BACK BUTTON ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 0, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              // ---------- TOP IMAGE ----------
              Image.network(
                // replace with your asset if needed
                'https://images.unsplash.com/photo-1502877338535-766e1452684a',
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              Column(
                children: [
                  const SizedBox(height: 24),
                  // ---------- TITLE + PRICE ROW ----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:  [
                        Expanded(
                          child: Text(
                            '2019 Audi R8 V10 Plus\n\$199,999',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, color: green, size: 20),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Toronto, ON",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),


              // ---------- Message card overlaps - use negative translate ----------
              Transform.translate(
                offset: const Offset(0, -10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: green.withOpacity(0.9), width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: green.withOpacity(0.12),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send seller a message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F3F4),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Hello, is this still available?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              decoration: BoxDecoration(
                                color: green,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Send',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ---------- ALERT + SAVE (centered pills) ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _outlinePill(icon: Icons.notifications_none, label: 'Alert', green: green),
                    _outlinePill(icon: Icons.bookmark_border, label: 'Save', green: green),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ---------- PRODUCT DESCRIPTION (black text + "See more" blue) ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    children: [
                      TextSpan(text: 'Description: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      const TextSpan(
                        text:
                        '2019 Truck, 4.0 V8 TFSI quattro, turbocharged v8 makes 800 horsepower and 1098 lb-ft of torque ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: 'See more',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ---------- SELLER ROW ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: green.withOpacity(0.6), width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 32, color: green),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // rating stars + text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ridzan Vadikhu",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),

                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            Icon(Icons.star_border, color: Colors.orange, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "4.2 (39)",
                              style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),




                      ],
                    ),

                    const Spacer(),

                    // big support circle button (matches screenshot)
                    GestureDetector(
                      onTap: () {
                        // handle support tap
                        showDialog(
                          context: context,
                          builder: (context) => AiMileyScreen()
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: green.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: const Icon(Icons.headset_mic, color: Colors.white, size: 36),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlinePill({required IconData icon, required String label, required Color green}) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: green, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: green.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
