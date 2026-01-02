import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';
import '../../../core/stripe_service.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ShipperBoostMyPage extends StatefulWidget {
  const ShipperBoostMyPage({super.key});

  @override
  State<ShipperBoostMyPage> createState() => _ShipperBoostMyPageState();
}

class _ShipperBoostMyPageState extends State<ShipperBoostMyPage> {
  String selectedPlan = ""; // Plan user is clicking on to select
  String activePlan =
      ""; // Plan user is actually subscribed to (from Firestore)
  bool _isLoading = false;
  int _usedPosts = 0;
  int _postLimit = 10; // Default limit
  List<Map<String, dynamic>> _subscriptionHistory = [];
  DateTime? _renewalDate; // Renewal date for active plan

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
        final shipperDoc = await FirebaseService.shippers
            .doc(shipper.uid)
            .get();

        Map<String, dynamic>? currentData;
        if (shipperDoc.exists) {
          currentData = shipperDoc.data() as Map<String, dynamic>?;
          if (currentData != null) {
            // Load subscription plan
            if (currentData['subscriptionPlan'] != null) {
              final planName = currentData['subscriptionPlan'] as String;
              setState(() {
                activePlan = planName; // This is the actual active subscription
                // Only set selectedPlan if user hasn't manually selected a different plan
                if (selectedPlan.isEmpty) {
                  selectedPlan = planName;
                }
              });

              // Load renewal date for active plan
              if (currentData['renewalDate'] != null) {
                try {
                  final renewalDateStr = currentData['renewalDate'] as String;
                  setState(() {
                    _renewalDate = DateTime.parse(renewalDateStr);
                  });
                } catch (e) {
                  debugPrint('Error parsing renewal date: $e');
                  setState(() {
                    _renewalDate = null;
                  });
                }
              } else {
                setState(() {
                  _renewalDate = null;
                });
              }
            } else {
              // No plan subscribed, set to empty
              setState(() {
                activePlan = "";
                _renewalDate = null;
              });
            }

            // Load post limit from subscription
            final loadPostingsLimit = currentData['loadPostingsLimit'];
            if (loadPostingsLimit != null) {
              setState(() {
                _postLimit = loadPostingsLimit is int
                    ? loadPostingsLimit
                    : int.tryParse(loadPostingsLimit.toString()) ?? 10;
              });
            }
          }
        }

        // Load posts used this period (reset on subscription/renewal/upgrade)
        // If not available, fall back to total count
        int usedPosts = 0;
        if (currentData != null && currentData['postsUsedThisPeriod'] != null) {
          usedPosts = currentData['postsUsedThisPeriod'] is int
              ? currentData['postsUsedThisPeriod']
              : int.tryParse(currentData['postsUsedThisPeriod'].toString()) ??
                    0;
        } else {
          // Fallback to total count if postsUsedThisPeriod not set
          final loadStats = await FirebaseService.getShipperLoadStats(
            shipper.uid,
          );
          usedPosts = loadStats['total'] ?? 0;
        }

        // Load subscription history
        final history = currentData?['subscriptionHistory'] as List<dynamic>?;
        final historyList = history != null
            ? List<Map<String, dynamic>>.from(
                history.map((e) => e as Map<String, dynamic>),
              )
            : <Map<String, dynamic>>[];

