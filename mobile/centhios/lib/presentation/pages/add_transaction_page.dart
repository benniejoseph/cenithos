import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:centhios/core/config.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<ShadFormState>();
  final _amountController = TextEditingController();
  String _transactionType = 'expense';
  String _category = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _transactionTypes = ['expense', 'income'];
  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Other'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to add a transaction.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final url = '${AppConfig.firebaseFunctionsBaseUrl}/addTransaction';

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'uid': user.uid,
            'amount': double.parse(_amountController.text),
            'type': _transactionType,
            'category': _category,
            'date': _selectedDate.toIso8601String().split('T').first,
          }),
        );

        if (response.statusCode == 201 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction saved successfully!')),
          );
          // Potentially clear form or navigate
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save transaction: ${response.body}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ShadCard(
              title: Text('Add a Transaction', style: theme.textTheme.h3),
              description: const Text('Fill in the details below.'),
              child: ShadForm(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ShadInputFormField(
                      id: 'amount',
                      controller: _amountController,
                      label: const Text('Amount'),
                      placeholder: const Text('Enter transaction amount'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v.isEmpty) return 'Amount is required.';
                        if (double.tryParse(v) == null)
                          return 'Please enter a valid number.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadSelect<String>(
                      initialValue: _transactionType,
                      placeholder: const Text('Select a type'),
                      options: _transactionTypes
                          .map((type) =>
                              ShadOption(value: type, child: Text(type)))
                          .toList(),
                      selectedOptionBuilder: (context, value) => Text(value),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _transactionType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ShadSelect<String>(
                      initialValue: _category,
                      placeholder: const Text('Select a category'),
                      options: _categories
                          .map(
                              (cat) => ShadOption(value: cat, child: Text(cat)))
                          .toList(),
                      selectedOptionBuilder: (context, value) => Text(value),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Date: ${_selectedDate.toLocal()}"
                                .split(' ')[0])),
                        ShadButton.outline(
                          onPressed: () => _selectDate(context),
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ShadButton(
                      onPressed: _isLoading ? null : _saveTransaction,
                      child: _isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Text('Save Transaction'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
