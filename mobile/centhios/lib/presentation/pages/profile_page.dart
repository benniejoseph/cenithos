import 'package:centhios/app_theme.dart';
import 'package:centhios/core/services/firebase_providers.dart';
import 'package:centhios/presentation/pages/auth/login_page.dart';
import 'package:centhios/presentation/pages/categories_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primary.withOpacity(0.8),
                          child: Text(
                            user?.displayName?.substring(0, 1) ??
                                user?.email?.substring(0, 1).toUpperCase() ??
                                'A',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'Centhios User',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'No email provided',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(CupertinoIcons.settings_solid),
                        title: const Text('Settings'),
                        onTap: () {
                          // Could navigate to a general settings page if more settings are added
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(CupertinoIcons.tag_solid),
                        title: const Text('Manage Categories'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoriesPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                  ),
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    }
                  },
                  child: const Text('LOGOUT'),
                ),
                const SizedBox(height: 100), // Space for floating nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }
}
