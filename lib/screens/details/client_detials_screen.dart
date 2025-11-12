import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:priyanakaenterprises/screens/details/bank_detials_page.dart';
import 'package:priyanakaenterprises/screens/details/card_detials_page.dart';

import 'package:priyanakaenterprises/screens/add_bill_screen.dart';
import 'package:priyanakaenterprises/screens/forms/add_client_screen.dart';
import 'package:priyanakaenterprises/widgets/card_selection.dart';

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
                Fluttertoast.showToast(msg: "$clientName deleted.");
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
        builder: (_) => SelectCardScreen(
          clientId: clientId,
          clientName: clientName,
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
    final billsStream = FirebaseFirestore.instance.collection('bills').where('clientId', isEqualTo: clientId).orderBy('createdAt', descending: true).snapshots();

    return SectionCard(
      title: 'Bills History',
      child: StreamBuilder<QuerySnapshot>(
        stream: billsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Error loading bills.'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No bills found for this client.');

          final bills = snapshot.data!.docs;
          return Column(children: bills.map((bill) {
            final data = bill.data() as Map<String, dynamic>;
            final amount = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(data['amount'] ?? 0);
            final status = data['status'] ?? 'Unknown';
            final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
            final formattedDate = dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : 'No due date';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(amount),
                subtitle: Text('Due: $formattedDate'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: status == 'paid' ? Colors.green.withOpacity(0.12) : (status == 'unpaid' ? Colors.red.withOpacity(0.12) : Colors.orange.withOpacity(0.12)), borderRadius: BorderRadius.circular(8)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: status == 'paid' ? Colors.green : (status == 'unpaid' ? Colors.red : Colors.orange), fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList());
        },
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