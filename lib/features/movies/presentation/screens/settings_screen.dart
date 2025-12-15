// Settings screen for account actions and profile controls.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/auth_service.dart';
import '../providers/profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profileState = ref.watch(profileProvider);
    final authService = ref.read(authServiceProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    final headerStyle = TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final contentStyle = const TextStyle(color: Colors.blue, fontSize: 16);
    final sectionHeaderStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Account", style: sectionHeaderStyle),
            const SizedBox(height: 20),

            // Identification Section
            Text("Identification", style: headerStyle),
            const SizedBox(height: 15),
            _buildInfoRow(
              "Display Name",
              profileState.name,
              headerStyle,
              contentStyle,
            ),
            _buildInfoRow(
              "Email",
              user?.email ?? "N/A",
              headerStyle,
              contentStyle,
            ),
            _buildInfoRow(
              "User ID",
              user?.uid ?? "N/A",
              headerStyle,
              contentStyle,
            ),

            const Divider(color: Colors.grey, height: 40),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                child: const Text(
                  "Log out",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                ),
                onPressed: () => _showDeleteConfirmation(
                  context,
                  ref,
                  authService,
                  profileNotifier,
                ),
                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 5),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    AuthService auth,
    ProfileNotifier profile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This action is irreversible. All your data, including your wishlist and ratings, will be permanently deleted.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                // Clean up data (Firestore & Hive)
                await profile.deleteUserData();
                // Delete Auth Account
                await auth.deleteAccount();
                if (context.mounted) {
                  // Navigate to Login
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Error deleting account: $e. You may need to re-login first.",
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
