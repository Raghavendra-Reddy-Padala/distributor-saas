import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:priyanakaenterprises/screens/add_bill_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCardsPage extends StatefulWidget {
  final Map<String, dynamic> clientData;
  const CreditCardsPage({super.key, required this.clientData});

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterCards(List<Map<String, dynamic>> cards) {
    if (_searchQuery.isEmpty) {
      return cards;
    }

    final query = _searchQuery.toLowerCase();
    return cards.where((card) {
      final cardNumber = (card['cardNumber'] as String?)?.toLowerCase() ?? '';
      final last4Digits = cardNumber.length >= 4 
          ? cardNumber.substring(cardNumber.length - 4) 
          : cardNumber;
      
      return cardNumber.contains(query) || last4Digits.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cards = (widget.clientData['creditCards'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    final filteredCards = _filterCards(cards);

    final totalLimit = cards.fold<double>(
      0,
      (sum, card) => sum + ((card['cardLimit'] as num?)?.toDouble() ?? 0),
    );

    final formattedTotalLimit = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(totalLimit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Cards', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _CompactStatItem(
                      icon: Icons.credit_card,
                      label: 'Total Cards',
                      value: '${cards.length}',
                      isAmount: false,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompactStatItem(
                      icon: Icons.account_balance_wallet,
                      label: 'Total Limit',
                      value: formattedTotalLimit,
                      isAmount: true,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by card number or last 4 digits...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    _searchQuery.isEmpty ? 'Your Cards' : 'Search Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredCards.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: filteredCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.credit_card_off : Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'No credit cards found'
                                : 'No cards match your search',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Try searching with different keywords',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final originalIndex = cards.indexOf(filteredCards[index]);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CreditCardItem(
                            cardData: filteredCards[index],
                            clientData: widget.clientData,
                            clientId: widget.clientData['id']?.toString() ?? 
                                      widget.clientData['clientId']?.toString() ?? '',
                            clientName: widget.clientData['name']?.toString() ?? 
                                        widget.clientData['clientName']?.toString() ?? 'Client',
                            cardIndex: originalIndex,
                            onPaymentAdded: () => setState(() {}),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  final bool isAmount;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: isAmount ? 18 : 16,
      fontWeight: isAmount ? FontWeight.w900 : FontWeight.w800,
      letterSpacing: isAmount ? 0.6 : 0.3,
    );

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: valueStyle,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.85)),
        ],
      ),
    );
  }
}

