import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/load_model.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/marketplace_screen.dart';
import 'package:flutter/material.dart';

class BookedNow extends StatefulWidget {
  final LoadModel load;
  final VoidCallback? onLoadBooked;
  
  const BookedNow({super.key, required this.load, this.onLoadBooked});

  @override
  State<BookedNow> createState() => _BookedNowState();
}

class _BookedNowState extends State<BookedNow> {
  bool _isBooking = false;
  String _currentStatus = '';
  String? _bookedByCarrierId; // Store bookedByCarrierId in state

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.load.status;
    _bookedByCarrierId = widget.load.bookedByCarrierId;
    _refreshLoadStatus();
  }

  @override
  void didUpdateWidget(BookedNow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh status when widget is updated
    if (oldWidget.load.id != widget.load.id || 
        oldWidget.load.status != widget.load.status ||
        oldWidget.load.bookedByCarrierId != widget.load.bookedByCarrierId) {
      _refreshLoadStatus();
    }
  }

  Future<void> _refreshLoadStatus() async {
    try {
      // Find the load in shipper subcollections to get latest status and bookedByCarrierId
      final shippersSnapshot = await FirebaseService.shippers.get();
      for (final shipperDoc in shippersSnapshot.docs) {
        final loadDoc = await FirebaseService.shippers
            .doc(shipperDoc.id)
            .collection('loads')
            .doc(widget.load.id)
            .get();
        
        if (loadDoc.exists) {
          final loadData = loadDoc.data();
          final status = loadData?['status'] as String?;
          final bookedByCarrierId = loadData?['bookedByCarrierId'] as String?;
          
          bool needsUpdate = false;
          if (status != null && status != _currentStatus) {
            needsUpdate = true;
          }
          if (bookedByCarrierId != _bookedByCarrierId) {
            needsUpdate = true;
          }
          
          if (needsUpdate && mounted) {
            setState(() {
              if (status != null) {
                _currentStatus = status;
              }
              _bookedByCarrierId = bookedByCarrierId;
            });
          }
          break;
        }
      }
    } catch (e) {
      print('Error refreshing load status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Load ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DateChip(text: _formatDate(widget.load.pickupDate)),
                Text(
                    "Load ID #${widget.load.id.substring(0, 8)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            /// From
            Row(
              children:  [
                Icon(Icons.location_on, color: primaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "From : ${widget.load.originAddress}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DateChip(text: _formatDate(widget.load.deliveryDate)),
            const SizedBox(height: 12),
            /// To
            Row(
              children:  [
                Icon(Icons.location_on, color: primaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "To : ${widget.load.destinationAddress}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),

            /// Distance & Weight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:  [
                Text(
                  "Distance : ${widget.load.distance.toStringAsFixed(0)} (mi)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
                ),
                Text(
                  "Weight : ${widget.load.weight.toStringAsFixed(0)} lb",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Equipment
             Text(
              "Equipment Needed: ${widget.load.equipmentNeeded}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
            ),
            const SizedBox(height: 8),

            /// Load Type
             Text(
              "Load Type : ${widget.load.loadType}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
            ),
            const SizedBox(height: 8),

            /// Shipper
             Text(
              "Shipper : ${widget.load.shipperName}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
            ),
            const SizedBox(height: 8),

            /// Description
             Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Description : ",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: widget.load.description.isNotEmpty ? widget.load.description : "No description provided",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// Tags
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "FRAGILE",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Temperature Control",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Payment
            Row(
              children: [
                const Text(
                  "Payment:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "\$${widget.load.price.toStringAsFixed(0)}",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Status Section
            Row(
              children: [
                const Text(
                  "Status:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentStatus),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(_currentStatus).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _currentStatus.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentStatus == 'available' && !_isBooking ? _bookLoad : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStatus == 'available' ? primaryColor : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isBooking 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStatus == 'available' ? "Accept" : "Already ${_currentStatus.toUpperCase()}",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
              ),
            ),

            // Only show negotiate button for available loads
            if (_currentStatus == 'available') ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToNegotiation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade200 ,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Negotiate",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],

           // Show "View on Map" button only if load was booked by current user
            //if ((_currentStatus == 'booked' || _currentStatus == 'in-transit') && _isBookedByCurrentUser()) ...[
            // Show "View on Map" button if load was booked by current user (any status except available)
            if (_currentStatus != 'available' && _isBookedByCurrentUser()) ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToMarketplace(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.map, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "View on Map",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  bool _isBookedByCurrentUser() {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) return false;
    // Use state value if available, otherwise fall back to widget.load
    final bookedById = _bookedByCarrierId ?? widget.load.bookedByCarrierId;
    return bookedById == currentUser.uid;
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

  Future<void> _bookLoad() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to accept this load?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    // If user cancelled, return early
    if (confirmed != true) {
      return;
    }

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

      print('DEBUG: Starting to book load ${widget.load.id}');
      final success = await FirebaseService.bookLoad(
        loadId: widget.load.id,
        carrierUid: user.uid,
      );
      print('DEBUG: Booking result: $success');

      if (success) {
        setState(() {
          _currentStatus = 'booked';
          _isBooking = false;
          // Update bookedByCarrierId after successful booking
          _bookedByCarrierId = user.uid;
        });
        
        // Refresh load status to ensure we have latest data from Firestore
        await _refreshLoadStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Load booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify parent widget to refresh
        if (widget.onLoadBooked != null) {
          widget.onLoadBooked!();
        }
        
        // Close the dialog and navigate to chat
        Navigator.of(context).pop();
        
        // Navigate to chat with shipper
        if (context.mounted) {
          await _navigateToChat();
        }
      } else {
        setState(() {
          _isBooking = false;
        });
        
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

  Future<void> _navigateToNegotiation() async {
    await _navigateToChat();
  }

  Future<void> _navigateToMarketplace() async {
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarketplaceScreen(
            initialLoadId: widget.load.id,
          ),
        ),
      );
      
      // Refresh load status when returning from marketplace
      if (context.mounted) {
        await _refreshLoadStatus();
        // Notify parent to refresh if callback provided
        if (widget.onLoadBooked != null) {
          widget.onLoadBooked!();
        }
      }
    }
  }

  Future<void> _navigateToChat() async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to chat')),
        );
        return;
      }

      // Show loading indicator if dialog is still open
      if (context.mounted && Navigator.canPop(context)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Create or get conversation for load
      final conversationId = await FirebaseService.createLoadConversation(
        loadId: widget.load.id,
        carrierUid: user.uid,
        shipperUid: widget.load.shipperUid,
      );

      // Close loading dialog if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Navigate to chat screen and refresh status when returning
      if (context.mounted) {
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
        
        // Refresh load status when returning from chat
        if (context.mounted) {
          await _refreshLoadStatus();
          // Notify parent to refresh if callback provided
          if (widget.onLoadBooked != null) {
            widget.onLoadBooked!();
          }
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}




class DateChip extends StatelessWidget {
  final String text;

  const DateChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade800, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

}