        setState(() {
          _usedPosts = usedPosts;
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
        setState(() => _isLoading = false);
        return;
      }

      // Determine plan details based on selected plan
      Map<String, dynamic> planData = {};
      int planPrice = 0;
      switch (selectedPlan) {
        case "Starter Bundle":
          planPrice = 99;
          planData = {
            'subscriptionPlan': 'Starter Bundle',
            'subscriptionPrice': 99,
            'loadPostingsLimit': 10,
            'boostCredits': 1,
            'subscriptionType': 'monthly',
          };
          break;
        case "Pro Bundle":
          planPrice = 249;
          planData = {
            'subscriptionPlan': 'Pro Bundle',
            'subscriptionPrice': 249,
            'loadPostingsLimit': 25,
            'boostCredits': 5,
            'subscriptionType': 'monthly',
          };
          break;
        case "Enterprise Bundle":
          planPrice = 449;
          planData = {
            'subscriptionPlan': 'Enterprise Bundle',
            'subscriptionPrice': 449,
            'loadPostingsLimit': -1, // -1 for unlimited
            'boostCredits': 10,
            'subscriptionType': 'monthly',
          };
          break;
      }

      // Process payment with Stripe before saving plan
      if (mounted) {
        final paymentConfirmed = await _processPayment(
          amount: planPrice,
          planName: selectedPlan,
          shipper: shipper,
        );

        if (!paymentConfirmed) {
          setState(() => _isLoading = false);
          return; // Payment was canceled or failed
        }
      }

      // Calculate subscription dates
      final now = DateTime.now();
      final subscriptionStartDate = now;
      // Monthly subscription - add 1 month for end date (handles year overflow)
      final subscriptionEndDate = DateTime(now.year, now.month + 1, now.day);
      final renewalDate =
          subscriptionEndDate; // Renewal is same as end date for monthly

      // Add subscription dates
      planData['subscriptionStartDate'] = subscriptionStartDate
          .toIso8601String();
      planData['subscriptionEndDate'] = subscriptionEndDate.toIso8601String();
      planData['renewalDate'] = renewalDate.toIso8601String();
      planData['subscriptionUpdatedAt'] = now.toIso8601String();
      planData['paymentStatus'] = 'paid';
      planData['paymentDate'] = now.toIso8601String();

      // Reset posts counter for new subscription period
      planData['postsUsedThisPeriod'] = 0;

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
          'subscriptionEndDate': DateTime.now()
              .toIso8601String(), // When it ended
          'changedAt': DateTime.now().toIso8601String(),
          'reason': 'plan_change', // Reason for change
        };
      }

      // Update shipper document with new plan and add to history
      final updates = Map<String, dynamic>.from(planData);

      if (historyEntry != null) {
        // Get existing history or initialize empty array
        final existingHistory =
            currentData?['subscriptionHistory'] as List<dynamic>? ?? [];

        // Add current subscription to history array (avoid duplicates)
        final updatedHistory = List<Map<String, dynamic>>.from(
          existingHistory.map((e) => e as Map<String, dynamic>),
        );
        updatedHistory.add(historyEntry);

        // Store updated history
        updates['subscriptionHistory'] = updatedHistory;
      } else if (currentData != null &&
          currentData['subscriptionHistory'] == null) {
        // Initialize empty history array if it doesn't exist
        updates['subscriptionHistory'] = [];
      }

      await FirebaseService.updateShipper(shipper.uid, updates);

      // Update activePlan immediately after successful save
      setState(() {
        activePlan = selectedPlan;
      });

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
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.black, // ✅ Black text
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          onPressed: _showSubscriptionHistory,
                          icon: const Icon(
                            Icons.history,
                            color: Color(0xFF195529),
                            size: 28,
                          ),
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
                      renewal:
                          activePlan == "Starter Bundle" && _renewalDate != null
                          ? _formatRenewalDate(_renewalDate!)
                          : null,
                      selected: selectedPlan == "Starter Bundle",
                      isActive: activePlan == "Starter Bundle",
                      onTap: () {
                        setState(() {
                          selectedPlan = "Starter Bundle";
                          _postLimit = 10;
                        });
                      },
                      onCancel: activePlan == "Starter Bundle"
                          ? _showCancelPlanDialog
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Pro Bundle
                    _planCard(
                      title: "Pro Bundle",
                      price: "\$249/month",
                      details: ["25 Load Postings + 5 Boost Credits"],
                      tag: "Best Value",
                      renewal:
                          activePlan == "Pro Bundle" && _renewalDate != null
                          ? _formatRenewalDate(_renewalDate!)
                          : null,
                      selected: selectedPlan == "Pro Bundle",
                      isActive: activePlan == "Pro Bundle",
                      onTap: () {
                        setState(() {
                          selectedPlan = "Pro Bundle";
                          _postLimit = 25;
                        });
                      },
                      onCancel: activePlan == "Pro Bundle"
                          ? _showCancelPlanDialog
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Enterprise Bundle
                    _planCard(
                      title: "Enterprise Bundle",
                      price: "\$449/month",
                      details: ["Unlimited Load Postings + 10 Boost Credits"],
                      renewal:
                          activePlan == "Enterprise Bundle" &&
                              _renewalDate != null
                          ? _formatRenewalDate(_renewalDate!)
                          : null,
                      selected: selectedPlan == "Enterprise Bundle",
                      isActive: activePlan == "Enterprise Bundle",
                      onTap: () {
                        setState(() {
                          selectedPlan = "Enterprise Bundle";
                          _postLimit = -1; // Unlimited
                        });
                      },
                      onCancel: activePlan == "Enterprise Bundle"
                          ? _showCancelPlanDialog
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // Upgrade Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_isLoading ||
                                (activePlan.isNotEmpty &&
                                    selectedPlan == activePlan))
                            ? Colors.grey
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          (_isLoading ||
                              (activePlan.isNotEmpty &&
                                  selectedPlan == activePlan))
                          ? null
                          : _savePlan,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              activePlan.isNotEmpty &&
                                      selectedPlan == activePlan
                                  ? "This is your active plan"
                                  : "Upgrade My Plan",
                              style: const TextStyle(
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

    // Reload fresh data from Firestore to ensure history is up to date
    Map<String, dynamic>? currentSubscription;
    List<Map<String, dynamic>> subscriptionHistory = [];

    if (shipper != null) {
      try {
        final shipperDoc = await FirebaseService.shippers
            .doc(shipper.uid)
            .get();
        if (shipperDoc.exists) {
          final data = shipperDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            // Get current active subscription
            if (data['subscriptionPlan'] != null) {
              currentSubscription = {
                'subscriptionPlan': data['subscriptionPlan'],
                'subscriptionPrice':
                    data['subscriptionPrice'] ?? _getPlanPrice(activePlan),
                'loadPostingsLimit': data['loadPostingsLimit'] ?? _postLimit,
                'boostCredits':
                    data['boostCredits'] ?? _getPlanBoostCredits(activePlan),
                'subscriptionType': data['subscriptionType'] ?? 'monthly',
                'subscriptionStartDate': data['subscriptionStartDate'],
                'subscriptionEndDate': data['subscriptionEndDate'],
                'renewalDate': data['renewalDate'],
                'status': 'active',
              };
            }

            // Get fresh subscription history from Firestore
            final history = data['subscriptionHistory'] as List<dynamic>?;
            if (history != null) {
              subscriptionHistory = List<Map<String, dynamic>>.from(
                history.map((e) => e as Map<String, dynamic>),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading subscription history: $e');
      }
    }

    // Combine current with history (newest first)
    final allSubscriptions = <Map<String, dynamic>>[];
    if (currentSubscription != null) {
      allSubscriptions.add(currentSubscription);
    }
    allSubscriptions.addAll(subscriptionHistory.reversed);

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
      height: 110, // Fixed height to prevent UI shifts
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // ✅ Light card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Remaining Posts",
            style: TextStyle(color: Colors.black, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    bool isActive =
        false, // True only if this is the actual active subscription
    required VoidCallback onTap,
    VoidCallback? onCancel, // Cancel subscription callback
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF195529).withOpacity(
                  0.08,
                ) // Primary color tint for active plan
              : Colors.grey.shade200, // ✅ Light card for inactive plans
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(
                    0xFF195529,
                  ) // Primary color border for active plan
                : (selected
                      ? Colors.green.withOpacity(0.6)
                      : Colors.grey.withOpacity(
                          0.3,
                        )), // Border for selected (clicked) plan
            width: 2, // Fixed width to prevent resizing
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Active Plan Chip - ONLY show for actually active plan
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isActive
                          ? Container(
                              key: const ValueKey('active-chip'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF195529),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Active Plan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('empty-chip'),
                              width: 0,
                              height: 0,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                const SizedBox(height: 6),
                ...details
                    .map(
                      (e) => Text(
                        e,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                    .toList(),
                if (renewal != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF195529).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF195529).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.autorenew,
                          size: 16,
                          color: Color(0xFF195529),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Renewal Date: $renewal",
                          style: const TextStyle(
                            color: Color(0xFF195529),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Cancel Subscription Button - only for active plan
                if (isActive && onCancel != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.red.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Cancel Subscription',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Best Value Tag
            if (tag != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  /// Format renewal date for display (e.g., "Sept 30, 2025")
  String _formatRenewalDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Process payment using Stripe
  Future<bool> _processPayment({
    required int amount,
    required String planName,
    required dynamic shipper,
  }) async {
    try {
      // Show payment processing dialog
      if (!mounted) return false;

      // Show payment method selection dialog
      final paymentMethod = await _showPaymentMethodDialog();
      if (paymentMethod == null) {
        return false; // User canceled
      }

      // Convert amount to cents for Stripe
      final amountInCents = amount * 100;

      // Prepare payment metadata
      final metadata = {
        'shipper_id': shipper.uid,
        'shipper_email': shipper.email ?? 'N/A',
        'plan_name': planName,
        'amount': amount.toString(),
        'subscription_type': 'monthly',
      };

      // Process payment
      bool paymentSuccess = false;

      if (kIsWeb) {
        // Web Payment Flow
        final clientSecret = await StripeService.createPaymentIntent(
          amountInCents: amountInCents,
          currency: 'cad',
          metadata: metadata,
        );

        if (!mounted) return false;

        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => WebPurchaseDialog(
            clientSecret: clientSecret,
            amount: amount,
            planName: planName,
          ),
        );

        paymentSuccess = result ?? false;
      } else {
        // Native Payment Flow
        paymentSuccess = await StripeService.processPayment(
          amountInCents: amountInCents,
          currency: 'cad',
          metadata: metadata,
        );
      }

      if (paymentSuccess) {
        // Log analytics event for successful subscription upgrade
        await FirebaseService.logEvent(
          'subscription_upgrade_success',
          parameters: FirebaseService.convertParameters({
            'plan_name': planName,
            'amount': amount,
            'shipper_id': shipper.uid,
          }),
        );

        if (mounted) {
          // Get subscription dates from planData (calculated in _savePlan)
          final now = DateTime.now();
          final subscriptionEndDate = DateTime(
            now.year,
            now.month + 1,
            now.day,
          );
          await _showPaymentSuccessDialog(
            planName: planName,
            amount: amount,
            startDate: now,
            endDate: subscriptionEndDate,
            renewalDate: subscriptionEndDate,
          );
        }
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      // Log payment errors to Crashlytics
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Payment processing failed in shipper_boost_my_page',
      );
      await FirebaseService.log(
        'Payment Failed - Plan: $planName, Amount: \$$amount',
      );
      await FirebaseService.setCustomKey('payment_plan', planName);
      await FirebaseService.setCustomKey('payment_amount', amount);

      // Log analytics event for subscription upgrade failure
      final errorMessage = StripeService.getErrorMessage(e);
      await FirebaseService.logEvent(
        'subscription_upgrade_failed',
        parameters: FirebaseService.convertParameters({
          'plan_name': planName,
          'amount': amount,
          'shipper_id': shipper.uid,
          'error_message': errorMessage.length > 100
              ? errorMessage.substring(0, 100)
              : errorMessage,
        }),
      );

      if (mounted) {
        // Calculate renewal date for failure dialog
        final now = DateTime.now();
        final renewalDate = DateTime(now.year, now.month + 1, now.day);
        await _showPaymentFailureDialog(
          planName: planName,
          amount: amount,
          errorMessage: errorMessage,
          shipper: shipper,
          renewalDate: renewalDate,
        );
      }
      return false;
    }
  }

  /// Show payment method selection dialog
  Future<String?> _showPaymentMethodDialog() async {
    // For now, directly proceed with Payment Sheet
    // In the future, you can add more payment methods here
    return 'payment_sheet';
  }

  /// Show cancel plan confirmation dialog
  Future<void> _showCancelPlanDialog() async {
    final authProvider = context.read<AuthProvider>();
    final shipper = authProvider.shipperUser;

    if (shipper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current subscription details
    final shipperDoc = await FirebaseService.shippers.doc(shipper.uid).get();
    final currentData = shipperDoc.data() as Map<String, dynamic>?;
    final currentPlan =
        currentData?['subscriptionPlan'] as String? ?? selectedPlan;
    final endDateStr = currentData?['subscriptionEndDate'] as String?;
    DateTime? endDate;
    if (endDateStr != null) {
      try {
        endDate = DateTime.parse(endDateStr);
      } catch (e) {
        debugPrint('Error parsing end date: $e');
      }
    }

    // Format date for display
    String formatDate(DateTime date) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sept',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6CA78A).withOpacity(0.2),
                  blurRadius: 13.4,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.36),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Cancel Subscription',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF195529),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subscription details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCancelDetailRow(
                        icon: Icons.workspace_premium,
                        label: 'Current Plan',
                        value: currentPlan,
                        iconColor: const Color(0xFFE53935),
                        labelColor: const Color(0xFFE53935),
                      ),
                      if (endDate != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFD9D9D9)),
                        const SizedBox(height: 12),
                        _buildCancelDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Active Until',
                          value: formatDate(endDate),
                          iconColor: const Color(0xFFE53935),
                          labelColor: const Color(0xFFE53935),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Warning message container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFE53935),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Important Notice',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              endDate != null
                                  ? 'Your subscription will remain active until ${formatDate(endDate)}. After this date, you will lose access to all premium features and benefits.'
                                  : 'Cancelling will immediately revoke access to all premium features and benefits.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE53935),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Column(
                  children: [
                    // Cancel Subscription button (primary action - red)
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFC62828)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC62828).withOpacity(0.36),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _cancelPlan(shipper);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Subscription',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Keep Subscription button (secondary action)
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF195529).withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF195529).withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF195529),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Keep My Subscription',
                                  style: TextStyle(
                                    color: Color(0xFF195529),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a detail row for the cancel dialog
  Widget _buildCancelDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? labelColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? const Color(0xFFE53935)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: labelColor ?? const Color(0xFFE53935),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: labelColor ?? const Color(0xFFE53935),
          ),
        ),
      ],
    );
  }

  /// Cancel the current subscription plan
  Future<void> _cancelPlan(dynamic shipper) async {
    try {
      setState(() => _isLoading = true);

      // Get current subscription data to save to history
      final shipperDoc = await FirebaseService.shippers.doc(shipper.uid).get();
      final currentData = shipperDoc.data() as Map<String, dynamic>?;

      // Prepare history entry for canceled subscription
      Map<String, dynamic>? historyEntry;
      if (currentData != null && currentData['subscriptionPlan'] != null) {
        historyEntry = {
          'subscriptionPlan': currentData['subscriptionPlan'],
          'subscriptionPrice': currentData['subscriptionPrice'] ?? 0,
          'loadPostingsLimit': currentData['loadPostingsLimit'] ?? 0,
          'boostCredits': currentData['boostCredits'] ?? 0,
          'subscriptionType': currentData['subscriptionType'] ?? 'monthly',
          'subscriptionStartDate': currentData['subscriptionStartDate'],
          'subscriptionEndDate': DateTime.now()
              .toIso8601String(), // Cancellation date
          'changedAt': DateTime.now().toIso8601String(),
          'reason': 'cancelled', // Reason for cancellation
        };
      }

      // Update shipper document - remove subscription but keep history
      final updates = <String, dynamic>{
        'subscriptionPlan': null,
        'subscriptionPrice': null,
        'loadPostingsLimit': null,
        'boostCredits': null,
        'subscriptionType': null,
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'renewalDate': null,
        'paymentStatus': 'cancelled',
        'subscriptionUpdatedAt': DateTime.now().toIso8601String(),
      };

      if (historyEntry != null) {
        // Get existing history or initialize empty array
        final existingHistory =
            currentData?['subscriptionHistory'] as List<dynamic>? ?? [];

        // Add canceled subscription to history
        final updatedHistory = List<Map<String, dynamic>>.from(
          existingHistory.map((e) => e as Map<String, dynamic>),
        );
        updatedHistory.add(historyEntry);

        // Store updated history
        updates['subscriptionHistory'] = updatedHistory;
      } else if (currentData != null &&
          currentData['subscriptionHistory'] == null) {
        // Initialize empty history array if it doesn't exist
        updates['subscriptionHistory'] = [];
      }

      await FirebaseService.updateShipper(shipper.uid, updates);

      // Update activePlan immediately after cancellation
      setState(() {
        activePlan = "";
      });

      // Log analytics event
      await FirebaseService.logEvent(
        'subscription_cancelled',
        parameters: FirebaseService.convertParameters({
          'plan_name': currentData?['subscriptionPlan'] ?? 'unknown',
          'shipper_id': shipper.uid,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        // Reload plan data
        await _loadCurrentPlan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel subscription: ${e.toString()}'),
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

  /// Show payment success dialog with beautiful design inspired by shipper_intransit_orders
  Future<void> _showPaymentSuccessDialog({
    required String planName,
    required int amount,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime renewalDate,
  }) async {
    // Format dates for display
    String formatDate(DateTime date) {
      return '${date.month}/${date.day}/${date.year}';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6CA78A).withOpacity(0.2),
                  blurRadius: 13.4,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF195529)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF195529).withOpacity(0.36),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),

                // Success title
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF195529),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Payment details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF195529).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPaymentDetailRow(
                        icon: Icons.workspace_premium,
                        label: 'Plan',
                        value: planName,
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.attach_money,
                        label: 'Amount',
                        value: '\$$amount',
                        valueColor: const Color(0xFFCEB838),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Billing',
                        value: 'Monthly',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.play_arrow,
                        label: 'Start Date',
                        value: formatDate(startDate),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.stop,
                        label: 'End Date',
                        value: formatDate(endDate),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.autorenew,
                        label: 'Renewal Date',
                        value: formatDate(renewalDate),
                        valueColor: const Color(0xFF195529),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Success message
                Text(
                  'Your subscription has been upgraded successfully. You can now enjoy all the premium features!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Done button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF195529)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF195529).withOpacity(0.36),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show payment failure dialog with beautiful design inspired by shipper_intransit_orders
  Future<void> _showPaymentFailureDialog({
    required String planName,
    required int amount,
    required String errorMessage,
    required dynamic shipper,
    required DateTime renewalDate,
  }) async {
    // Format dates for display
    String formatDate(DateTime date) {
      return '${date.month}/${date.day}/${date.year}';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6CA78A).withOpacity(0.2),
                  blurRadius: 13.4,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC62828).withOpacity(0.36),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),

                // Failure title
                const Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC62828),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Payment details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC62828).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPaymentDetailRow(
                        icon: Icons.workspace_premium,
                        label: 'Plan',
                        value: planName,
                        iconColor: const Color(0xFFC62828),
                        labelColor: const Color(0xFFC62828),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.attach_money,
                        label: 'Amount',
                        value: '\$$amount',
                        valueColor: const Color(0xFFCEB838),
                        iconColor: const Color(0xFFC62828),
                        labelColor: const Color(0xFFC62828),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD9D9D9)),
                      const SizedBox(height: 12),
                      _buildPaymentDetailRow(
                        icon: Icons.autorenew,
                        label: 'Renewal Date',
                        value: formatDate(renewalDate),
                        iconColor: const Color(0xFFC62828),
                        labelColor: const Color(0xFFC62828),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error message container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC62828).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFC62828),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage.length > 150
                              ? '${errorMessage.substring(0, 150)}...'
                              : errorMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC62828),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Helpful message
                Text(
                  'Please check your payment method and try again. If the problem persists, contact support.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Retry and Cancel buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC62828).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC62828).withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Retry button
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFC62828)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC62828).withOpacity(0.36),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              // Retry payment by calling _processPayment again
                              _processPayment(
                                amount: amount,
                                planName: planName,
                                shipper: shipper,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: const Center(
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a payment detail row for the success dialog
  Widget _buildPaymentDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor,
    Color? labelColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? const Color(0xFF195529)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: labelColor ?? const Color(0xFF195529),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF195529),
          ),
        ),
      ],
    );
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
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
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
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
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
                    decoration: BoxDecoration(color: Colors.grey.shade50),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = subscriptions[index];
                        final isActive = subscription['status'] == 'active';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHistoryItem(
                            context,
                            subscription,
                            isActive,
                            shipper,
                          ),
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
                            color: isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plan,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.green.shade900
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
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
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _buildActionButton(
                        icon: Icons.print,
                        label: 'Print',
                        color: Colors.green,
                        onPressed: () =>
                            _printReceipt(context, receiptText, plan, shipper),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        color: Colors.orange,
                        onPressed: () =>
                            _shareReceipt(context, receiptText, plan),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
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
                        _buildDateRow(
                          'Start Date',
                          _formatDate(startDate),
                          Icons.play_circle,
                          Colors.green,
                        ),
                      if (endDate != null) ...[
                        const SizedBox(height: 8),
                        _buildDateRow(
                          'End Date',
                          _formatDate(endDate),
                          Icons.stop_circle,
                          Colors.red,
                        ),
                      ],
                      if (changedAt != null && !isActive) ...[
                        const SizedBox(height: 8),
                        _buildDateRow(
                          'Changed At',
                          _formatDate(changedAt),
                          Icons.swap_horiz,
                          Colors.orange,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildDateRow(
                        'Print Date',
                        _formatDate(DateTime.now().toIso8601String()),
                        Icons.print,
                        Colors.blue,
                      ),
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

  Widget _buildFeatureRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
    buffer.writeln(
      'Print Date: ${_formatDate(DateTime.now().toIso8601String())}',
    );
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

  Future<void> _printReceipt(
    BuildContext context,
    String receiptText,
    String planName,
    dynamic shipper,
  ) async {
    try {
      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (format) async =>
            await _generateReceiptPDF(receiptText, planName, shipper),
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

  Future<Uint8List> _generateReceiptPDF(
    String receiptText,
    String planName,
    dynamic shipper,
  ) async {
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
                textStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey);
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
                child: pw.Text(line, style: textStyle),
              );
            }).toList(),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _shareReceipt(
    BuildContext context,
    String receiptText,
    String planName,
  ) async {
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

class WebPurchaseDialog extends StatefulWidget {
  final String clientSecret;
  final int amount;
  final String planName;

  const WebPurchaseDialog({
    super.key,
    required this.clientSecret,
    required this.amount,
    required this.planName,
  });

  @override
  State<WebPurchaseDialog> createState() => _WebPurchaseDialogState();
}

class _WebPurchaseDialogState extends State<WebPurchaseDialog> {
  bool _isComplete = false;
  bool _isLoading = false;

  Future<void> _handlePay() async {
    setState(() => _isLoading = true);
    try {
      await StripeService.confirmWebPayment(widget.clientSecret);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pay \$${widget.amount}'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchasing: ${widget.planName}'),
            const SizedBox(height: 20),
            const Text('Enter your card details securely via Stripe.'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: CardField(
                onCardChanged: (details) {
                  setState(() {
                    _isComplete = details?.complete ?? false;
                  });
                },
                style: const TextStyle(fontSize: 16, color: Colors.black),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isComplete && !_isLoading) ? _handlePay : null,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Pay Now'),
        ),
      ],
    );
  }
}
