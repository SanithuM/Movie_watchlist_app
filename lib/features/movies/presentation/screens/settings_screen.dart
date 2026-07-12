// Settings screen for account actions and profile controls.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/auth_service.dart';
import '../providers/profile_provider.dart';
import 'import_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profileState = ref.watch(profileProvider);
    final authService = ref.read(authServiceProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    final headerStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.6),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    final contentStyle = const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500);
    final sectionHeaderStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

            Divider(color: Colors.grey[900], height: 40),

            Text("Data Management", style: sectionHeaderStyle),
            const SizedBox(height: 15),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.import_export,
                color: Color(0xFFFFD200),
              ),
              title: const Text(
                'Import TV Time Data',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportScreen(),
                  ),
                );
              },
            ),

            Divider(color: Colors.grey[900], height: 40),
            const SizedBox(height: 20),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD200),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                child: const Text(
                  "LOG OUT",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showDeleteConfirmation(
                  context,
                  ref,
                  authService,
                  profileNotifier,
                ),
                child: const Text(
                  "DELETE ACCOUNT",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
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
        backgroundColor: const Color(0xFF161616),
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action is irreversible. All your data, including your wishlist and ratings, will be permanently deleted.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