class CreditCardItem extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final Map<String, dynamic> clientData;
  final String clientId;
  final String clientName;
  final int cardIndex;
  final VoidCallback onPaymentAdded;
  
  const CreditCardItem({
    super.key,
    required this.cardData,
    required this.clientData,
    required this.clientId,
    required this.clientName,
    required this.cardIndex,
    required this.onPaymentAdded,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
    );
  }

  Future<void> _showPaymentHistoryDialog(BuildContext context) async {
    final payments = (cardData['paymentHistory'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    // Sort by date (newest first)
    payments.sort((a, b) {
      final dateA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final dateB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payment History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddPaymentDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: payments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No payment history',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
                          final month = payment['month'] as String? ?? '';
                          final year = payment['year'] as int? ?? DateTime.now().year;
                          final timestamp = (payment['timestamp'] as Timestamp?)?.toDate();
                          
                          final formattedAmount = NumberFormat.currency(
                            locale: 'en_IN',
                            symbol: '₹',
                            decimalDigits: 0,
                          ).format(amount);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '$month $year',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: timestamp != null
                                  ? Text(
                                      DateFormat('dd MMM yyyy, hh:mm a').format(timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formattedAmount,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  if (index == 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Latest',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onLongPress: () {
                                _showEditPaymentDialog(context, payment, index);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPaymentDialog(BuildContext context) async {
    final amountController = TextEditingController();
    String? selectedMonth;
    int selectedYear = DateTime.now().year;

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    hintText: 'Enter amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Payment Month', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  hint: const Text('Select month'),
                  items: months.map((month) {
                    return DropdownMenuItem(value: month, child: Text(month));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMonth = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Year', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(value: year, child: Text(year.toString()));
                  }),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedYear = value ?? DateTime.now().year;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty || selectedMonth == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')),
                  );
                  return;
                }

                await _savePayment(context, amount, selectedMonth!, selectedYear);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPaymentDialog(
    BuildContext context,
    Map<String, dynamic> payment,
    int paymentIndex,
  ) async {
    final amountController = TextEditingController(
      text: (payment['amount'] as num?)?.toString() ?? '',
    );
    String? selectedMonth = payment['month'] as String?;
    int selectedYear = payment['year'] as int? ?? DateTime.now().year;

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    hintText: 'Enter amount',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Payment Month', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMonth,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: months.map((month) {
                    return DropdownMenuItem(value: month, child: Text(month));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMonth = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Year', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(value: year, child: Text(year.toString()));
                  }),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedYear = value ?? DateTime.now().year;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Payment'),
                    content: const Text('Are you sure you want to delete this payment?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deletePayment(context, paymentIndex);
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty || selectedMonth == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')),
                  );
                  return;
                }

                await _updatePayment(context, paymentIndex, amount, selectedMonth!, selectedYear);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment(
    BuildContext context,
    double amount,
    String month,
    int year,
  ) async {
    try {
      final clientDocId = clientData['id']?.toString() ?? 
                         clientData['clientId']?.toString() ?? '';
                                                 print(  clientData);


      if (clientDocId.isEmpty) {
        throw Exception('Client ID not found');
      }

      final payments = (cardData['paymentHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      payments.add({
        'amount': amount,
        'month': month,
        'year': year,
      });

      final updatedCards = List<Map<String, dynamic>>.from(
        (clientData['creditCards'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );

      updatedCards[cardIndex]['paymentHistory'] = payments;

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientDocId)
          .update({'creditCards': updatedCards});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment updated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        onPaymentAdded();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        
      }
          print('Error: $e');
                                  print(  clientData);


    }
  }
    Future<void> _updatePayment(
    BuildContext context,
    int paymentIndex,
    double amount,
    String month,
    int year,
  ) async {
    try {
      final clientDocId = clientData['id']?.toString() ?? 
                         clientData['id']?.toString() ?? '';
                        print(  clientData);

      if (clientDocId.isEmpty) {
        throw Exception('Client ID not found');
      }

      final payments = List<Map<String, dynamic>>.from(
        (cardData['paymentHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );

      payments[paymentIndex] = {
        'amount': amount,
        'month': month,
        'year': year,
        'timestamp': payments[paymentIndex]['timestamp'],
      };

      final updatedCards = List<Map<String, dynamic>>.from(
        (clientData['creditCards'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );

      updatedCards[cardIndex]['paymentHistory'] = payments;

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientDocId)
          .update({'creditCards': updatedCards});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        onPaymentAdded();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),

        );
      }
    }
  }


  Future<void> _deletePayment(BuildContext context, int paymentIndex) async {
    try {
      final clientDocId = clientData['id']?.toString() ?? 
                         clientData['clientId']?.toString() ?? '';

      if (clientDocId.isEmpty) {
        throw Exception('Client ID not found');
      }

      final payments = List<Map<String, dynamic>>.from(
        (cardData['paymentHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );

      payments.removeAt(paymentIndex);

      final updatedCards = List<Map<String, dynamic>>.from(
        (clientData['creditCards'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );

      updatedCards[cardIndex]['paymentHistory'] = payments;

      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientDocId)
          .update({'creditCards': updatedCards});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully!'),
            backgroundColor: Colors.red,
          ),
        );
        onPaymentAdded();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  LinearGradient _getCardGradient(String? bankName) {
    final bank = (bankName ?? '').toLowerCase();
    if (bank.contains('hdfc')) {
      return const LinearGradient(
        colors: [Color(0xFF004C8F), Color(0xFF0066B2), Color(0xFF0A63A6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('icici')) {
      return const LinearGradient(
        colors: [Color(0xFFB34700), Color(0xFFEF6C00), Color(0xFFFF8C42)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('axis')) {
      return const LinearGradient(
        colors: [Color(0xFF7B0F2E), Color(0xFFA41C44), Color(0xFFC92752)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('sbi')) {
      return const LinearGradient(
        colors: [Color(0xFF0B3A78), Color(0xFF134A96), Color(0xFF1E5BB8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('kotak')) {
      return const LinearGradient(
        colors: [Color(0xFF9F1D22), Color(0xFFD22B2B), Color(0xFFE63946)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (bank.contains('citibank') || bank.contains('citi')) {
      return const LinearGradient(
        colors: [Color(0xFF003A70), Color(0xFF004F8C), Color(0xFF0066B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF1F2937), Color(0xFF334155), Color(0xFF475569)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankName = (cardData['bankName'] as String?) ?? 'Bank';
    final cardNumber = (cardData['cardNumber'] as String?) ?? '';
    final holder = (cardData['cardHolderName'] as String?) ?? '—';
    final holderMobile = (cardData['cardHolderMobile'] as String?) ?? '';
    final expiry = (cardData['expiryDate'] as String?) ?? 'MM/YY';
    final cvv = (cardData['cvv'] as String?) ?? '•••';
    final cardType = (cardData['cardType'] as String?) ?? '';
    final limitValue = (cardData['cardLimit'] as num?)?.toDouble() ?? 0;
    final limit = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(limitValue);
    final billDate = (cardData['billGenerationDate'] != null)
        ? cardData['billGenerationDate'].toString()
        : '-';
    final dueDate = (cardData['cardDueDate'] != null)
        ? cardData['cardDueDate'].toString()
        : '-';

    // Get latest payment
    final payments = (cardData['paymentHistory'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    
    // Sort to get latest payment
    payments.sort((a, b) {
      final dateA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final dateB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final latestPayment = payments.isNotEmpty ? payments.first : null;
    final latestAmount = latestPayment != null 
        ? NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
            .format((latestPayment['amount'] as num?)?.toDouble() ?? 0)
        : null;
    final latestMonth = latestPayment?['month'] as String?;
    final latestYear = latestPayment?['year'] as int?;

    final gradient = _getCardGradient(bankName);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank name and chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bankName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Card number
                GestureDetector(
                  onTap: () => _copyToClipboard(context, cardNumber, 'Card number'),
                  child: Text(
                    cardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Card holder name and mobile
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _copyToClipboard(context, holder, 'Holder name'),
                            child: Text(
                              holder.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (holderMobile.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _copyToClipboard(context, holderMobile, 'Mobile number'),
                              child: Text(
                                holderMobile,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Expiry, CVV, Card Type
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPIRES',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _copyToClipboard(context, expiry, 'Expiry date'),
                            child: Text(
                              expiry,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CVV',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _copyToClipboard(context, cvv, 'CVV'),
                            child: Text(
                              cvv,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cardType.isNotEmpty)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TYPE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _copyToClipboard(context, cardType, 'Card type'),
                              child: Text(
                                cardType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

               const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Credit Limit',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _copyToClipboard(context, limitValue.toString(), 'Credit limit'),
                            child: Text(
                              limit,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill Date',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(context, billDate, 'Bill date'),
                                  child: Text(
                                    'Day $billDate',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(context, dueDate, 'Due date'),
                                  child: Text(
                                    'Day $dueDate',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (latestPayment != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showPaymentHistoryDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color.fromARGB(255, 56, 199, 152).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                         
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Payment',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$latestMonth $latestYear',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                latestAmount!,
                                style: const TextStyle(
                    color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${payments.length} payment${payments.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showAddPaymentDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.white.withOpacity(0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Payment History',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
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
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
               final selectedCard = {
  'bankName': cardData['bankName'],
  'cardNumber': cardData['cardNumber'],
  'cardHolderName': cardData['cardHolderName'],
  'cardLimit': cardData['cardLimit'],
  'cardType': cardData['cardType'],
  'billGenerationDate': cardData['billGenerationDate'],
  'cardDueDate': cardData['cardDueDate'],
  'cvv': cardData['cvv'],
  'expiryDate': cardData['expiryDate'],
  'cardHolderMobile': cardData['cardHolderMobile'],
  'paymentHistory': cardData['paymentHistory'],
  'billPaymentRatePercent': cardData['billPaymentRatePercent'],
  'withdrawalRatePercent': cardData['withdrawalRatePercent'],
};

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddBillScreen(
                      clientId: clientId,
                      clientName: clientName,
                      clientData: clientData,
                      selectedCard: selectedCard,
                      cardIndex: cardIndex,

                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pay Bill',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

