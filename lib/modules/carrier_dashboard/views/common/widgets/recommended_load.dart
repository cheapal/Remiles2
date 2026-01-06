import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/load_model.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/booked_now.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecommendedLoad extends StatefulWidget {
  final LoadModel load;

  const RecommendedLoad({super.key, required this.load});

  @override
  State<RecommendedLoad> createState() => _RecommendedLoadState();
}

class _RecommendedLoadState extends State<RecommendedLoad> {
  bool _isBooking = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.load.status;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _currentStatus == 'booked'
          ? () => _showLoadDetails(context)
          : (_isBooking ? null : () => _bookLoad(context)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // border: Border.all(color: Colors.green.shade200, width: 2),
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
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Recommended Load",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${widget.load.matchPercentage?.toStringAsFixed(0) ?? '0'}% Match",
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
                    "\$${widget.load.price.toStringAsFixed(0)}   ${widget.load.distance.toStringAsFixed(0)}(mi)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "Load ID #${widget.load.id.isNotEmpty ? widget.load.id : 'N/A'}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// From/To
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "From : ${widget.load.originAddress.isNotEmpty ? widget.load.originAddress : (widget.load.originCity.isNotEmpty || widget.load.originState.isNotEmpty ? '${widget.load.originCity}, ${widget.load.originState}' : 'N/A')}",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "To : ${widget.load.destinationAddress.isNotEmpty ? widget.load.destinationAddress : (widget.load.destinationCity.isNotEmpty || widget.load.destinationState.isNotEmpty ? '${widget.load.destinationCity}, ${widget.load.destinationState}' : 'N/A')}",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    "assets/calender.svg",
                    width: 18,
                    height: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Pickup : ${_formatDate(widget.load.pickupDate)}",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    "assets/calender.svg",
                    width: 18,
                    height: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Delivery : ${_formatDate(widget.load.deliveryDate)}",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 12, color: Colors.grey),
              const SizedBox(height: 12),

              /// Weight
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SvgPicture.asset(
                    "assets/truck.svg",
                    width: 18,
                    height: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.load.weight.toStringAsFixed(0)} lb",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      "Equipment: ${widget.load.equipmentNeeded}",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Instant Booking or View Details
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStatus == 'booked'
                        ? Colors.blue
                        : (_isBooking ? Colors.grey : const Color(0xFFFFCA4D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadowColor: Colors.black.withOpacity(1),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 0,
                    ),
                  ),
                  onPressed: _currentStatus == 'booked'
                      ? () => _showLoadDetails(context)
                      : (_isBooking ? null : () => _bookLoad(context)),
                  child: _isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _currentStatus == 'booked'
                              ? "View Details"
                              : "Instant Booking",
                          style: TextStyle(
                            color: _currentStatus == 'booked'
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _bookLoad(BuildContext context) async {
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

      final success = await FirebaseService.bookLoad(
        loadId: widget.load.id,
        carrierUid: user.uid,
      );

      setState(() {
        _isBooking = false;
        if (success) {
          _currentStatus = 'booked';
        }
      });

      if (success) {
        // Navigate to chat after successful booking
        if (context.mounted) {
          await _navigateToChat();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load booked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book load. Please try again.'),
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

  Future<void> _navigateToChat() async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return;

      final conversationId = await FirebaseService.createLoadConversation(
        loadId: widget.load.id,
        carrierUid: user.uid,
        shipperUid: widget.load.shipperUid,
      );

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: widget.load.shipperUid,
              otherUserName: widget.load.shipperName,
              listingId: null,
              loadId: widget.load.id,
              loadPrice: widget.load.price,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to chat: $e');
    }
  }

  void _showLoadDetails(BuildContext context) {
    // Show details for booked loads - create updated load with current status
    final updatedLoad = widget.load.copyWith(status: _currentStatus);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: BookedNow(load: updatedLoad)),
        );
      },
    );
  }
}
