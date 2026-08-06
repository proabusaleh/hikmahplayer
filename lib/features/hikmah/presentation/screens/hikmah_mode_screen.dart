import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/hikmah_service.dart';
import '../../../hikmah/domain/models/hikmah_mode.dart';
import '../../../hikmah/domain/models/session_journal.dart';
import 'learning_goals_screen.dart';

class HikmahModeScreen extends StatelessWidget {
  const HikmahModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hikmah = AppScope.of(context).hikmah;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hikmah Mode'),
        actions: [
          ListenableBuilder(
            listenable: hikmah,
            builder: (context, _) => Switch(
              value: hikmah.config.enabled,
              onChanged: (_) => hikmah.toggleEnabled(),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: hikmah,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(enabled: hikmah.config.enabled, session: hikmah.activeSession),
              const SizedBox(height: 16),
              if (hikmah.config.enabled) ...[
                if (hikmah.activeSession != null) ...[
                  _SessionSection(session: hikmah.activeSession!),
                  const SizedBox(height: 16),
                ],
                _Section(
                  title: 'Mindful Learning',
                  children: [
                    _DashboardTile(
                      icon: Icons.track_changes,
                      title: 'Learning Goals',
                      subtitle: '${hikmah.goals.length} active goals',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LearningGoalsScreen()),
                      ),
                    ),
                    _DashboardTile(
                      icon: Icons.local_fire_department,
                      title: 'Streaks',
                      subtitle: _streakSummary(hikmah),
                      onTap: () => _showStreaks(context, hikmah),
                    ),
                    _DashboardTile(
                      icon: Icons.quiz,
                      title: 'Comprehension',
                      subtitle: hikmah.checks.isEmpty
                          ? 'No checks yet'
                          : '${(hikmah.comprehensionScore * 100).round()}% score',
                      onTap: () => _showChecks(context, hikmah),
                    ),
                    _DashboardTile(
                      icon: Icons.record_voice_over,
                      title: 'Teach-Back',
                      subtitle: '${hikmah.teachBacks.length} completed',
                      onTap: () => _showTeachBacks(context, hikmah),
                    ),
                  ],
                ),
                _Section(
                  title: 'Journal',
                  children: [
                    _DashboardTile(
                      icon: Icons.book,
                      title: 'Session Journal',
                      subtitle: '${hikmah.journalEntries.length} entries',
                      onTap: () => _showJournal(context, hikmah),
                    ),
                    _DashboardTile(
                      icon: Icons.auto_awesome,
                      title: 'Reflections',
                      subtitle: '${hikmah.reflections.length} prompts',
                      onTap: () => _showReflections(context, hikmah),
                    ),
                  ],
                ),
                _Section(
                  title: 'Settings',
                  children: [
                    ListTile(
                      title: const Text('Reflection interval'),
                      subtitle: Text('${hikmah.config.reflectionIntervalMinutes} min'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showIntervalPicker(context, hikmah),
                    ),
                    SwitchListTile(
                      title: const Text('Comprehension checks'),
                      value: hikmah.config.comprehensionChecksEnabled,
                      onChanged: (v) => hikmah.setConfig(
                        hikmah.config.copyWith(comprehensionChecksEnabled: v),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Teach-back'),
                      value: hikmah.config.teachBackEnabled,
                      onChanged: (v) => hikmah.setConfig(
                        hikmah.config.copyWith(teachBackEnabled: v),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Auto-save journals'),
                      value: hikmah.config.autoSaveJournals,
                      onChanged: (v) => hikmah.setConfig(
                        hikmah.config.copyWith(autoSaveJournals: v),
                      ),
                    ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Icon(Icons.self_improvement,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('Enable Hikmah Mode',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Mindful consumption with reflection pauses, '
                        'comprehension checks, teach-back, and session journaling.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _streakSummary(HikmahModeService hikmah) {
    final s = hikmah.streakFor('session');
    if (s.currentStreak == 0) return 'No streak yet';
    return '${s.currentStreak} day streak (best: ${s.longestStreak})';
  }

  void _showStreaks(BuildContext context, HikmahModeService hikmah) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Streaks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final type in ['session', 'reflection', 'comprehension', 'teachBack', 'goal'])
            _StreakTile(streak: hikmah.streakFor(type)),
        ],
      ),
    );
  }

  void _showChecks(BuildContext context, HikmahModeService hikmah) {
    final checks = hikmah.checks;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Comprehension Checks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (checks.isEmpty) const Text('No checks yet.'),
            for (final c in checks)
              ListTile(
                leading: Icon(
                  c.isCorrect == true ? Icons.check_circle : Icons.cancel,
                  color: c.isCorrect == true ? Colors.green : Colors.red,
                ),
                title: Text(c.question, maxLines: 2),
                subtitle: Text(
                  c.isCorrect == null ? 'Unanswered' : (c.isCorrect! ? 'Correct' : 'Incorrect'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTeachBacks(BuildContext context, HikmahModeService hikmah) {
    final tbs = hikmah.teachBacks;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Teach-Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (tbs.isEmpty) const Text('No teach-backs yet.'),
            for (final t in tbs)
              ListTile(
                leading: Icon(
                  t.isCompleted ? Icons.check_circle : Icons.record_voice_over,
                  color: t.isCompleted ? Colors.green : null,
                ),
                title: Text(t.prompt, maxLines: 2),
                subtitle: Text(t.isCompleted ? 'Completed' : 'Pending'),
              ),
          ],
        ),
      ),
    );
  }

  void _showJournal(BuildContext context, HikmahModeService hikmah) {
    final entries = hikmah.journalEntries;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Session Journal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (entries.isEmpty) const Text('No journal entries yet.'),
            for (final e in entries)
              Card(
                child: ListTile(
                  leading: Icon(e.autoSaved ? Icons.auto_awesome : Icons.edit),
                  title: Text(e.title ?? 'Untitled', maxLines: 1),
                  subtitle: Text(e.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReflections(BuildContext context, HikmahModeService hikmah) {
    final refs = hikmah.reflections;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Reflections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (refs.isEmpty) const Text('No reflections yet.'),
            for (final r in refs)
              Card(
                child: ListTile(
                  leading: Icon(
                    r.hasResponse ? Icons.check_circle : Icons.help_outline,
                    color: r.hasResponse ? Colors.green : null,
                  ),
                  title: Text(r.prompt, maxLines: 2),
                  subtitle: Text(r.hasResponse ? r.userResponse! : 'Awaiting response'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, HikmahModeService hikmah) {
    final options = [5, 10, 15, 20, 30];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Reflection Interval', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (final min in options)
            RadioListTile<int>(
              title: Text('$min minutes'),
              value: min,
              groupValue: hikmah.config.reflectionIntervalMinutes,
              onChanged: (v) {
                if (v != null) {
                  hikmah.setConfig(hikmah.config.copyWith(reflectionIntervalMinutes: v));
                }
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.enabled, required this.session});

  final bool enabled;
  final HikmahSession? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: enabled
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            enabled ? Icons.self_improvement : Icons.offline_bolt_outlined,
            size: 40,
            color: enabled ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            enabled ? (session != null ? 'Session Active' : 'Hikmah Enabled') : 'Hikmah Off',
            style: theme.textTheme.titleMedium,
          ),
          if (session?.learningIntent != null) ...[
            const SizedBox(height: 4),
            Text(
              '"${session!.learningIntent}"',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({required this.session});

  final HikmahSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Session', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(value: '${session.reflectionCount}', label: 'Reflections'),
                _MiniStat(value: '${session.comprehensionChecks}', label: 'Checks'),
                _MiniStat(value: '${session.teachBacks}', label: 'Teach-Back'),
                _MiniStat(value: '${session.activityCount}', label: 'Activities'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        streak.currentStreak > 0 ? Icons.local_fire_department : Icons.outlined_flag,
        color: streak.currentStreak > 0 ? Colors.orange : null,
      ),
      title: Text(streak.activityType),
      subtitle: Text(
        streak.currentStreak > 0
            ? '${streak.currentStreak} day streak (best: ${streak.longestStreak})'
            : 'No streak',
      ),
      trailing: streak.isActiveToday
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : null,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
