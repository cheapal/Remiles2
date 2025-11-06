import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';

class ShipperBoostMyPage extends StatefulWidget {
  const ShipperBoostMyPage({super.key});

  @override
  State<ShipperBoostMyPage> createState() => _ShipperBoostMyPageState();
}

class _ShipperBoostMyPageState extends State<ShipperBoostMyPage> {
  String selectedPlan = ""; // Empty string means no plan selected
  bool _isLoading = false;
  int _usedPosts = 0;
  int _postLimit = 10; // Default limit
  List<Map<String, dynamic>> _subscriptionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      if (shipper != null) {
        // Get shipper document directly to access subscriptionPlan field
        final shipperDoc = await FirebaseService.shippers.doc(shipper.uid).get();
        
        Map<String, dynamic>? currentData;
        if (shipperDoc.exists) {
          currentData = shipperDoc.data() as Map<String, dynamic>?;
          if (currentData != null) {
            // Load subscription plan
            if (currentData['subscriptionPlan'] != null) {
              setState(() {
                selectedPlan = currentData!['subscriptionPlan'] as String;
              });
            } else {
              // No plan subscribed, set to empty
              setState(() {
                selectedPlan = "";
              });
            }
            
            // Load post limit from subscription
            final loadPostingsLimit = currentData['loadPostingsLimit'];
            if (loadPostingsLimit != null) {
              setState(() {
                _postLimit = loadPostingsLimit is int ? loadPostingsLimit : int.tryParse(loadPostingsLimit.toString()) ?? 10;
              });
            }
          }
        }
        
        // Load total number of loads posted
        final loadStats = await FirebaseService.getShipperLoadStats(shipper.uid);
        
        // Load subscription history
        final history = currentData?['subscriptionHistory'] as List<dynamic>?;
        final historyList = history != null
            ? List<Map<String, dynamic>>.from(
                history.map((e) => e as Map<String, dynamic>)
              )
            : <Map<String, dynamic>>[];
        
        setState(() {
          _usedPosts = loadStats['total'] ?? 0;
          _subscriptionHistory = historyList;
        });
      }
    } catch (e) {
      debugPrint('Error loading current plan: $e');
    }
  }

  Future<void> _savePlan() async {
    if (_isLoading) return;
    
    // Check if a plan is selected
    if (selectedPlan.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a plan first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Determine plan details based on selected plan
      Map<String, dynamic> planData = {};
      switch (selectedPlan) {
        case "Starter Bundle":
          planData = {
            'subscriptionPlan': 'Starter Bundle',
            'subscriptionPrice': 99,
            'loadPostingsLimit': 10,
            'boostCredits': 1,
            'subscriptionType': 'monthly',
          };
          break;
        case "Pro Bundle":
          planData = {
            'subscriptionPlan': 'Pro Bundle',
            'subscriptionPrice': 249,
            'loadPostingsLimit': 25,
            'boostCredits': 5,
            'subscriptionType': 'monthly',
          };
          break;
        case "Enterprise Bundle":
          planData = {
            'subscriptionPlan': 'Enterprise Bundle',
            'subscriptionPrice': 449,
            'loadPostingsLimit': -1, // -1 for unlimited
            'boostCredits': 10,
            'subscriptionType': 'monthly',
          };
          break;
      }

      // Add subscription date
      planData['subscriptionStartDate'] = DateTime.now().toIso8601String();
      planData['subscriptionUpdatedAt'] = DateTime.now().toIso8601String();

      // Get current subscription data to save to history
      final shipperDoc = await FirebaseService.shippers.doc(shipper.uid).get();
      final currentData = shipperDoc.data() as Map<String, dynamic>?;
      
      // Prepare history entry from current subscription (if exists and different)
      Map<String, dynamic>? historyEntry;
      if (currentData != null && 
          currentData['subscriptionPlan'] != null &&
          currentData['subscriptionPlan'] != selectedPlan) {
        // Only save to history if it's different from the new plan
        historyEntry = {
          'subscriptionPlan': currentData['subscriptionPlan'],
          'subscriptionPrice': currentData['subscriptionPrice'] ?? 0,
          'loadPostingsLimit': currentData['loadPostingsLimit'] ?? 0,
          'boostCredits': currentData['boostCredits'] ?? 0,
          'subscriptionType': currentData['subscriptionType'] ?? 'monthly',
          'subscriptionStartDate': currentData['subscriptionStartDate'],
          'subscriptionEndDate': DateTime.now().toIso8601String(), // When it ended
          'changedAt': DateTime.now().toIso8601String(),
          'reason': 'plan_change', // Reason for change
        };
      }

      // Update shipper document with new plan and add to history
      final updates = Map<String, dynamic>.from(planData);
      
      if (historyEntry != null) {
        // Get existing history or initialize empty array
        final existingHistory = currentData?['subscriptionHistory'] as List<dynamic>? ?? [];
        
        // Add current subscription to history array (avoid duplicates)
        final updatedHistory = List<Map<String, dynamic>>.from(
          existingHistory.map((e) => e as Map<String, dynamic>)
        );
        updatedHistory.add(historyEntry);
        
        // Store updated history
        updates['subscriptionHistory'] = updatedHistory;
      } else if (currentData != null && currentData['subscriptionHistory'] == null) {
        // Initialize empty history array if it doesn't exist
        updates['subscriptionHistory'] = [];
      }
      
      await FirebaseService.updateShipper(shipper.uid, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated to $selectedPlan successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Reload plan data to update remaining posts
        await _loadCurrentPlan();
        
        // Pop after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update plan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ White background
      body: Column(
        children: [
          // Top Navigation Bar
          TopNavigationBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text(
                  'Boost My Load',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black, // ✅ Black text
                    fontWeight: FontWeight.bold,
                  ),
                    ),
                    IconButton(
                      onPressed: _showSubscriptionHistory,
                      icon: const Icon(Icons.history, color: Colors.black),
                      tooltip: 'View Subscription History',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
          
                _remainingPostsCard(),
                const SizedBox(height: 20),
          
                // Starter Bundle
                _planCard(
                  title: "Starter Bundle",
                  price: "\$99/month",
                  details: ["10 load postings + 1 Boost"],
                  renewal: "Sept 30*",
                  selected: selectedPlan == "Starter Bundle",
                  onTap: () {
                    setState(() {
                      selectedPlan = "Starter Bundle";
                      _postLimit = 10;
                    });
                  },
                ),
                const SizedBox(height: 16),
          
                // Pro Bundle
                _planCard(
                  title: "Pro Bundle",
                  price: "\$249/month",
                  details: ["25 Load Postings + 5 Boost Credits"],
                  tag: "Best Value",
                  selected: selectedPlan == "Pro Bundle",
                  onTap: () {
                    setState(() {
                      selectedPlan = "Pro Bundle";
                      _postLimit = 25;
                    });
                  },
                ),
                const SizedBox(height: 16),
          
                // Enterprise Bundle
                _planCard(
                  title: "Enterprise Bundle",
                  price: "\$449/month",
                  details: ["Unlimited Load Postings + 10 Boost Credits"],
                  selected: selectedPlan == "Enterprise Bundle",
                  onTap: () {
                    setState(() {
                      selectedPlan = "Enterprise Bundle";
                      _postLimit = -1; // Unlimited
                    });
                  },
                ),
                const SizedBox(height: 30),
          
                // Upgrade Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _savePlan,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                    "Upgrade My Plan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubscriptionHistory() async {
    final authProvider = context.read<AuthProvider>();
    final shipper = authProvider.shipperUser;
    
    // Get current subscription from Firebase
    Map<String, dynamic>? currentSubscription;
    if (shipper != null) {
      try {
        final shipperDoc = await FirebaseService.shippers.doc(shipper.uid).get();
        if (shipperDoc.exists) {
          final data = shipperDoc.data() as Map<String, dynamic>?;
          if (data != null && data['subscriptionPlan'] != null) {
            currentSubscription = {
              'subscriptionPlan': data['subscriptionPlan'],
              'subscriptionPrice': data['subscriptionPrice'] ?? _getPlanPrice(selectedPlan),
              'loadPostingsLimit': data['loadPostingsLimit'] ?? _postLimit,
              'boostCredits': data['boostCredits'] ?? _getPlanBoostCredits(selectedPlan),
              'subscriptionType': data['subscriptionType'] ?? 'monthly',
              'subscriptionStartDate': data['subscriptionStartDate'],
              'status': 'active',
            };
          }
        }
      } catch (e) {
        debugPrint('Error loading current subscription: $e');
      }
    }
    
    // If no current subscription found and a plan is selected, create one from state
    if (currentSubscription == null && selectedPlan.isNotEmpty) {
      currentSubscription = {
        'subscriptionPlan': selectedPlan,
        'subscriptionPrice': _getPlanPrice(selectedPlan),
        'loadPostingsLimit': _postLimit,
        'boostCredits': _getPlanBoostCredits(selectedPlan),
        'subscriptionType': 'monthly',
        'subscriptionStartDate': DateTime.now().toIso8601String(),
        'status': 'active',
      };
    }
    
    // Combine current with history (newest first)
    final allSubscriptions = <Map<String, dynamic>>[];
    if (currentSubscription != null) {
      allSubscriptions.add(currentSubscription);
    }
    allSubscriptions.addAll(_subscriptionHistory.reversed);
    
    // Navigate to full screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionHistoryScreen(
          subscriptions: allSubscriptions,
          shipper: shipper,
        ),
      ),
    );
  }

  Widget _remainingPostsCard() {
    // Calculate remaining posts
    final remaining = _postLimit == -1 ? -1 : (_postLimit - _usedPosts);
    final displayText = _postLimit == -1 
        ? "$_usedPosts/Unlimited" 
        : "$_usedPosts/$_postLimit";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // ✅ Light card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Remaining Posts",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_postLimit != -1 && remaining >= 0) ...[
            const SizedBox(height: 4),
            Text(
              "$remaining posts remaining",
              style: TextStyle(
                color: remaining < 3 ? Colors.red : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required List<String> details,
    String? renewal,
    String? tag,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // ✅ Light card
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 6),
                Text(price,
                    style:
                    const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 6),
                ...details
                    .map((e) => Text(
                  e,
                  style: const TextStyle(color: Colors.black54),
                ))
                    .toList(),
                if (renewal != null) ...[
                  const SizedBox(height: 6),
                  Text("Renewal Date: $renewal",
                      style: const TextStyle(color: Colors.black54)),
                ],
              ],
            ),

            // Best Value Tag
            if (tag != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(tag,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getPlanPrice(String plan) {
    switch (plan) {
      case "Starter Bundle":
        return 99;
      case "Pro Bundle":
        return 249;
      case "Enterprise Bundle":
        return 449;
      default:
        return 0;
    }
  }

  int _getPlanBoostCredits(String plan) {
    switch (plan) {
      case "Starter Bundle":
        return 1;
      case "Pro Bundle":
        return 5;
      case "Enterprise Bundle":
        return 10;
      default:
        return 0;
    }
  }
}

// Full Screen Subscription History Screen
class SubscriptionHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> subscriptions;
  final dynamic shipper;

  const SubscriptionHistoryScreen({
    super.key,
    required this.subscriptions,
    required this.shipper,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Professional Header with Back Button
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'History & Receipts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // History List
          Expanded(
            child: subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No subscription history available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = subscriptions[index];
                        final isActive = subscription['status'] == 'active';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHistoryItem(context, subscription, isActive, shipper),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    Map<String, dynamic> subscription,
    bool isActive,
    dynamic shipper,
  ) {
    final plan = subscription['subscriptionPlan'] ?? 'N/A';
    final price = subscription['subscriptionPrice'] ?? 0;
    final limit = subscription['loadPostingsLimit'] ?? 0;
    final boostCredits = subscription['boostCredits'] ?? 0;
    final startDate = subscription['subscriptionStartDate'];
    final endDate = subscription['subscriptionEndDate'];
    final changedAt = subscription['changedAt'] ?? startDate;
    final status = isActive ? 'Active' : 'Ended';
    final subscriptionType = subscription['subscriptionType'] ?? 'monthly';
    
    final receiptText = _formatReceipt(subscription, shipper);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive 
                    ? [Colors.green.shade50, Colors.green.shade100]
                    : [Colors.grey.shade50, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.history,
                            color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green.shade900 : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons with better styling
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        color: Colors.blue,
                        onPressed: () => _copyReceipt(context, receiptText),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      _buildActionButton(
                        icon: Icons.print,
                        label: 'Print',
                        color: Colors.green,
                        onPressed: () => _printReceipt(context, receiptText, plan, shipper),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        color: Colors.orange,
                        onPressed: () => _shareReceipt(context, receiptText, plan),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Detailed Information Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pricing Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$$price',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            '/month',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: Colors.blue.shade200,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Subscription Type',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subscriptionType.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Features Section
                Text(
                  'Plan Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  Icons.local_shipping,
                  'Load Postings Limit',
                  limit == -1 ? 'Unlimited' : '$limit posts',
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  Icons.rocket_launch,
                  'Boost Credits',
                  '$boostCredits credits',
                  Colors.orange,
                ),
                const SizedBox(height: 20),
                // Dates Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Subscription Timeline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (startDate != null)
                        _buildDateRow('Start Date', _formatDate(startDate), Icons.play_circle, Colors.green),
                      if (endDate != null) ...[
                        const SizedBox(height: 8),
                        _buildDateRow('End Date', _formatDate(endDate), Icons.stop_circle, Colors.red),
                      ],
                      if (changedAt != null && !isActive) ...[
                        const SizedBox(height: 8),
                        _buildDateRow('Changed At', _formatDate(changedAt), Icons.swap_horiz, Colors.orange),
                      ],
                      const SizedBox(height: 8),
                      _buildDateRow('Print Date', _formatDate(DateTime.now().toIso8601String()), Icons.print, Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  String _formatReceipt(Map<String, dynamic> subscription, dynamic shipper) {
    final plan = subscription['subscriptionPlan'] ?? 'N/A';
    final price = subscription['subscriptionPrice'] ?? 0;
    final limit = subscription['loadPostingsLimit'] ?? 0;
    final boostCredits = subscription['boostCredits'] ?? 0;
    final startDate = subscription['subscriptionStartDate'];
    final endDate = subscription['subscriptionEndDate'];
    final changedAt = subscription['changedAt'] ?? startDate;
    final status = subscription['status'] == 'active' ? 'Active' : 'Ended';
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('        SUBSCRIPTION RECEIPT');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Company: ${shipper?.companyName ?? 'N/A'}');
    buffer.writeln('Email: ${shipper?.email ?? 'N/A'}');
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Subscription Details:');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Plan: $plan');
    buffer.writeln('Status: $status');
    buffer.writeln('Price: \$$price/month');
    buffer.writeln('Load Postings Limit: ${limit == -1 ? 'Unlimited' : limit}');
    buffer.writeln('Boost Credits: $boostCredits');
    buffer.writeln('');
    if (startDate != null) {
      buffer.writeln('Start Date: ${_formatDate(startDate)}');
    }
    if (endDate != null) {
      buffer.writeln('End Date: ${_formatDate(endDate)}');
    }
    if (changedAt != null && status != 'Active') {
      buffer.writeln('Changed At: ${_formatDate(changedAt)}');
    }
    buffer.writeln('');
    buffer.writeln('Print Date: ${_formatDate(DateTime.now().toIso8601String())}');
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('Thank you for using Remiles!');
    buffer.writeln('═══════════════════════════════════');
    
    return buffer.toString();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _copyReceipt(BuildContext context, String receiptText) {
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, String receiptText, String planName, dynamic shipper) async {
    try {
      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => await _generateReceiptPDF(receiptText, planName, shipper),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateReceiptPDF(String receiptText, String planName, dynamic shipper) async {
    final pdf = pw.Document();
    final lines = receiptText.split('\n');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: lines.map((line) {
              if (line.trim().isEmpty) {
                return pw.SizedBox(height: 8);
              }
              
              // Style headers and separators
              pw.TextStyle textStyle = pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
              );
              
              if (line.contains('════') || line.contains('───')) {
                textStyle = pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                );
              } else if (line.contains('SUBSCRIPTION RECEIPT') || 
                         line.contains('Subscription Details:')) {
                textStyle = pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                );
              } else if (line.contains('Plan:') || 
                         line.contains('Status:') || 
                         line.contains('Price:')) {
                textStyle = pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                );
              }
              
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  line,
                  style: textStyle,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
    
    return pdf.save();
  }

  Future<void> _shareReceipt(BuildContext context, String receiptText, String planName) async {
    try {
      await Share.share(
        receiptText,
        subject: 'Subscription Receipt - $planName',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
