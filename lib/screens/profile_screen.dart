import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:priyanakaenterprises/screens/login_screen.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                
                // Call the signOut method
                context.read<AuthProvider>().signOut();
                
                // Navigate all the way back to the LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false, // Remove all routes
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Handles the "Change Password" action
  void _handleChangePassword(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Text('A password reset email will be sent to:\n\n$email\n\n'
              'Follow the instructions in the email to set a new password.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Send Email'),
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                bool success = await authProvider.forgotPassword(email);

                if (success) {
                  toastification.show(
  type: ToastificationType.success, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('Password reset email sent successfully!'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);

                } else {
                  toastification.show(
  type: ToastificationType.error, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('Failed to send password reset email. Please try again.'),
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
);  
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get all user and distributor data from the provider
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final distributorName = authProvider.distributorName ?? 'Distributor';
    final distributorId = authProvider.distributorId ?? '...';
    final userEmail = user?.email ?? 'No Email';
    
    // Generate the unique client form link
    final clientFormLink =
        'https://formsapp-five.vercel.app/form/$distributorId';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Distributor Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      distributorName.isNotEmpty ? distributorName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    distributorName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Distributor ID: $distributorId',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Client Form Link
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('My Client Form Link'),
            subtitle: Text(
              clientFormLink,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.copy_rounded),
            onTap: () {
              Clipboard.setData(ClipboardData(text: clientFormLink)).then((_) {
                toastification.show(
  type: ToastificationType.success, // error type gives red styling
  style: ToastificationStyle.fillColored,
  title: Text('Client form link copied to clipboard!'),   
  autoCloseDuration: const Duration(seconds: 5), // similar to Toast.LENGTH_LONG
  alignment: Alignment.bottomCenter,
  );
                });
            },
          ),
          
          const Divider(),

          // Change Password
          ListTile(
            leading: const Icon(Icons.lock_reset_rounded),
            title: const Text('Change Password'),
            onTap: () {
              _handleChangePassword(context, userEmail);
            },
          ),
          
          const Divider(),
          
          // App Version
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'), // Static version number
            onTap: () {},
          ),
          
          const SizedBox(height: 48),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showLogoutConfirmation(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}