import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FilterManageLoadScreen extends StatefulWidget {
  const FilterManageLoadScreen({Key? key}) : super(key: key);

  @override
  State<FilterManageLoadScreen> createState() => _FilterManageLoadScreenState();
}

class _FilterManageLoadScreenState extends State<FilterManageLoadScreen> {
  String? selectedEquipment;

  final List<String> equipmentTypes = [
    "Dry Van",
    "Reefer",
    "Flat bed",
    "Box Truck",
    "Tanker",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopNavigationBar(context),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: const Text(
              'Manage Loads',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 32,
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInputTile(
                    icon: Icon( Icons.location_on,color: primaryColor),
                    text: "Select Location",
                  ),
                  const SizedBox(height: 16),
                  _buildInputTile(
                    icon:SvgPicture.asset('assets/calender.svg',color: primaryColor,height: 24,width: 24),
                    text: "Date",
                  ),
                  const SizedBox(height: 16),
                  _buildInputTile(
                    icon: SvgPicture.asset('assets/truck.svg',color: primaryColor,height: 24,width: 24),
                    text: "Load ID",
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Types of Equipment",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: equipmentTypes.map((e) {
                      final isSelected = selectedEquipment == e;
                      return ChoiceChip(
                        label: Text(e),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => selectedEquipment = e);
                        },
                        backgroundColor: Colors.white,
                        shadowColor: Colors.green,
                        elevation: 2,
                        selectedColor: const Color(0xFF497A57),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.black12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF497A57),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Search",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTile({required Widget icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
         icon,
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
