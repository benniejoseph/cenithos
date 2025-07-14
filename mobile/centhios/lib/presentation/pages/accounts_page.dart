import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/debt_model.dart';
import 'package:centhios/data/models/investment_model.dart';
import 'package:centhios/data/repositories/debts_repository.dart';
import 'package:centhios/data/repositories/investments_repository.dart';
import 'package:centhios/presentation/widgets/glassmorphic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final investmentsProvider = FutureProvider<List<Investment>>((ref) async {
  return ref.watch(investmentsRepositoryProvider).getInvestments();
});

final debtsProvider = FutureProvider<List<Debt>>((ref) async {
  return ref.watch(debtsRepositoryProvider).getDebts();
});

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  Future<void> _refreshAccounts(WidgetRef ref) async {
    ref.refresh(investmentsProvider);
    ref.refresh(debtsProvider);
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
        context: context,
        builder: (context) {
          return AddAccountDialog();
        });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final investmentsAsync = ref.watch(investmentsProvider);
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
        backgroundColor: AppTheme.accent,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Accounts', style: theme.textTheme.headlineLarge),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refreshAccounts(ref),
                child: investmentsAsync.when(
                  data: (investments) => debtsAsync.when(
                    data: (debts) =>
                        _buildAccountList(context, investments, debts, ref),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('Error loading debts: $err')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading investments: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(BuildContext context, List<Investment> investments,
      List<Debt> debts, WidgetRef ref) {
    if (investments.isEmpty && debts.isEmpty) {
      return Center(
          child: Text('No accounts found.',
              style: Theme.of(context).textTheme.bodyLarge));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (investments.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Investments',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          ...investments
              .map((investment) =>
                  _buildInvestmentCard(context, investment, ref))
              .toList(),
        ],
        if (debts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: Text('Debts / Liabilities',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          ...debts.map((debt) => _buildDebtCard(context, debt, ref)).toList(),
        ]
      ],
    );
  }

  Widget _buildInvestmentCard(
      BuildContext context, Investment investment, WidgetRef ref) {
    return Dismissible(
      key: Key(investment.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref
            .read(investmentsRepositoryProvider)
            .deleteInvestment(investment.id);
        ref.refresh(investmentsProvider);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) => AddAccountDialog(investment: investment));
        },
        child: _buildAccountCard(
          context,
          accountName: investment.name,
          accountType: investment.type,
          balance: NumberFormat.currency(symbol: '₹', decimalDigits: 2)
              .format(investment.currentValue),
          icon: Icons.trending_up,
          color: AppTheme.accent,
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, WidgetRef ref) {
    return Dismissible(
      key: Key(debt.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ref.read(debtsRepositoryProvider).deleteDebt(debt.id);
        ref.refresh(debtsProvider);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) => AddAccountDialog(debt: debt));
        },
        child: _buildAccountCard(
          context,
          accountName: debt.name,
          accountType: debt.type,
          balance: NumberFormat.currency(symbol: '₹', decimalDigits: 2)
              .format(debt.balance),
          icon: Icons.trending_down,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String accountName,
    required String accountType,
    required String balance,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(accountName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(accountType,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            Text(balance,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class AddAccountDialog extends ConsumerStatefulWidget {
  final Investment? investment;
  final Debt? debt;
  const AddAccountDialog({super.key, this.investment, this.debt});

  @override
  _AddAccountDialogState createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _type = '';
  double _balance = 0;
  String _accountType = 'Investment'; // or 'Debt'

  @override
  void initState() {
    super.initState();
    if (widget.investment != null) {
      _accountType = 'Investment';
      _name = widget.investment!.name;
      _type = widget.investment!.type;
      _balance = widget.investment!.currentValue;
    } else if (widget.debt != null) {
      _accountType = 'Debt';
      _name = widget.debt!.name;
      _type = widget.debt!.type;
      _balance = widget.debt!.balance;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_accountType == 'Investment') {
        final investmentRepo = ref.read(investmentsRepositoryProvider);
        if (widget.investment != null) {
          final updatedInvestment = widget.investment!
              .copyWith(name: _name, type: _type, currentValue: _balance);
          await investmentRepo.updateInvestment(updatedInvestment);
        } else {
          final newInvestment = Investment(
              id: '',
              userId: '',
              name: _name,
              type: _type,
              currentValue: _balance,
              investedAmount: _balance);
          await investmentRepo.createInvestment(newInvestment);
        }
        ref.refresh(investmentsProvider);
      } else {
        final debtRepo = ref.read(debtsRepositoryProvider);
        if (widget.debt != null) {
          final updatedDebt = widget.debt!
              .copyWith(name: _name, type: _type, balance: _balance);
          await debtRepo.updateDebt(updatedDebt);
        } else {
          final newDebt = Debt(
              id: '',
              userId: '',
              name: _name,
              type: _type,
              balance: _balance,
              interestRate: 0,
              minimumPayment: 0);
          await debtRepo.createDebt(newDebt);
        }
        ref.refresh(debtsProvider);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.investment != null || widget.debt != null
          ? 'Edit Account'
          : 'Add Account'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _accountType,
                items: ['Investment', 'Debt'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (widget.investment != null || widget.debt != null)
                    ? null
                    : (String? newValue) {
                        setState(() {
                          _accountType = newValue!;
                          _type = '';
                        });
                      },
                decoration: const InputDecoration(labelText: 'Account Type'),
              ),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _type,
                decoration: const InputDecoration(
                    labelText: 'Type (e.g., Stock, Loan)'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a type' : null,
                onSaved: (value) => _type = value!,
              ),
              TextFormField(
                initialValue: _balance.toString(),
                decoration:
                    const InputDecoration(labelText: 'Balance / Current Value'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an amount' : null,
                onSaved: (value) => _balance = double.parse(value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
