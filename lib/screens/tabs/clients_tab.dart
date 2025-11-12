import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:priyanakaenterprises/screens/details/client_detials_screen.dart';
import 'package:priyanakaenterprises/screens/forms/add_client_screen.dart';
import 'package:priyanakaenterprises/screens/search/client_search_delegate.dart';
import 'package:priyanakaenterprises/screens/tabs/dashboard_tab.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // For swipe actions
import 'package:fluttertoast/fluttertoast.dart'; // For "copied" message

class ClientsTab extends StatelessWidget {
  const ClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final distributorId = context.watch<AuthProvider>().distributorId;

    if (distributorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clients')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final clientsStream = FirebaseFirestore.instance
        .collection('clients')
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('name', descending: false)
        .snapshots();

    final clientFormLink =
        'https://priyanka-enterprises-69.web.app/form/$distributorId';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Form Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: clientFormLink)).then((_) {
                Fluttertoast.showToast(msg: "Client form link copied!");
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Clients',
            onPressed: () {
              showSearch(
                context: context,
                delegate: ClientSearchDelegate(distributorId: distributorId),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: clientsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'An error occurred: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Re-uses the same EmptyStateWidget from the dashboard file
            return const Center(
              child: EmptyStateWidget(
                message: 'No clients found.\nTap the "+" button to add a new client.',
                icon: Icons.people_outline_rounded,
              ),
            );
          }

          final clients = snapshot.data!.docs;

          // Use same card container style to keep UI consistent
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final clientDoc = clients[index];
                    final data = clientDoc.data() as Map<String, dynamic>;
                    final String name = data['name'] ?? 'No Name';
                    final String mobile = data['mobile'] ?? 'No Mobile';
                    final int cardCount = (data['creditCards'] as List?)?.length ?? 0;
                    final String cardCountText = cardCount == 1 ? '1 card' : '$cardCount cards';

                    return Slidable(
                      key: ValueKey(clientDoc.id),
                      startActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (ctx) => _showDeleteConfirmation(context, clientDoc.id, name),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_forever_rounded,
                            label: 'Delete',
                          ),
                          SlidableAction(
                            onPressed: (ctx) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddClientScreen(clientDoc: clientDoc)),
                              );
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(mobile),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cardCountText, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                            const SizedBox(height: 6),
                            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ClientDetailsScreen(clientId: clientDoc.id)),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddClientScreen()));
        },
        tooltip: 'Add New Client',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String clientId, String clientName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $clientName? This action cannot be undone.'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                FirebaseFirestore.instance.collection('clients').doc(clientId).delete();
                Navigator.of(dialogContext).pop();
                Fluttertoast.showToast(msg: "$clientName deleted.");
              },
            ),
          ],
        );
      },
    );
  }
}
