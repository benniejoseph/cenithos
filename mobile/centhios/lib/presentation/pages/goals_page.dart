import 'package:centhios/app_theme.dart';
import 'package:centhios/data/models/goal_model.dart';
import 'package:centhios/data/repositories/goals_repository.dart';
import 'package:centhios/presentation/widgets/create_goal_dialog.dart';
import 'package:centhios/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  final repository = ref.watch(goalsRepositoryProvider);
  ref.onDispose(() {}); // Ensure provider is disposed
  return repository.getGoals();
});

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(goalsProvider.future),
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return const Center(
                  child: Text("You haven't set any goals yet."),
                );
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: goals.length + 1, // Add 1 for the spacer
                itemBuilder: (context, index) {
                  if (index == goals.length) {
                    return const SizedBox(height: 100); // Spacer at the end
                  }
                  final goal = goals[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Dismissible(
                      key: Key(goal.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref.read(goalsRepositoryProvider).deleteGoal(goal.id);
                        ref.invalidate(goalsProvider);
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_sweep_rounded,
                            color: AppTheme.textPrimary),
                      ),
                      child: GestureDetector(
                        onTap: () => showCreateGoalDialog(context, ref,
                            goalToEdit: goal),
                        child: GoalCard(goal: goal),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => showCreateGoalDialog(context, ref),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: AppTheme.textPrimary),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Financial Goals',
          style: AppTheme.theme.textTheme.headlineMedium),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}
