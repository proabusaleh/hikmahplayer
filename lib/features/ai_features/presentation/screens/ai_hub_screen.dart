import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/ai_service.dart';
import '../../../hikmah/presentation/screens/hikmah_mode_screen.dart';
import 'flashcard_screen.dart';
import 'knowledge_graph_screen.dart';
import 'summary_screen.dart';
import 'transcript_screen.dart';

class AiHubScreen extends StatefulWidget {
  const AiHubScreen({super.key});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  AIService? _ai;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ai ??= AppScope.of(context).ai;
  }

  AIService get _svc => _ai!;

  @override
  Widget build(BuildContext context) {
    final running = _svc.status.values
        .where((s) => s == AiAnalysisStatus.running)
        .length;
    final done = _svc.status.values
        .where((s) => s == AiAnalysisStatus.done)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (running > 0 || done > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      running > 0 ? Icons.auto_awesome : Icons.check_circle_outline,
                      color: running > 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        running > 0
                            ? 'Analysing $running track(s)…'
                            : '$done track(s) analysed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text('Smart Tools', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _AiTile(
            icon: Icons.subtitles,
            title: 'Transcript',
            subtitle: 'Search & navigate speech',
            route: MaterialPageRoute<void>(
              builder: (_) => const TranscriptScreen(),
            ),
          ),
          _AiTile(
            icon: Icons.summarize,
            title: 'Summary',
            subtitle: 'Extractive text summaries',
            route: MaterialPageRoute<void>(
              builder: (_) => const SummaryScreen(),
            ),
          ),
          _AiTile(
            icon: Icons.bookmarks,
            title: 'Chapters',
            subtitle: 'Auto-segmented structure',
            onTap: () {},
          ),
          _AiTile(
            icon: Icons.lightbulb_outline,
            title: 'Concepts & Notes',
            subtitle: 'Key ideas extracted',
            onTap: () {},
          ),
          _AiTile(
            icon: Icons.quiz_outlined,
            title: 'Quiz',
            subtitle: 'Generate questions from content',
            onTap: () {},
          ),
          _AiTile(
            icon: Icons.style,
            title: 'Flashcards',
            subtitle: 'Spaced-repetition study cards',
            route: MaterialPageRoute<void>(
              builder: (_) => const FlashcardScreen(),
            ),
          ),
          _AiTile(
            icon: Icons.account_tree_outlined,
            title: 'Knowledge Graph',
            subtitle: 'Concept relationships',
            route: MaterialPageRoute<void>(
              builder: (_) => const KnowledgeGraphScreen(),
            ),
          ),
          _AiTile(
            icon: Icons.record_voice_over,
            title: 'Voice Commands',
            subtitle: 'Hands-free navigation',
            onTap: () {},
          ),
          _AiTile(
            icon: Icons.speed,
            title: 'RSVP',
            subtitle: 'Rapid serial visual presentation',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          Text('Mindful Learning', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _AiTile(
            icon: Icons.self_improvement,
            title: 'Hikmah Mode',
            subtitle: 'Reflection, comprehension checks, teach-back, journaling',
            route: MaterialPageRoute<void>(
              builder: (_) => const HikmahModeScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiTile extends StatelessWidget {
  const _AiTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final MaterialPageRoute<void>? route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? (route != null ? () => Navigator.push(context, route!) : null),
      ),
    );
  }
}
