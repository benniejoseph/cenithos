import 'package:centhios/presentation/pages/manage_categories_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit, or remove transaction categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesPage(),
                ),
              );
            },
          ),
          const Divider(),
          // Other settings will go here in the future
        ],
      ),
    );
  }
} 