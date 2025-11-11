import 'package:Remiles/modules/shipper_dashboard/pages/shipper_add_payment_method.dart';
import 'package:Remiles/providers/payment_methods_provider.dart';
import 'package:Remiles/core/payment_logo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter; // null means all statuses

  @override
  void initState() {
    super.initState();
    // Load data (uses cache if available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentMethodsProvider>();
      provider.loadPaymentMethods();
      provider.loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _toDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
      await context.read<PaymentMethodsProvider>().loadTransactions(
        forceRefresh: true,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
      await context.read<PaymentMethodsProvider>().loadTransactions(
        forceRefresh: true,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    }
  }

  Future<void> _clearDateFilters() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    await context.read<PaymentMethodsProvider>().loadTransactions(
      forceRefresh: true,
      fromDate: null,
      toDate: null,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTransactionId(String paymentIntentId) {
    // Extract last 4 characters for display
    if (paymentIntentId.length > 4) {
      return 'RM-${paymentIntentId.substring(paymentIntentId.length - 4)}';
    }
    return 'RM-$paymentIntentId';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'canceled':
        return 'Canceled';
      default:
        return 'Unknown';
    }
  }

  List<Map<String, dynamic>> _filterTransactions(List<Map<String, dynamic>> transactions) {
    String searchQuery = _searchController.text.toLowerCase().trim();
    
    return transactions.where((transaction) {
      // Status filter
      if (_statusFilter != null) {
        final status = transaction['status'] as String? ?? 'unknown';
        if (status.toLowerCase() != _statusFilter!.toLowerCase()) {
          return false;
        }
      }
      
      // Search filter
      if (searchQuery.isNotEmpty) {
        final paymentIntentId = transaction['paymentIntentId'] as String? ?? '';
        final transactionId = _formatTransactionId(paymentIntentId).toLowerCase();
        final amount = transaction['amount'] as int? ?? 0;
        final amountStr = (amount ~/ 100).toString();
        final status = _getStatusText(transaction['status'] as String? ?? 'unknown').toLowerCase();
        
        if (!transactionId.contains(searchQuery) &&
            !amountStr.contains(searchQuery) &&
            !status.contains(searchQuery)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    String? selectedFilter = _statusFilter;
    const String cancelSentinel = '__CANCEL__';
    
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: const Text('All'),
                value: null,
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Paid'),
                value: 'succeeded',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Pending'),
                value: 'pending',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Processing'),
                value: 'processing',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Failed'),
                value: 'failed',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
              RadioListTile<String?>(
                title: const Text('Canceled'),
                value: 'canceled',
                groupValue: selectedFilter,
                onChanged: (value) {
                  setDialogState(() {
                    selectedFilter = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, cancelSentinel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedFilter),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    
    // Only update if Apply was clicked (not Cancel)
    // result can be null (for "All") or a status string, but not the cancel sentinel
    if (result != cancelSentinel) {
      setState(() {
        _statusFilter = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<PaymentMethodsProvider>(
          builder: (context, provider, child) {
            final paymentMethods = provider.paymentMethods;
            final allTransactions = provider.transactions;
            final filteredTransactions = _filterTransactions(allTransactions);
            final isLoading = provider.isLoading && paymentMethods.isEmpty && allTransactions.isEmpty;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                              tooltip: 'Back',
                            ),
                            const SizedBox(width: 8),
                  const Text(
                    "Payment Methods",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                            ),
                          ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.person, color: Colors.green, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),

                    /// Payment Methods List
                    if (paymentMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 10),
                            Text(
                              "No payment methods added",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ...paymentMethods.take(1).map((method) {
                        final card = method['card'] as Map<String, dynamic>;
                        final brand = card['brand'] as String? ?? 'visa';
                        final last4 = card['last4'] as String? ?? '0000';
                        final isDefault = method['isDefault'] as bool? ?? false;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDefault ? Colors.green : Colors.grey.shade300,
                              width: isDefault ? 2 : 1,
                            ),
                ),
                child: Row(
                  children: [
                              PaymentLogoService().getLogoWidget(brand, width: 40, height: 40),
                    const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${brand.toUpperCase()} ****$last4',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                    ),
                  ],
                ),
              ),
                            ],
                          ),
                        );
                      }),
              const SizedBox(height: 16),

              /// Add Payment Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                      onPressed: () async {
                        await Navigator.push(
                    context,
                          MaterialPageRoute(
                            builder: (context) => const ShipperAddPaymentMethod(),
                          ),
                  );
                        // Refresh payment methods after returning
                        provider.loadPaymentMethods(forceRefresh: true);
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  "Add Payment Method",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),

              /// Search + Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              ),
                            GestureDetector(
                              onTap: _showFilterDialog,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                'assets/filter_2.svg',
                                fit: BoxFit.scaleDown,
                                  colorFilter: _statusFilter != null
                                      ? const ColorFilter.mode(Colors.blue, BlendMode.srcIn)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 12,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// Transactions Header
                    const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                  Text(
                    "Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(),
                ],
              ),
              const SizedBox(height: 16),

              /// Date Filters
              Row(
                children: [
                  Expanded(
                          child: _buildDateField("From Date", _fromDate, _selectFromDate),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                          child: _buildDateField("To Date", _toDate, _selectToDate),
                  ),
                  if (_fromDate != null || _toDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearDateFilters,
                      tooltip: 'Clear date filters',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              /// Transactions List
                    if (filteredTransactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                allTransactions.isEmpty
                                    ? 'No transactions found'
                                    : 'No transactions match your filters',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredTransactions.map((transaction) {
                        final status = transaction['status'] as String? ?? 'unknown';
                        final amount = transaction['amount'] as int? ?? 0;
                        final date = transaction['createdAt'] as DateTime? ??
                            transaction['succeededAt'] as DateTime? ??
                            transaction['failedAt'] as DateTime;
                        final paymentIntentId = transaction['paymentIntentId'] as String? ?? '';

                        return _buildTransactionCard(
                          _formatTransactionId(paymentIntentId),
                          _formatDate(date),
                          amount ~/ 100, // Convert cents to dollars
                          _getStatusText(status),
                          _getStatusColor(status),
                        );
                      }),
            ],
          ),
              );
          },
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: TextField(
          readOnly: true,
            controller: TextEditingController(
              text: date != null ? DateFormat('MMM dd, yyyy').format(date) : 'dd mm yy',
            ),
          decoration: InputDecoration(
            hintText: "dd mm yy",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
      String id, String date, int amount, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "\$$amount",
                  style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
