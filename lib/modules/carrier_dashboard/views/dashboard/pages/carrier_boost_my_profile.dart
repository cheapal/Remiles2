import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/app_state_provider.dart';
import '../../../../../core/firebase_service.dart';
import '../../../../../core/stripe_service.dart';
import '../../common/widgets/top_navigation_bar.dart';

class CarrierBoostMyProfile extends StatefulWidget {
  const CarrierBoostMyProfile({super.key});

  @override
  State<CarrierBoostMyProfile> createState() => _CarrierBoostMyProfileState();
}

class _CarrierBoostMyProfileState extends State<CarrierBoostMyProfile> {
  String? _activeBoostType; // 'basic', 'premium', 'monthly'
  DateTime? _boostEndDate;
  DateTime? _boostStartDate;
  bool _isLoading = false;
  String? _selectedBoostType;
  String? _selectedCard; // Track which card is currently selected

  @override
  void initState() {
    super.initState();
    _loadCurrentBoost();
  }

  Future<void> _loadCurrentBoost() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      
      if (carrier != null) {
        final carrierDoc = await FirebaseService.carriers.doc(carrier.uid).get();
        
        if (carrierDoc.exists) {
          final data = carrierDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            final boostType = data['profileBoostType'] as String?;
            final boostEndDateStr = data['profileBoostEndDate'] as String?;
            final boostStartDateStr = data['profileBoostStartDate'] as String?;
            
            DateTime? endDate;
            DateTime? startDate;
            
            if (boostEndDateStr != null) {
              try {
                endDate = DateTime.parse(boostEndDateStr);
                // Check if boost is still active
                if (endDate.isBefore(DateTime.now())) {
                  // Boost has expired
                  setState(() {
                    _activeBoostType = null;
                    _boostEndDate = null;
                    _boostStartDate = null;
                  });
                  return;
                }
              } catch (e) {
                debugPrint('Error parsing boost end date: $e');
              }
            }
            
            if (boostStartDateStr != null) {
              try {
                startDate = DateTime.parse(boostStartDateStr);
              } catch (e) {
                debugPrint('Error parsing boost start date: $e');
              }
            }
            
            setState(() {
              _activeBoostType = boostType;
              _boostEndDate = endDate;
              _boostStartDate = startDate;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading current boost: $e');
    }
  }

  String _formatRemainingTime(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    return '${days}d ${hours}h ${minutes}m left';
  }

  double _getProgressPercentage(DateTime endDate) {
    if (_boostStartDate == null) {
      // If we don't have start date, estimate based on boost type duration
      final durationDays = _getBoostDurationDays(_activeBoostType);
      final estimatedStart = endDate.subtract(Duration(days: durationDays));
      return _calculateProgress(estimatedStart, endDate);
    }
    return _calculateProgress(_boostStartDate!, endDate);
  }

  double _calculateProgress(DateTime startDate, DateTime endDate) {
    final now = DateTime.now();
    final total = endDate.difference(startDate).inMilliseconds;
    final elapsed = now.difference(startDate).inMilliseconds;
    
    if (total <= 0) return 0.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  int _getBoostDurationDays(String? boostType) {
    switch (boostType) {
      case 'basic':
        return 3; // 72 hours = 3 days
      case 'premium':
        return 7; // 7 days
      case 'monthly':
        return 30; // 30 days
      default:
        return 0;
    }
  }

  Future<void> _purchaseBoost(String boostType) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _selectedBoostType = boostType;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
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

      // Determine boost details
      int price = 0;
      int durationDays = 0;
      String boostName = '';
      
      switch (boostType) {
        case 'basic':
          price = 999; // $9.99 CAD in cents
          durationDays = 3;
          boostName = 'Basic Boost';
          break;
        case 'premium':
          price = 1999; // $19.99 CAD in cents
          durationDays = 7;
          boostName = 'Premium (Weekly) Boost';
          break;
        case 'monthly':
          price = 4999; // $49.99 CAD in cents
          durationDays = 30;
          boostName = 'Monthly Boost';
          break;
      }

      // Store data before async operations to avoid context issues
      final carrierUid = carrier.uid;
      final carrierEmail = carrier.email;
      
      // Process payment - don't show loading dialog as Stripe sheet will handle UI
      if (!mounted) return;
      
      final paymentSuccess = await StripeService.processPayment(
        amountInCents: price,
        currency: 'cad',
        metadata: {
          'carrier_id': carrierUid,
          'carrier_email': carrierEmail,
          'boost_type': boostType,
          'boost_name': boostName,
          'amount': (price / 100).toString(),
        },
      );

      // Check mounted after async operation
      if (!mounted) return;

      if (!paymentSuccess) {
        if (mounted) {
          setState(() {
            _selectedCard = null; // Clear selection on payment failure
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Calculate boost end date
      final now = DateTime.now();
      final boostEndDate = now.add(Duration(days: durationDays));
      
      // If there's an active boost, extend it
      DateTime finalEndDate = boostEndDate;
      DateTime? previousEndDate;
      if (_activeBoostType != null && _boostEndDate != null && _boostEndDate!.isAfter(now)) {
        // Extend from current end date
        previousEndDate = _boostEndDate;
        finalEndDate = _boostEndDate!.add(Duration(days: durationDays));
      }

      // Check mounted before continuing
      if (!mounted) return;
      
      // Get current boost data to save to history
      final carrierDoc = await FirebaseService.carriers.doc(carrierUid).get();
      final currentData = carrierDoc.data() as Map<String, dynamic>?;
      
      // Prepare history entry from current boost (if exists and different)
      Map<String, dynamic>? historyEntry;
      if (currentData != null && 
          currentData['profileBoostType'] != null &&
          currentData['profileBoostType'] != boostType) {
        // Only save to history if it's different from the new boost
        historyEntry = {
          'boostType': currentData['profileBoostType'],
          'boostName': _getBoostName(currentData['profileBoostType']),
          'price': _getBoostPrice(currentData['profileBoostType']),
          'startDate': currentData['profileBoostStartDate'],
          'endDate': previousEndDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'changedAt': DateTime.now().toIso8601String(),
          'reason': 'boost_change',
        };
      }

      // Update carrier document
      final updates = <String, dynamic>{
        'profileBoostType': boostType,
        'profileBoostEndDate': finalEndDate.toIso8601String(),
        'profileBoostStartDate': now.toIso8601String(),
        'profileBoostLastUpdated': now.toIso8601String(),
      };
      
      if (historyEntry != null) {
        // Get existing history or initialize empty array
        final existingHistory = currentData?['profileBoostHistory'] as List<dynamic>? ?? [];
        
        // Add current boost to history array
        final updatedHistory = List<Map<String, dynamic>>.from(
          existingHistory.map((e) => e as Map<String, dynamic>)
        );
        updatedHistory.add(historyEntry);
        
        // Store updated history
        updates['profileBoostHistory'] = updatedHistory;
      } else if (currentData != null && currentData['profileBoostHistory'] == null) {
        // Initialize empty history array if it doesn't exist
        updates['profileBoostHistory'] = [];
      }
      
      // Check mounted before updating
      if (!mounted) return;
      
      await FirebaseService.updateCarrier(carrierUid, updates);

      // Check mounted before logging
      if (!mounted) return;
      
      // Log analytics
      await FirebaseService.logEvent(
        'carrier_profile_boost_purchased',
        parameters: FirebaseService.convertParameters({
          'boost_type': boostType,
          'boost_name': boostName,
          'amount': price / 100,
          'carrier_id': carrierUid,
        }),
      );

      // Refresh boost data
      await _loadCurrentBoost();

      if (mounted) {
        setState(() {
          _selectedCard = null; // Clear selection after successful purchase
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$boostName activated successfully!'),
            backgroundColor: const Color(0xFF4B744F),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Check mounted before accessing context
      if (!mounted) return;
      
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to purchase boost. Please try again.');
      
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Carrier profile boost purchase failed',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedBoostType = null;
          // Don't clear _selectedCard here - let it clear after success/failure
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: Column(
        children: [
          TopNavigationBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Title with History Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Boost My Profile',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF186230),
                          ),
                        ),
                        IconButton(
                          onPressed: _showSubscriptionHistory,
                          icon: const Icon(
                            Icons.history,
                            color: Color(0xFF186230),
                            size: 28,
                          ),
                          tooltip: 'View Boost History',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Remaining Time Section
                    if (_activeBoostType != null && _boostEndDate != null)
                      _buildRemainingTimeSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Basic Boost Card
                    _buildBoostCard(
                      boostType: 'basic',
                      title: 'Basic Boost',
                      duration: '72 hrs',
                      benefit: 'Get 3X more visibility',
                      price: '\$9.99 CAD',
                      isActive: _activeBoostType == 'basic',
                      isSelected: _selectedCard == 'basic',
                      onTap: () {
                        setState(() {
                          _selectedCard = 'basic';
                        });
                        _purchaseBoost('basic');
                      },
                      isLoading: _isLoading && _selectedBoostType == 'basic',
                    ),
                    const SizedBox(height: 16),
                    
                    // Premium Boost Card
                    _buildBoostCard(
                      boostType: 'premium',
                      title: 'Premium (Weekly) Boost',
                      duration: '7 Days',
                      benefit: 'Be seen first by shippers',
                      price: '\$19.99 CAD',
                      isActive: _activeBoostType == 'premium',
                      isSelected: _selectedCard == 'premium',
                      onTap: () {
                        setState(() {
                          _selectedCard = 'premium';
                        });
                        _purchaseBoost('premium');
                      },
                      isLoading: _isLoading && _selectedBoostType == 'premium',
                    ),
                    const SizedBox(height: 16),
                    
                    // Monthly Boost Card
                    _buildBoostCard(
                      boostType: 'monthly',
                      title: 'Monthly Boost',
                      duration: '30 days',
                      benefit: 'Save 20% with monthly',
                      price: '\$49.99 CAD',
                      originalPrice: '\$58.99 CAD',
                      isActive: _activeBoostType == 'monthly',
                      isSelected: _selectedCard == 'monthly',
                      onTap: () {
                        setState(() {
                          _selectedCard = 'monthly';
                        });
                        _purchaseBoost('monthly');
                      },
                      isLoading: _isLoading && _selectedBoostType == 'monthly',
                    ),
                    const SizedBox(height: 30),
                    
                    // Extend Boost Button
                    if (_activeBoostType != null && _boostEndDate != null && _boostEndDate!.isAfter(DateTime.now()))
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43975A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _isLoading ? null : () {
                          // Show dialog to select boost to extend with
                          _showExtendBoostDialog();
                        },
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
                                'Extend Boost',
                                style: TextStyle(
                                  fontSize: 18,
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

  Widget _buildRemainingTimeSection() {
    if (_boostEndDate == null) return const SizedBox.shrink();
    
    final remainingTime = _formatRemainingTime(_boostEndDate!);
    final progress = _getProgressPercentage(_boostEndDate!);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF43975A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Remaining Time',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF186230),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 16, color: Color(0xFF186230)),
              const Spacer(),
              Text(
                remainingTime,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF186230),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF43975A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostCard({
    required String boostType,
    required String title,
    required String duration,
    required String benefit,
    required String price,
    String? originalPrice,
    required bool isActive,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    // Determine card background color based on state
    Color cardBackgroundColor;
    if (isSelected) {
      cardBackgroundColor = const Color(0xFF43975A).withOpacity(0.1);
    } else if (isActive) {
      cardBackgroundColor = const Color(0xFF43975A).withOpacity(0.08);
    } else {
      cardBackgroundColor = Colors.white;
    }

    // Determine border color and width
    Color borderColor;
    double borderWidth;
    if (isSelected) {
      borderColor = const Color(0xFF43975A);
      borderWidth = 3;
    } else if (isActive) {
      borderColor = const Color(0xFF43975A);
      borderWidth = 2;
    } else {
      borderColor = const Color(0xFF43975A).withOpacity(0.3);
      borderWidth = 2;
    }

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF43975A).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF186230),
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF43975A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Currently Active',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  benefit,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (originalPrice != null) ...[
                      Text(
                        originalPrice,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      price,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF186230),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43975A)),
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

  void _showExtendBoostDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Extend Boost',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF186230),
            ),
          ),
          content: const Text(
            'Select a boost option to extend your current boost:',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _purchaseBoost('basic');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Basic Boost',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF186230),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _purchaseBoost('premium');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Premium Boost',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF186230),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _purchaseBoost('monthly');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Monthly Boost',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF186230),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getBoostName(String? boostType) {
    switch (boostType) {
      case 'basic':
        return 'Basic Boost';
      case 'premium':
        return 'Premium (Weekly) Boost';
      case 'monthly':
        return 'Monthly Boost';
      default:
        return 'Unknown Boost';
    }
  }

  int _getBoostPrice(String? boostType) {
    switch (boostType) {
      case 'basic':
        return 999; // $9.99 in cents
      case 'premium':
        return 1999; // $19.99 in cents
      case 'monthly':
        return 4999; // $49.99 in cents
      default:
        return 0;
    }
  }

  Future<void> _showSubscriptionHistory() async {
    final authProvider = context.read<AuthProvider>();
    final carrier = authProvider.carrierUser;
    
    // Reload fresh data from Firestore to ensure history is up to date
    Map<String, dynamic>? currentBoost;
    List<Map<String, dynamic>> boostHistory = [];
    
    if (carrier != null) {
      try {
        final carrierDoc = await FirebaseService.carriers.doc(carrier.uid).get();
        if (carrierDoc.exists) {
          final data = carrierDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            // Get current active boost
            if (data['profileBoostType'] != null && 
                data['profileBoostEndDate'] != null) {
              final endDateStr = data['profileBoostEndDate'] as String;
              final endDate = DateTime.parse(endDateStr);
              
              // Only show as active if not expired
              if (endDate.isAfter(DateTime.now())) {
                currentBoost = {
                  'boostType': data['profileBoostType'],
                  'boostName': _getBoostName(data['profileBoostType']),
                  'price': _getBoostPrice(data['profileBoostType']),
                  'startDate': data['profileBoostStartDate'],
                  'endDate': data['profileBoostEndDate'],
                  'status': 'active',
                };
              }
            }
            
            // Get fresh boost history from Firestore
            final history = data['profileBoostHistory'] as List<dynamic>?;
            if (history != null) {
              boostHistory = List<Map<String, dynamic>>.from(
                history.map((e) => e as Map<String, dynamic>)
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading boost history: $e');
      }
    }
    
    // Combine current with history (newest first)
    final allBoosts = <Map<String, dynamic>>[];
    if (currentBoost != null) {
      allBoosts.add(currentBoost);
    }
    allBoosts.addAll(boostHistory.reversed);
    
    // Navigate to full screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CarrierBoostHistoryScreen(
          boosts: allBoosts,
          carrier: carrier,
        ),
      ),
    );
  }
}

// Full Screen Boost History Screen for Carriers
class CarrierBoostHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> boosts;
  final dynamic carrier;

  const CarrierBoostHistoryScreen({
    super.key,
    required this.boosts,
    required this.carrier,
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
                      Icon(Icons.history, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Boost History',
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
            child: boosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No boost history available',
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
                      itemCount: boosts.length,
                      itemBuilder: (context, index) {
                        final boost = boosts[index];
                        final isActive = boost['status'] == 'active';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHistoryItem(context, boost, isActive, carrier),
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
    Map<String, dynamic> boost,
    bool isActive,
    dynamic carrier,
  ) {
    final boostName = boost['boostName'] ?? 'N/A';
    final price = boost['price'] ?? 0;
    final startDate = boost['startDate'];
    final endDate = boost['endDate'];
    final changedAt = boost['changedAt'] ?? startDate;
    final status = isActive ? 'Active' : 'Ended';
    
    final receiptText = _formatReceipt(boost, carrier);
    
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
                            isActive ? Icons.rocket_launch : Icons.history,
                            color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              boostName,
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
                // Action buttons
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
                        onPressed: () => _printReceipt(context, receiptText, boostName, carrier),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        color: Colors.orange,
                        onPressed: () => _shareReceipt(context, receiptText, boostName),
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
                            'Boost Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${(price / 100).toStringAsFixed(2)} CAD',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                            'Boost Timeline',
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

  String _formatReceipt(Map<String, dynamic> boost, dynamic carrier) {
    final boostName = boost['boostName'] ?? 'N/A';
    final price = boost['price'] ?? 0;
    final startDate = boost['startDate'];
    final endDate = boost['endDate'];
    final changedAt = boost['changedAt'] ?? startDate;
    final status = boost['status'] == 'active' ? 'Active' : 'Ended';
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('        BOOST RECEIPT');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Company: ${carrier?.companyName ?? 'N/A'}');
    buffer.writeln('Email: ${carrier?.email ?? 'N/A'}');
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Boost Details:');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Boost: $boostName');
    buffer.writeln('Status: $status');
    buffer.writeln('Price: \$${(price / 100).toStringAsFixed(2)} CAD');
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

  Future<void> _printReceipt(BuildContext context, String receiptText, String boostName, dynamic carrier) async {
    try {
      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (format) async => await _generateReceiptPDF(receiptText, boostName, carrier),
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

  Future<Uint8List> _generateReceiptPDF(String receiptText, String boostName, dynamic carrier) async {
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
              } else if (line.contains('BOOST RECEIPT') || 
                         line.contains('Boost Details:')) {
                textStyle = pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                );
              } else if (line.contains('Boost:') || 
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

  Future<void> _shareReceipt(BuildContext context, String receiptText, String boostName) async {
    try {
      await Share.share(
        receiptText,
        subject: 'Boost Receipt - $boostName',
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

