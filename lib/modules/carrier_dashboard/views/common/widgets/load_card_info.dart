import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/models/load_model.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/booked_now.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadCardInfo extends StatefulWidget {
  final LoadModel load;
  final VoidCallback? onLoadBooked;

  const LoadCardInfo({super.key, required this.load, this.onLoadBooked});

  @override
  State<LoadCardInfo> createState() => _LoadCardInfoState();
}

class _LoadCardInfoState extends State<LoadCardInfo> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleLoadAction(context),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.45),
                spreadRadius: 2,
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Price, Distance, Match, Status
              Text(
                "Load ID #${widget.load.id.isNotEmpty ? widget.load.id : 'N/A'}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "\$${widget.load.price.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${widget.load.distance.toStringAsFixed(0)} (mi)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (widget.load.matchPercentage != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMatchColor(
                          widget.load.matchPercentage!,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${widget.load.matchPercentage!.toStringAsFixed(0)}% Match",
                        style: TextStyle(
                          color: _getMatchColor(widget.load.matchPercentage!),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.load.status),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(
                            widget.load.status,
                          ).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getStatusText(widget.load.status),
                      style: TextStyle(
                        color: widget.load.status == 'booked'
                            ? Colors.black
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Body: Addresses & Dates with Load ID on the right
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.location_on,
                        "From : ${widget.load.originAddress.isNotEmpty ? widget.load.originAddress : '${widget.load.originCity}, ${widget.load.originState}'}",
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        "To : ${widget.load.destinationAddress.isNotEmpty ? widget.load.destinationAddress : '${widget.load.destinationCity}, ${widget.load.destinationState}'}",
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today,
                        "Pickup : ${_formatDate(widget.load.pickupDate)}",
                        isSvg: true,
                        svgPath: "assets/calender.svg",
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today,
                        "Delivery : ${_formatDate(widget.load.deliveryDate)}",
                        isSvg: true,
                        svgPath: "assets/calender.svg",
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 16),

              // Footer: Weight, Equipment, LoadType
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      //  SvgPicture.asset(
                      //   "assets/truck.svg",
                      //   width: 20,
                      //   height: 20,
                      //   color: primaryColor,
                      // ),
                      Icon(Icons.local_shipping_outlined, color: primaryColor),
                      const SizedBox(width: 8),

                      Text(
                        "${widget.load.weight.toStringAsFixed(0)} lb",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Text(
                      "Equip: ${widget.load.equipmentNeeded}",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  // Text(
                  //   "Docs 0",
                  //   overflow: TextOverflow.ellipsis,
                  //   maxLines: 1,
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.w700,
                  //     color: primaryColor,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // ),
                  Expanded(
                    child: Text(
                      "${widget.load.loadType}",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildInfoRow(
  IconData icon,
  String text, {
  bool isSvg = false,
  String? svgPath,
}) {
  return Row(
    mainAxisSize: MainAxisSize.max,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (isSvg && svgPath != null)
        SvgPicture.asset(svgPath, width: 18, height: 18, color: primaryColor)
      else
        Icon(icon, size: 18, color: primaryColor),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
  Color _getMatchColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'available':
        return primaryColor;
      case 'booked':
        return const Color(0xFFFFD600);
      case 'in-transit':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'available':
        return 'Available';
      case 'booked':
        return 'Booked';
      case 'in-transit':
        return 'In-Transit';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _handleLoadAction(BuildContext context) {
    // Open dialog for available loads - booking will happen in the dialog
    _showLoadDetails(context);
  }

  void _showLoadDetails(BuildContext context) {
    // Show details dialog for all loads (available loads can be booked from dialog)
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: BookedNow(
              load: widget.load,
              onLoadBooked: widget.onLoadBooked,
            ),
          ),
        );
      },
    );
  }
}
