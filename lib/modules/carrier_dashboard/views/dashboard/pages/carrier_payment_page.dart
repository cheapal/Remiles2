import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../providers/carrier_payments_provider.dart';
import '../../../../../../providers/auth_provider.dart';
import '../../../../../../providers/payment_methods_provider.dart';
import 'carrier_add_payment_method.dart';

class CarrierPaymentPage extends StatefulWidget {
  const CarrierPaymentPage({super.key});

  @override
  State<CarrierPaymentPage> createState() => _CarrierPaymentPageState();
}

class _CarrierPaymentPageState extends State<CarrierPaymentPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter; // null means all statuses

  @override
  void initState() {
    super.initState();
    // Load data (uses cache if available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CarrierPaymentsProvider>();
      provider.loadPayments();
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
      await context.read<CarrierPaymentsProvider>().loadPayments(
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
      await context.read<CarrierPaymentsProvider>().loadPayments(
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
    await context.read<CarrierPaymentsProvider>().loadPayments(
      forceRefresh: true,
      fromDate: null,
      toDate: null,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTransferId(String transferId) {
    // Extract last 4 characters for display
    if (transferId.length > 4) {
      return 'RM-${transferId.substring(transferId.length - 4)}';
    }
    return 'RM-$transferId';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
      case 'completed':
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

  List<Map<String, dynamic>> _filterPayments(List<Map<String, dynamic>> payments) {
    String searchQuery = _searchController.text.toLowerCase().trim();
    
    return payments.where((payment) {
      // Status filter
      if (_statusFilter != null) {
        final status = payment['status'] as String? ?? 'unknown';
        if (status.toLowerCase() != _statusFilter!.toLowerCase()) {
          return false;
        }
      }
      
      // Search filter - search by shipper name, transfer ID, amount, or load number
      if (searchQuery.isNotEmpty) {
        final transferId = _formatTransferId(payment['transferId'] as String? ?? '').toLowerCase();
        final shipperName = (payment['shipperName'] as String? ?? '').toLowerCase();
        final amount = payment['amount'] as int? ?? 0;
        final amountStr = (amount ~/ 100).toString();
        final status = _getStatusText(payment['status'] as String? ?? 'unknown').toLowerCase();
        final loadNumber = (payment['loadNumber'] as String? ?? '').toLowerCase();
        
        if (!transferId.contains(searchQuery) &&
            !shipperName.contains(searchQuery) &&
            !amountStr.contains(searchQuery) &&
            !status.contains(searchQuery) &&
            !loadNumber.contains(searchQuery)) {
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
    
    if (result != cancelSentinel) {
      setState(() {
        _statusFilter = result;
      });
    }
  }

  String _formatReceipt(Map<String, dynamic> payment, dynamic carrier, {DateTime? fromDate, DateTime? toDate}) {
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('        PAYMENT RECEIPT');
    buffer.writeln('');
    buffer.writeln('Remiles Logistics');
    buffer.writeln('Payment Transfer Receipt');
    buffer.writeln('');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Transfer ID: ${_formatTransferId(payment['transferId'] as String? ?? '')}');
    buffer.writeln('Date: ${_formatDate(payment['succeededAt'] as DateTime? ?? payment['createdAt'] as DateTime?)}');
    buffer.writeln('Status: ${_getStatusText(payment['status'] as String? ?? 'unknown')}');
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
    buffer.writeln('From: ${payment['shipperName'] as String? ?? 'Unknown Shipper'}');
    buffer.writeln('To: ${carrier?.companyName ?? carrier?.name ?? 'Carrier'}');
    buffer.writeln('');
    buffer.writeln('Load ID: ${payment['loadNumber'] as String? ?? payment['loadId'] as String? ?? 'N/A'}');
    buffer.writeln('');
    buffer.writeln('----------------------------------------');
    final amount = payment['amount'] as int? ?? 0;
    buffer.writeln('Amount: \$${(amount / 100).toStringAsFixed(2)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('');
    buffer.writeln('Thank you for using Remiles!');
    buffer.writeln('');
    return buffer.toString();
  }

  Future<void> _printReceipt(BuildContext context, Map<String, dynamic> payment) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      final receiptText = _formatReceipt(payment, carrier, fromDate: _fromDate, toDate: _toDate);
      
      await Printing.layoutPdf(
        onLayout: (format) async => await _generateReceiptPDF(receiptText, payment, carrier),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generateReceiptPDF(String receiptText, Map<String, dynamic> payment, dynamic carrier) async {
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
              } else if (line.contains('PAYMENT RECEIPT')) {
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

  void _copyReceipt(BuildContext context, Map<String, dynamic> payment) {
    final authProvider = context.read<AuthProvider>();
    final carrier = authProvider.carrierUser;
    final receiptText = _formatReceipt(payment, carrier, fromDate: _fromDate, toDate: _toDate);
    
    Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: SafeArea(
        child: Consumer<CarrierPaymentsProvider>(
          builder: (context, provider, child) {
            final allPayments = provider.payments;
            final filteredPayments = _filterPayments(allPayments);
            final isLoading = provider.isLoading && allPayments.isEmpty;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "Payments Received",textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF186230),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // CircleAvatar(
                      //   radius: 22,
                      //   backgroundColor: Colors.green.shade100,
                      //   child: const Icon(Icons.person, color: Colors.green, size: 28),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// Summary Card
                  Container(
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${filteredPayments.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF186230),
                              ),
                            ),
                            const Text(
                              'Total Payments',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        Column(
                          children: [
                            Text(
                              '\$${((filteredPayments.fold<int>(0, (sum, p) => sum + (p['amount'] as int? ?? 0))) / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF186230),
                              ),
                            ),
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Add Payment Method Button - For receiving payments
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF43975A), width: 2),
                    ),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide.none,
                      ),
                      onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CarrierAddPaymentMethod(),
                        ),
                      );
                        // Refresh payment methods after returning
                        final paymentProvider = context.read<PaymentMethodsProvider>();
                        paymentProvider.loadPaymentMethods(forceRefresh: true);
                      },
                      icon: const Icon(Icons.account_balance_wallet, color: Color(0xFF186230), size: 24),
                      label: const Text(
                        "Manage Payment Methods",
                        style: TextStyle(
                          color: Color(0xFF186230),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
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
                            hintText: "Search by shipper name, ID, amount...",
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

                  /// Payments List
                  const Text(
                    "Payments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (filteredPayments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allPayments.isEmpty
                                  ? 'No payments received yet'
                                  : 'No payments match your filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_fromDate != null || _toDate != null || _statusFilter != null || _searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                _fromDate != null || _toDate != null
                                    ? 'Try adjusting your date range or clear filters'
                                    : 'Try adjusting your search or filters',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _fromDate = null;
                                    _toDate = null;
                                    _statusFilter = null;
                                    _searchController.clear();
                                  });
                                  provider.loadPayments(forceRefresh: true);
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Clear All Filters'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredPayments.map((payment) {
                      final status = payment['status'] as String? ?? 'unknown';
                      final amount = payment['amount'] as int? ?? 0;
                      final date = payment['succeededAt'] as DateTime? ??
                          payment['completedAt'] as DateTime? ??
                          payment['createdAt'] as DateTime?;
                      final transferId = payment['transferId'] as String? ?? '';
                      final shipperName = payment['shipperName'] as String? ?? 'Unknown Shipper';

                      return _buildPaymentCard(
                        _formatTransferId(transferId),
                        _formatDate(date),
                        amount ~/ 100, // Convert cents to dollars
                        _getStatusText(status),
                        _getStatusColor(status),
                        shipperName,
                        payment['loadNumber'] as String? ?? payment['loadId'] as String? ?? 'N/A',
                        payment,
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
          child: AbsorbPointer(
            child: TextField(
              readOnly: true,
              enableInteractiveSelection: false,
              controller: TextEditingController(
                text: date != null ? DateFormat('MMM dd, yyyy').format(date) : '',
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
        ),
      ],
    );
  }

  Widget _buildPaymentCard(
    String id,
    String date,
    int amount,
    String status,
    Color statusColor,
    String shipperName,
    String loadNumber,
    Map<String, dynamic> payment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFF43975A), width: 1),
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
                    Text(
                      id,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shipperName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Load:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loadNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "\$$amount",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF186230),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print, size: 20),
                        onPressed: () => _printReceipt(context, payment),
                        tooltip: 'Print Receipt',
                        color: const Color(0xFF186230),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () => _copyReceipt(context, payment),
                        tooltip: 'Copy Receipt',
                        color: const Color(0xFF186230),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
