
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
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
                      "\$${widget.load.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                     Text(
                      "${widget.load.distance.toStringAsFixed(0)} mi",
                      style: TextStyle(fontSize: 16,color: primaryColor,),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.load.matchPercentage != null) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getMatchColor(widget.load.matchPercentage!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${widget.load.matchPercentage!.toStringAsFixed(0)}% Match",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.load.status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getStatusText(widget.load.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route Info
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "From : ${widget.load.originAddress.isNotEmpty ? widget.load.originAddress : '${widget.load.originCity}, ${widget.load.originState}'}",
                    style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    "To : ${widget.load.destinationAddress.isNotEmpty ? widget.load.destinationAddress : '${widget.load.destinationCity}, ${widget.load.destinationState}'}",
                    style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Load ID #${widget.load.id.isNotEmpty ? widget.load.id : 'N/A'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    softWrap: true,
                  ),
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
                Flexible(
                  child: Text(
                    "Pickup : ${_formatDate(widget.load.pickupDate)}",
                    style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SvgPicture.asset("assets/calender.svg",
                    width: 18, height: 18, color: primaryColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Delivery : ${_formatDate(widget.load.deliveryDate)}",
                    style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Single button that handles both view details and booking
                    ElevatedButton(
                      onPressed: widget.load.status == 'active' || widget.load.status == 'available'
                          ? () => _handleLoadAction(context)
                          : () => _showLoadDetails(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.load.status == 'active' || widget.load.status == 'available'
                            ? primaryColor
                            : _getStatusColor(widget.load.status),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.load.status == 'active' || widget.load.status == 'available' ? "Book Now" : _getActionText(widget.load.status), 
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset("assets/truck.svg",
                          width: 20, height: 20, color: primaryColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "${widget.load.weight.toStringAsFixed(0)} lb",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Equip: ${widget.load.equipmentNeeded}",
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    "${widget.load.loadType}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        return Colors.blue;
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

  String _getActionText(String status) {
    switch (status) {
      case 'booked':
        return 'View Details';
      case 'in-transit':
        return 'Track Load';
      case 'completed':
        return 'View Details';
      case 'cancelled':
        return 'View Details';
      default:
        return 'View';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
