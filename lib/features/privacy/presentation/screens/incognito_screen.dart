import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';

class IncognitoScreen extends StatelessWidget {
  const IncognitoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = AppScope.of(context).privacy;

    return Scaffold(
      appBar: AppBar(title: const Text('Incognito Mode')),
      body: ListenableBuilder(
        listenable: privacy,
        builder: (context, _) {
          final isIncognito = privacy.isIncognito;
          final session = privacy.incognitoSession;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(isIncognito: isIncognito, session: session),
              const SizedBox(height: 24),
              if (isIncognito) ...[
                _Section(title: 'Session', children: [
                  _InfoRow(label: 'Started', value: session != null ? _formatTime(session.startedAt) : '—'),
                  _InfoRow(label: 'Activities', value: '${session?.activities ?? 0}'),
                  _InfoRow(label: 'History blocked', value: '${session?.historyBlocked ?? 0}'),
                  _InfoRow(label: 'Recs suppressed', value: '${session?.recommendationsSuppressed ?? 0}'),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => privacy.exitIncognito(),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Exit Incognito'),
                  ),
                ),
              ] else ...[
                const Text(
                  'When incognito mode is active:\n'
                  '• Watch history is not recorded\n'
                  '• Recommendations are suppressed\n'
                  '• History can auto-clean on exit',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => privacy.enterIncognito(),
                    icon: const Icon(Icons.theater_comedy),
                    label: const Text('Enter Incognito'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isIncognito, required this.session});

  final bool isIncognito;
  final dynamic session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isIncognito
            ? Colors.orange.withAlpha(30)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: isIncognito ? Border.all(color: Colors.orange.withAlpha(80)) : null,
      ),
      child: Column(
        children: [
          Icon(
            isIncognito ? Icons.theater_comedy : Icons.visibility,
            size: 48,
            color: isIncognito ? Colors.orange : theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            isIncognito ? 'Incognito Active' : 'Incognito Off',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isIncognito ? Colors.orange : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isIncognito ? 'Your activity is private' : 'Activity is being recorded',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
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
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
