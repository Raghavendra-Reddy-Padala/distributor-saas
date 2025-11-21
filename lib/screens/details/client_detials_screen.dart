import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:priyanakaenterprises/screens/details/bank_detials_page.dart';
import 'package:priyanakaenterprises/screens/details/card_detials_page.dart';

import 'package:priyanakaenterprises/screens/add_bill_screen.dart';
import 'package:priyanakaenterprises/screens/forms/add_client_screen.dart';
import 'package:priyanakaenterprises/screens/tabs/bills_tab.dart';
import 'package:priyanakaenterprises/widgets/card_selection.dart';
import 'package:toastification/toastification.dart';

class ClientDetailsScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailsScreen({super.key, required this.clientId});

  void _showDeleteConfirmation(BuildContext context, String clientName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $clientName? '
              'This will also delete associated bills/reminders. This action cannot be undone.'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete Permanently'),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('clients').doc(clientId).delete();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                Toastification().show(
                  title: Text('Client Deleted'),
                  description:Text( '$clientName has been deleted successfully.'),
                  type: ToastificationType.success,
                );  

                /// Toastification().show(
///   context: context, // optional if ToastificationWrapper is in widget tree
///   alignment: Alignment.topRight,
///   title: Text('Hello World'),
///   description: Text('This is a notification'),
///   type: ToastificationType.info,
///   style: ToastificationStyle.flat,
///   autoCloseDuration: Duration(seconds: 3),
/// );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientStream = FirebaseFirestore.instance.collection('clients').doc(clientId).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: clientStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('Error')), body: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(appBar: AppBar(title: const Text('Not Found')), body: const Center(child: Text('Client not found.')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final clientName = data['name'] ?? 'Client Details';

        return Scaffold(
          appBar: AppBar(
            title: Text(clientName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddClientScreen(clientDoc: snapshot.data!))),
                tooltip: 'Edit Client',
              ),
              IconButton(
                icon: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error),
                onPressed: () => _showDeleteConfirmation(context, clientName),
                tooltip: 'Delete Client',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Top summary card
                SummaryCard(data: data),
                const SizedBox(height: 16),

                // Documents row
                SectionCard(
                  title: 'Documents',
                  child: DocumentsRow(data: data),
                ),
                const SizedBox(height: 16),

                // Credit Cards - Now Tappable!
                CreditCardsSection(data: data),
                const SizedBox(height: 16),

                // Bank Accounts - Now Tappable!
                BankAccountsSection(data: data),
                const SizedBox(height: 16),

                // Bills History
                BillsHistorySection(clientId: clientId),
                const SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditCardsPage(
          
          clientData: data,
        ),
      ),
    );
  },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Bill'),
          ),
        );
      },
    );
  }
}

// --------------------- Reusable Small Widgets ---------------------
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final mobile = data['mobile'] ?? '';
    final email = data['email'] ?? '';
    final address = data['address'] ?? '';

    return SectionCard(
      title: 'Personal Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])),
                child: Center(child: Text((data['name'] as String?)?.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['name'] ?? 'No Name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(mobile.isNotEmpty ? mobile : 'No mobile', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(email.isNotEmpty ? email : 'No email', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ]),
              )
            ],
          ),
          const SizedBox(height: 12),
          if ((address as String).isNotEmpty) ...[
            Row(children: [const Icon(Icons.location_on_rounded, size: 18, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(address))])
          ]
        ],
      ),
    );
  }
}

class DocumentsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const DocumentsRow({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final panUrl = data['panImageUrl'] as String?;
    final aadhaarImages = (data['aadhaarImages'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final frontUrl = aadhaarImages.firstWhere((i) => i['side'] == 'front', orElse: () => {})['url'] as String?;
    final backUrl = aadhaarImages.firstWhere((i) => i['side'] == 'back', orElse: () => {})['url'] as String?;

    return Row(
      children: [
        Expanded(child: DocumentPreview(label: 'PAN', url: panUrl)),
        const SizedBox(width: 12),
        Expanded(child: DocumentPreview(label: 'Aadhaar Front', url: frontUrl)),
        const SizedBox(width: 12),
        Expanded(child: DocumentPreview(label: 'Aadhaar Back', url: backUrl)),
      ],
    );
  }
}

class DocumentPreview extends StatelessWidget {
  final String label;
  final String? url;
  const DocumentPreview({super.key, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: (url != null && url!.isNotEmpty) ? () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(url!))) : null,
        child: Container(
          height: 96,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: (url != null && url!.isNotEmpty)
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url!, fit: BoxFit.cover, loadingBuilder: (c, w, p) => p == null ? w : const Center(child: CircularProgressIndicator())))
              : Center(child: Icon(Icons.image_not_supported, color: Colors.grey.shade400)),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 12))
    ]);
  }
}

// Updated CreditCardsSection - Now Tappable!
class CreditCardsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const CreditCardsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = (data['creditCards'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditCardsPage(clientData: data),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Credit Cards',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cards.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const Text('No credit cards found for this client.')
            else
              Column(
                children: cards.take(2).map((card) {
                  final last4 = card['cardNumber'];
                  final limit = NumberFormat.currency(
                    locale: 'en_IN',
                    symbol: '₹',
                    decimalDigits: 0,
                  ).format(card['cardLimit'] ?? 0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card['bankName'] ?? 'Unknown Bank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                last4,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          limit,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (cards.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${cards.length - 2} more cards',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Updated BankAccountsSection - Now Tappable!
class BankAccountsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const BankAccountsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accounts = (data['bankAccounts'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BankAccountsPage(clientData: data),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Bank Accounts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${accounts.length}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (accounts.isEmpty)
              const Text('No bank accounts found for this client.')
            else
              Column(
                children: accounts.take(2).map((acc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc['bankName'] ?? 'Unknown Bank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                acc['accountNumber'] ?? 'No Account #',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.verified,
                          color: Colors.green[600],
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (accounts.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${accounts.length - 2} more accounts',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class BillsHistorySection extends StatelessWidget {
  final String clientId;
  const BillsHistorySection({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final billsStream = FirebaseFirestore.instance
        .collection('bills')
        .where('clientId', isEqualTo: clientId)
        .snapshots();

    return SectionCard(
      title: 'Bills History',
      child: StreamBuilder<QuerySnapshot>(
        stream: billsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading bills.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No bills found for this client.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final bills = snapshot.data!.docs;
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bills.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bill = bills[index];
              final data = bill.data() as Map<String, dynamic>;
              
              final totalBillPayment = data['totalBillPayment'] ?? 0;
              final totalWithdrawal = data['totalWithdrawal'] ?? 0;
              final finalAmount = data['interestAmount'] ?? 0;
              final status = data['status'] ?? 'Unknown';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null 
                  ? DateFormat('dd MMM yyyy').format(createdAt) 
                  : 'No date';
              final selectedGateway = data['selectedGateway']?.toString().toUpperCase() ?? 'N/A';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BillDetailPage(billDoc: bill),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Amount Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Final Amount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 2,
                                    ).format(finalAmount),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'paid'
                                    ? Colors.green.withOpacity(0.15)
                                    : (status == 'unpaid'
                                        ? Colors.red.withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.15)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: status == 'paid'
                                      ? Colors.green.shade700
                                      : (status == 'unpaid'
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        
                        // Details Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                icon: Icons.credit_card,
                                label: 'Bill Payment',
                                value: '₹${NumberFormat('#,##,##0').format(totalBillPayment)}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                icon: Icons.account_balance_wallet,
                                label: 'Withdrawal',
                                value: '₹${NumberFormat('#,##,##0').format(totalWithdrawal)}',
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Footer Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Date and Gateway
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      selectedGateway,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // View Details Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BillDetailPage(billDoc: bill),
                                    ),
                                  );
                                },
                                tooltip: 'View Details',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return ListTile(leading: Icon(icon, color: Colors.grey[600]), title: Text(label), subtitle: Text(value, style: const TextStyle(fontSize: 14)));
  }
}