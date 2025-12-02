import 'package:Remiles/modules/shipper_dashboard/pages/shipper_add_payment_method.dart';
import 'package:Remiles/providers/payment_methods_provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:Remiles/core/payment_logo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    // Unfocus any text fields before showing picker
    FocusScope.of(context).unfocus();
    
    final initialDate = _fromDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: _toDate ?? DateTime.now(),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final picked = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
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
  }

  Future<void> _selectToDate() async {
    // Unfocus any text fields before showing picker
    FocusScope.of(context).unfocus();
    
    final initialDate = _toDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final picked = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
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
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
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
      case 'completed':
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      default:
        return status.isNotEmpty ? status : 'Unknown';
    }
  }

  List<Map<String, dynamic>> _filterTransactions(List<Map<String, dynamic>> transactions) {
    String searchQuery = _searchController.text.toLowerCase().trim();
    
    return transactions.where((transaction) {
      // Status filter
      if (_statusFilter != null) {
        final status = transaction['status'] as String? ?? 'unknown';
        final statusLower = status.toLowerCase();
        final filterLower = _statusFilter!.toLowerCase();
        
        // Handle multiple status values that map to the same filter
        if (filterLower == 'succeeded') {
          if (statusLower != 'succeeded' && statusLower != 'completed' && statusLower != 'paid') {
            return false;
          }
        } else if (statusLower != filterLower) {
          return false;
        }
      }
      
      // Date filter (already applied in provider, but double-check here with time component)
      if (_fromDate != null || _toDate != null) {
        final transactionDate = transaction['succeededAt'] as DateTime? ??
                                transaction['completedAt'] as DateTime? ??
                                transaction['createdAt'] as DateTime?;
        
        if (transactionDate != null) {
          // For fromDate: transaction must be on or after the selected date/time
          if (_fromDate != null && transactionDate.isBefore(_fromDate!)) {
            return false;
          }
          // For toDate: transaction must be on or before the selected date/time (respecting time component)
          if (_toDate != null && transactionDate.isAfter(_toDate!)) {
            return false;
          }
        }
      }
      
      // Search filter
      if (searchQuery.isNotEmpty) {
        final carrierName = (transaction['carrierName'] as String? ?? '').toLowerCase();
        final loadNumber = (transaction['loadNumber'] as String? ?? 
                           transaction['loadId'] as String? ?? '').toLowerCase();
        final amount = transaction['amount'] as int? ?? 0;
        final amountStr = (amount ~/ 100).toString();
        final status = _getStatusText(transaction['status'] as String? ?? 'unknown').toLowerCase();
        
        if (!carrierName.contains(searchQuery) &&
            !loadNumber.contains(searchQuery) &&
            !amountStr.contains(searchQuery) &&
            !status.contains(searchQuery)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    // Unfocus any text fields before showing dialog
    FocusScope.of(context).unfocus();
    
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

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadTransactions(
                  forceRefresh: true,
                  fromDate: _fromDate,
                  toDate: _toDate,
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      ...paymentMethods.where((method) => method['isDefault'] == true).take(1).map((method) {
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
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
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

              /// Transactions Header with Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (filteredTransactions.isNotEmpty && (_fromDate != null || _toDate != null || _statusFilter != null))
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () => _printAllTransactions(filteredTransactions),
                          tooltip: 'Print All Filtered Transactions',
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
                        final date = transaction['succeededAt'] as DateTime? ??
                            transaction['completedAt'] as DateTime? ??
                            transaction['createdAt'] as DateTime? ??
                            transaction['failedAt'] as DateTime?;
                        final carrierName = transaction['carrierName'] as String?;
                        final loadNumber = transaction['loadNumber'] as String? ?? 
                                         transaction['loadId'] as String?;

                        return GestureDetector(
                          onTap: () => _showTransactionDetails(transaction),
                          child: _buildTransactionCard(
                            carrierName ?? 'Unknown Carrier',
                            _formatDate(date),
                            amount ~/ 100, // Convert cents to dollars
                            _getStatusText(status),
                            _getStatusColor(status),
                            transaction,
                            carrierName: carrierName,
                            loadNumber: loadNumber,
                          ),
                        );
                      }),
                  ],
                ),
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? DateFormat('MMM dd, yyyy hh:mm a').format(date) : 'Select date & time',
                    style: TextStyle(
                      color: date != null ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
      String id, String date, int amount, String status, Color color,
      Map<String, dynamic> transaction, {
      String? carrierName,
      String? loadNumber,
    }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(date, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          if (carrierName != null || loadNumber != null) ...[
            const SizedBox(height: 8),
            if (carrierName != null)
              Text(
                'To: $carrierName',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            if (loadNumber != null)
              Text(
                'Load: $loadNumber',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
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

  String _formatInvoice(Map<String, dynamic> transaction, dynamic shipper, {DateTime? fromDate, DateTime? toDate}) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('        PAYMENT INVOICE');
    buffer.writeln('');
    buffer.writeln('Remiles Logistics');
    buffer.writeln('Payment Transaction Invoice');
    buffer.writeln('');
    buffer.writeln('----------------------------------------');
    
    final transactionId = transaction['paymentIntentId'] as String? ?? transaction['transferId'] as String? ?? 'N/A';
    buffer.writeln('Transaction ID: ${_formatTransactionId(transactionId)}');
    
    final date = transaction['succeededAt'] as DateTime? ??
                transaction['completedAt'] as DateTime? ??
                transaction['createdAt'] as DateTime?;
    buffer.writeln('Date & Time: ${_formatDate(date)}');
    buffer.writeln('Status: ${_getStatusText(transaction['status'] as String? ?? 'unknown')}');
    
    if (fromDate != null || toDate != null) {
      buffer.writeln('');
      if (fromDate != null && toDate != null) {
        buffer.writeln('Period: ${_formatDate(fromDate)} to ${_formatDate(toDate)}');
      } else if (fromDate != null) {
        buffer.writeln('From Date: ${_formatDate(fromDate)}');
      } else if (toDate != null) {
        buffer.writeln('To Date: ${_formatDate(toDate)}');
      }
    }
    
    buffer.writeln('');
    
    buffer.writeln('From: ${shipper?.companyName ?? shipper?.displayName ?? 'Shipper'}');
    
    final carrierName = transaction['carrierName'] as String?;
    if (carrierName != null) {
      buffer.writeln('To: $carrierName');
    }
    
    buffer.writeln('');
    
    final loadNumber = transaction['loadNumber'] as String? ?? transaction['loadId'] as String?;
    if (loadNumber != null) {
      buffer.writeln('Load ID: $loadNumber');
      buffer.writeln('');
    }
    
    buffer.writeln('----------------------------------------');
    final amount = transaction['amount'] as int? ?? 0;
    buffer.writeln('Amount: \$${(amount / 100).toStringAsFixed(2)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('');
    buffer.writeln('Thank you for using Remiles!');
    buffer.writeln('');
    return buffer.toString();
  }

  Future<void> _showTransactionDetails(Map<String, dynamic> transaction) async {
    final authProvider = context.read<AuthProvider>();
    final shipper = authProvider.shipperUser;
    final status = transaction['status'] as String? ?? 'unknown';
    final amount = transaction['amount'] as int? ?? 0;
    final date = transaction['succeededAt'] as DateTime? ??
                transaction['completedAt'] as DateTime? ??
                transaction['createdAt'] as DateTime?;
    final paymentIntentId = transaction['paymentIntentId'] as String? ?? 
                           transaction['transferId'] as String? ?? 'N/A';
    final carrierName = transaction['carrierName'] as String? ?? 'Unknown Carrier';
    final loadNumber = transaction['loadNumber'] as String? ?? 
                      transaction['loadId'] as String? ?? 'N/A';
    final carrierId = transaction['carrierId'] as String?;
    
    // Unfocus any text fields before showing dialog
    FocusScope.of(context).unfocus();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Transaction ID', _formatTransactionId(paymentIntentId)),
              _buildDetailRow('Date & Time', _formatDate(date)),
              _buildDetailRow('Status', _getStatusText(status), color: _getStatusColor(status)),
              _buildDetailRow('Amount', '\$${(amount / 100).toStringAsFixed(2)}', color: Colors.green),
              const Divider(),
              _buildDetailRow('From', shipper?.companyName ?? shipper?.displayName ?? 'Shipper'),
              _buildDetailRow('To', carrierName),
              _buildDetailRow('Load Number', loadNumber),
              if (carrierId != null) _buildDetailRow('Carrier ID', carrierId),
              const Divider(),
              _buildDetailRow('Type', transaction['type'] as String? ?? 'transfer'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _printInvoice(transaction);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(Map<String, dynamic> transaction) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      final invoiceText = _formatInvoice(transaction, shipper, fromDate: _fromDate, toDate: _toDate);
      
      await Printing.layoutPdf(
        onLayout: (format) async => await _generateInvoicePDF(invoiceText, transaction, shipper),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printAllTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      
      final buffer = StringBuffer();
      buffer.writeln('');
      buffer.writeln('        TRANSACTIONS REPORT');
      buffer.writeln('');
      buffer.writeln('Remiles Logistics');
      buffer.writeln('Payment Transactions Report');
      buffer.writeln('');
      buffer.writeln('----------------------------------------');
      buffer.writeln('From: ${shipper?.companyName ?? shipper?.displayName ?? 'Shipper'}');
      buffer.writeln('Report Date: ${_formatDate(DateTime.now())}');
      if (_fromDate != null || _toDate != null) {
        buffer.writeln('');
        if (_fromDate != null && _toDate != null) {
          buffer.writeln('Period: ${_formatDate(_fromDate)} to ${_formatDate(_toDate)}');
        } else if (_fromDate != null) {
          buffer.writeln('From Date: ${_formatDate(_fromDate)}');
        } else if (_toDate != null) {
          buffer.writeln('To Date: ${_formatDate(_toDate)}');
        }
      }
      if (_statusFilter != null) {
        buffer.writeln('Status Filter: ${_getStatusText(_statusFilter!)}');
      }
      buffer.writeln('Total Transactions: ${transactions.length}');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');
      
      double totalAmount = 0;
      for (var transaction in transactions) {
        final amount = transaction['amount'] as int? ?? 0;
        totalAmount += amount / 100;
        
        buffer.writeln('Transaction ID: ${_formatTransactionId(transaction['paymentIntentId'] as String? ?? transaction['transferId'] as String? ?? 'N/A')}');
        buffer.writeln('Date: ${_formatDate(transaction['succeededAt'] as DateTime? ?? transaction['completedAt'] as DateTime? ?? transaction['createdAt'] as DateTime?)}');
        buffer.writeln('To: ${transaction['carrierName'] as String? ?? 'Unknown Carrier'}');
        buffer.writeln('Amount: \$${(amount / 100).toStringAsFixed(2)}');
        buffer.writeln('Status: ${_getStatusText(transaction['status'] as String? ?? 'unknown')}');
        buffer.writeln('---');
      }
      
      buffer.writeln('');
      buffer.writeln('----------------------------------------');
      buffer.writeln('Total Amount: \$${totalAmount.toStringAsFixed(2)}');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');
      buffer.writeln('Thank you for using Remiles!');
      buffer.writeln('');
      
      final reportText = buffer.toString();
      
      await Printing.layoutPdf(
        onLayout: (format) async => await _generateReportPDF(reportText, transactions.length, totalAmount),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateReportPDF(String reportText, int count, double totalAmount) async {
    final pdf = pw.Document();
    final lines = reportText.split('\n');
    
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
              } else if (line.contains('TRANSACTIONS REPORT') || line.contains('Total Amount:')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else if (line.contains('---')) {
                return pw.Divider();
              } else if (line.contains('Amount:') || line.contains('Total:')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.black,
                  ),
                );
              }
            }).toList(),
          );
        },
      ),
    );
    
    return pdf.save();
  }

  Future<Uint8List> _generateInvoicePDF(String invoiceText, Map<String, dynamic> transaction, dynamic shipper) async {
    final pdf = pw.Document();
    final lines = invoiceText.split('\n');
    
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
              } else if (line.contains('PAYMENT INVOICE')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else if (line.contains('---')) {
                return pw.Divider();
              } else if (line.contains('Amount:')) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                );
              } else {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.black,
                  ),
                );
              }
            }).toList(),
          );
        },
      ),
    );
    
    return pdf.save();
  }
}
