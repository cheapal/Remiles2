
import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/load_model.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/booked_now.dart';
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
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.all(12),
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
                      "${widget.load.distance.toStringAsFixed(0)} (mi)",
                      style: TextStyle(fontSize: 16,color: primaryColor,),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (widget.load.matchPercentage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getMatchColor(widget.load.matchPercentage!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${widget.load.matchPercentage!.toStringAsFixed(0)}% Match",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.load.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(widget.load.status),
                        style: const TextStyle(color: Colors.white),
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
                 Text("From : ${widget.load.originCity}, ${widget.load.originState}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                 Text("To : ${widget.load.destinationCity}, ${widget.load.destinationState}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  "Load ID #${widget.load.id.substring(0, 8)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                 Text("Pickup : ${_formatDate(widget.load.pickupDate)}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700)),
              ],
            ),
            Row(
              children: [
                SvgPicture.asset("assets/calender.svg",
                    width: 18, height: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text("Delivery : ${_formatDate(widget.load.deliveryDate)}", style: TextStyle(color: primaryColor,fontSize: 14,fontWeight: FontWeight.w700),),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Single button that handles both view details and booking
                    ElevatedButton(
                      onPressed: widget.load.status == 'available' && !_isBooking 
                          ? () => _handleLoadAction(context)
                          : widget.load.status == 'available' && _isBooking
                              ? null
                              : () => _showLoadDetails(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.load.status == 'available' 
                            ? (_isBooking ? Colors.grey : primaryColor)
                            : _getStatusColor(widget.load.status),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: widget.load.status == 'available' && _isBooking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.load.status == 'available' ? "Book Now" : _getActionText(widget.load.status), 
                              style: const TextStyle(color: Colors.white),
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
              children: [
                SvgPicture.asset("assets/truck.svg",
                    width: 20, height: 20, color: primaryColor),
                const SizedBox(width: 8),
                Text("${widget.load.weight.toStringAsFixed(0)} lb"),
                const Spacer(),
                Text("Equipment: ${widget.load.equipmentNeeded}"),
                const Spacer(),
                 Text(
                  "${widget.load.loadType}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: primaryColor),
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

  Future<void> _handleLoadAction(BuildContext context) async {
    // Direct booking for available loads (instant booking)
    try {
      setState(() {
        _isBooking = true;
      });

      final user = FirebaseService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to book loads')),
        );
        setState(() {
          _isBooking = false;
        });
        return;
      }

      print('DEBUG: Starting instant booking for load ${widget.load.id}');
      final success = await FirebaseService.bookLoad(
        loadId: widget.load.id,
        carrierUid: user.uid,
      );
      print('DEBUG: Instant booking result: $success');

      setState(() {
        _isBooking = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Load booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent to refresh
        if (widget.onLoadBooked != null) {
          widget.onLoadBooked!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Load is no longer available or booking failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadDetails(BuildContext context) {
    // Show details for non-available loads
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: BookedNow(load: widget.load),
          ),
        );
      },
    );
  }

}
