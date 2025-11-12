import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:priyanakaenterprises/screens/details/client_detials_screen.dart';

class ClientSearchDelegate extends SearchDelegate<String> {
  final String distributorId;

  ClientSearchDelegate({required this.distributorId});

  @override
  String get searchFieldLabel => 'Search by name or mobile';

  /// Builds the "clear" button in the search bar
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () {
          query = ''; // Clear the search query
        },
      ),
    ];
  }

  /// Builds the "back" button
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, ''); // Close the search, returning an empty string
      },
    );
  }

  /// Builds the results list based on the query
  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Please enter a name or mobile number.'),
      );
    }

    // --- This is the core search logic ---
    Query searchQuery;
    final clientsRef = FirebaseFirestore.instance.collection('clients');
    
    // Check if query is a 10-digit mobile number
    final bool isMobileSearch =
        query.trim().length == 10 && int.tryParse(query.trim()) != null;

    if (isMobileSearch) {
      // Search by exact mobile number
      searchQuery = clientsRef
          .where('distributorId', isEqualTo: distributorId)
          .where('mobile', isEqualTo: query.trim());
    } else {
      // Search by name (case-sensitive "starts with")
      // \uf8ff is a high-code-point character that acts as a "cap"
      searchQuery = clientsRef
          .where('distributorId', isEqualTo: distributorId)
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThanOrEqualTo: '${query.trim()}\uf8ff');
    }
    // --- End of search logic ---

    return StreamBuilder<QuerySnapshot>(
      stream: searchQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('An error occurred.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No clients found matching "$query".'),
          );
        }

        final results = snapshot.data!.docs;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final doc = results[index];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name'] ?? 'No Name';
            final mobile = data['mobile'] ?? 'No Mobile';
            final int cardCount = (data['creditCards'] as List?)?.length ?? 0;

            return ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(name),
              subtitle: Text(mobile),
              trailing: Text('$cardCount cards'),
              onTap: () {
                // Navigate to the client's details screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientDetailsScreen(clientId: doc.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Builds the suggestions list (shown while typing)
  @override
  Widget buildSuggestions(BuildContext context) {
    // We can show suggestions here, but for simplicity and to reduce
    // read costs, we will only show results when the user presses "search".
    // buildResults() will be called when the user submits.
    
    if (query.trim().isEmpty) {
       return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text('Search for your clients', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // You could return a simple "Loading..." or suggestions here.
    // For this app, we'll let them hit "search" to see results.
    return const Center(
      child: Text('Press "Enter" or search button to find clients.'),
    );
  }
}