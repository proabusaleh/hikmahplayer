import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../developer/domain/models/developer_models.dart';

class LogViewerScreen extends StatelessWidget {
  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dev = AppScope.of(context).developer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          PopupMenuButton<LogLevel>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (level) => dev.setLogFilter(level),
            itemBuilder: (_) => LogLevel.values
                .map((l) => PopupMenuItem(
                      value: l,
                      child: Row(
                        children: [
                          Icon(_levelIcon(l), size: 16, color: _levelColor(l)),
                          const SizedBox(width: 8),
                          Text(l.name.toUpperCase()),
                          if (l == dev.logFilter) ...[
                            const Spacer(),
                            const Icon(Icons.check, size: 16),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add sample log',
            onPressed: () {
              dev.log(LogLevel.info, 'Sample info message', tag: 'Demo');
              dev.log(LogLevel.warning, 'Sample warning', tag: 'Demo');
              dev.log(LogLevel.error, 'Sample error with details',
                  tag: 'Demo', stackTrace: 'at Widget.build()\nline 42');
              dev.log(LogLevel.debug, 'Debug: variable x = 42', tag: 'Demo');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear logs',
            onPressed: () => dev.clearLogs(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: dev,
        builder: (context, _) {
          final logs = dev.filteredLogs;

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bug_report,
                      size: 48, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 8),
                  Text('No logs',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Filter: ${dev.logFilter.name.toUpperCase()} or higher',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final entry = logs[index];
              return _LogTile(entry: entry);
            },
          );
        },
      ),
    );
  }

  static IconData _levelIcon(LogLevel level) {
    return switch (level) {
      LogLevel.debug => Icons.bug_report,
      LogLevel.info => Icons.info_outline,
      LogLevel.warning => Icons.warning_amber,
      LogLevel.error => Icons.error_outline,
    };
  }

  static Color _levelColor(LogLevel level) {
    return switch (level) {
      LogLevel.debug => Colors.grey,
      LogLevel.info => Colors.blue,
      LogLevel.warning => Colors.orange,
      LogLevel.error => Colors.red,
    };
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(entry.level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(entry.level), size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                entry.level.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              if (entry.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    entry.tag!,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              const Spacer(),
              Text(
                '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 10, color: theme.colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            entry.message,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          if (entry.stackTrace != null)
            Text(
              entry.stackTrace!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  static Color _color(LogLevel level) {
    return switch (level) {
      LogLevel.debug => Colors.grey,
      LogLevel.info => Colors.blue,
      LogLevel.warning => Colors.orange,
      LogLevel.error => Colors.red,
    };
  }

  static IconData _icon(LogLevel level) {
    return switch (level) {
      LogLevel.debug => Icons.bug_report,
      LogLevel.info => Icons.info_outline,
      LogLevel.warning => Icons.warning_amber,
      LogLevel.error => Icons.error_outline,
    };
  }
}
