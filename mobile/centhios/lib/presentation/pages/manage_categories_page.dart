import 'package:centhios/app_theme.dart';
import 'package:centhios/data/repositories/categories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageCategoriesPage extends ConsumerWidget {
  const ManageCategoriesPage({super.key});

  void _showCategoryDialog(BuildContext context, {String? category}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(originalCategoryName: category),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Dismissible(
                key: Key(category),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  ref.read(categoriesRepositoryProvider).deleteCategory(category);
                  ref.invalidate(categoriesProvider);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text('Category "$category" deleted.'),
                      backgroundColor: Colors.red,
                    ));
                },
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(category),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _showCategoryDialog(context, category: category),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  final String? originalCategoryName;
  const _CategoryDialog({this.originalCategoryName});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool get isEditing => widget.originalCategoryName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.originalCategoryName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final newName = _nameController.text.trim();
      try {
        final repo = ref.read(categoriesRepositoryProvider);
        if (isEditing) {
          // The backend doesn't support editing, so we delete then create.
          // This is not ideal, but works with the current backend.
          if (widget.originalCategoryName! != newName) {
            await repo.deleteCategory(widget.originalCategoryName!);
            await repo.createCategory(newName);
          }
        } else {
          await repo.createCategory(newName);
        }
        ref.invalidate(categoriesProvider);
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'New Category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Category Name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a category name.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
} 