import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/hikmah_service.dart';
import '../../../hikmah/domain/models/learning_goal.dart';

class LearningGoalsScreen extends StatelessWidget {
  const LearningGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hikmah = AppScope.of(context).hikmah;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context, hikmah),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: hikmah,
        builder: (context, _) {
          final goals = hikmah.goals;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.track_changes,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No Learning Goals',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Set goals to track your learning progress.',
                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddGoalDialog(context, hikmah),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Goal'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _GoalCard(
                goal: goal,
                onComplete: () => hikmah.completeGoal(goal.id),
                onRemove: () => hikmah.removeGoal(goal.id),
                onCompleteMilestone: (mId) =>
                    hikmah.completeMilestone(goal.id, mId),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, HikmahModeService hikmah) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Learning Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Goal title',
                hintText: 'e.g. Master 50 flashcards',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              hikmah.addGoal(
                title: titleController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onComplete,
    required this.onRemove,
    required this.onCompleteMilestone,
  });

  final LearningGoal goal;
  final VoidCallback onComplete;
  final VoidCallback onRemove;
  final ValueChanged<String> onCompleteMilestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  goal.completed ? Icons.check_circle : Icons.track_changes,
                  color: goal.completed ? Colors.green : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: goal.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (goal.description != null)
                        Text(
                          goal.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'complete') onComplete();
                    if (v == 'remove') onRemove();
                  },
                  itemBuilder: (_) => [
                    if (!goal.completed)
                      const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            if (goal.milestones.isNotEmpty) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 8),
              for (final m in goal.milestones)
                CheckboxListTile(
                  value: m.completed,
                  onChanged: m.completed
                      ? null
                      : (_) => onCompleteMilestone(m.id),
                  title: Text(
                    m.title,
                    style: TextStyle(
                      decoration: m.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
            if (goal.targetDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Target: ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: goal.isOverdue ? Colors.red : theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
