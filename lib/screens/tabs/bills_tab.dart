import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:priyanakaenterprises/screens/add_bill_screen.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Improved BillsTab with proper data display and bill view functionality
class BillsTab extends StatefulWidget {
  const BillsTab({super.key});

  @override
  State<BillsTab> createState() => _BillsTabState();
}

enum BillStatusFilter { all, paid, unpaid }

class _BillsTabState extends State<BillsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BillStatusFilter _selectedFilter = BillStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedFilter = BillStatusFilter.values[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _buildBillsStream(String distributorId) {
    Query query = FirebaseFirestore.instance
        .collection('bills')
        .where('distributorId', isEqualTo: distributorId);

    switch (_selectedFilter) {
      case BillStatusFilter.paid:
        query = query.where('status', isEqualTo: 'paid');
        break;
      case BillStatusFilter.unpaid:
        query = query.where('status', isEqualTo: 'unpaid');
        break;
      case BillStatusFilter.all:
      default:
        break;
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final distributorId = context.watch<AuthProvider>().distributorId;

    if (distributorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bills')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              tabs: const [
                Tab(text: 'ALL BILLS'),
                Tab(text: 'PAID'),
                Tab(text: 'UNPAID'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildBillsStream(distributorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState(
              message: 'No bills found',
              subtitle: 'Create a new bill using the + button',
            );
          }

          final bills = snapshot.data!.docs;


          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => BillCardV2(billDoc: bills[index]),
            
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  const _EmptyState({required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 88, color: Colors.grey[400]),
            const SizedBox(height: 18),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: const TextStyle(color: Colors.black45))
            ]
          ],
        ),
      ),
    );
  }
}

class BillCardV2 extends StatelessWidget {
  final DocumentSnapshot billDoc;
  const BillCardV2({super.key, required this.billDoc});

  Map<String, dynamic> get data => billDoc.data() as Map<String, dynamic>;

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'unpaid':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatAmount(num? amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
        .format(amount ?? 0);
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(ts.toDate());
  }

  Future<void> _markAsPaid(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('bills')
          .doc(billDoc.id)
          .update({'status': 'paid'});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill marked as paid')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientName = data['clientName'] ?? 'Unknown Client';
    final status = (data['status'] as String?) ?? 'unknown';
    final finalAmount = (data['interestAmount'] as num?) ?? 0;
    final totalBillPayment = (data['totalBillPayment'] as num?) ?? 0;
    final totalWithdrawal = (data['totalWithdrawal'] as num?) ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final clientId = data['clientId'] ?? 'N/A';

    final statusColor = _statusColor(status);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillDetailPage(billDoc: billDoc),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: statusColor.withOpacity(0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: statusColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: statusColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ID: $clientId',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  // Amount details
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.account_balance_wallet,
                          label: 'Bill Payment',
                          value: _formatAmount(totalBillPayment),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.money_off,
                          label: 'Withdrawal',
                          value: _formatAmount(totalWithdrawal),
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Final amount (highlighted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.currency_rupee, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Final Amount To Collect',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatAmount(finalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Date and actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (status == 'unpaid')
                            ElevatedButton.icon(
                              onPressed: () => _markAsPaid(context),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Mark Paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BillDetailPage(billDoc: billDoc),
                                ),
                              );
                            },
                            tooltip: 'View Details',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Bill Detail Page
class BillDetailPage extends StatelessWidget {
  final DocumentSnapshot billDoc;

  const BillDetailPage({super.key, required this.billDoc});

  Map<String, dynamic> get data => billDoc.data() as Map<String, dynamic>;

  String _formatAmount(num? amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)
        .format(amount ?? 0);
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'unpaid':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _markAsPaid(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('bills')
          .doc(billDoc.id)
          .update({'status': 'paid'});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill marked as paid successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] as String?) ?? 'unknown';
    final statusColor = _statusColor(status);
    
    final selectedCard = data['selectedCard'] as Map<String, dynamic>?;
    final billPayments = (data['billPayments'] as List<dynamic>?)?.cast<num>() ?? [];
    final withdrawals = (data['withdrawals'] as List<dynamic>?)?.cast<num>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          if (status == 'unpaid')
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _markAsPaid(context),
              tooltip: 'Mark as Paid',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['clientName'] ?? 'Unknown Client',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Client ID: ${data['clientId'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatAmount(data['interestAmount']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Final Amount To Collect',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill Information
                  _SectionCard(
                    title: 'Bill Information',
                    icon: Icons.receipt_long,
                    children: [
                      _DetailRow('Created At', _formatDate(data['createdAt'])),
                      _DetailRow('Gateway', data['selectedGateway']?.toUpperCase() ?? 'N/A'),
                      _DetailRow('Client Rate', '${data['clientRate'] ?? 0}%'),
                      _DetailRow('Gateway Rate', '${data['gatewayRate'] ?? 0}%'),
                      _DetailRow('Profit Margin', '${data['profitMargin'] ?? 0}%'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Payment Breakdown
                  _SectionCard(
                    title: 'Payment Breakdown',
                    icon: Icons.account_balance_wallet,
                    children: [
                      
                      _DetailRow(
                        'Total Bill Payment',
                        _formatAmount(data['totalBillPayment']),
                        isBold: true,
                      ),
                      _DetailRow(
                        'Total Withdrawal',
                        _formatAmount(data['totalWithdrawal']),
                        isBold: true,
                      ),
                      _DetailRow(
                        'Amount To Pay',
                        _formatAmount(data['interestAmount']),
                        valueColor: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bill Payments List
                  if (billPayments.isNotEmpty)
                    _SectionCard(
                      title: 'Bill Payments',
                      icon: Icons.payment,
                      children: billPayments.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment ${entry.key + 1}'),
                              Text(
                                _formatAmount(entry.value),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // Withdrawals List
                  if (withdrawals.isNotEmpty)
                    _SectionCard(
                      title: 'Withdrawals',
                      icon: Icons.money_off,
                      children: withdrawals.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Withdrawal ${entry.key + 1}'),
                              Text(
                                _formatAmount(entry.value),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // Card Details
                  if (selectedCard != null)
                    _SectionCard(
                      title: 'Card Details',
                      icon: Icons.credit_card,
                      children: [
                        _DetailRow('Card Holder', selectedCard['cardHolderName'] ?? 'N/A'),
                        _DetailRow('Card Number', _maskCardNumber(selectedCard['cardNumber'])),
                        _DetailRow('Card Type', selectedCard['cardType'] ?? 'N/A'),
                        _DetailRow('Bank', selectedCard['bankName'] ?? 'N/A'),
                        _DetailRow('Expiry Date', selectedCard['expiryDate'] ?? 'N/A'),
                        _DetailRow('Card Limit', _formatAmount(selectedCard['cardLimit'])),
                        _DetailRow('Bill Generation Date', selectedCard['billGenerationDate'] ?? 'N/A'),
                        _DetailRow('Card Due Date', selectedCard['cardDueDate'] ?? 'N/A'),
                        _DetailRow('Mobile', selectedCard['cardHolderMobile'] ?? 'N/A'),
                      ],
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: status == 'unpaid'
          ? FloatingActionButton.extended(
              onPressed: () => _markAsPaid(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Paid'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  String _maskCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber.length < 4) return 'N/A';
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _DetailRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}