import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/folder_repository.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  FolderRepository? _folders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _folders ??= AppScope.of(context).folders;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = _folders!;
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: StreamBuilder<List<Folder>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final folders = snapshot.data ?? const <Folder>[];
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_copy_outlined,
                    size: 72,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text('No folders indexed', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Scanned media folders will be listed here.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: folders.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Icon(
                  folder.isPinned ? Icons.push_pin : Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(folder.name),
                subtitle: Text(folder.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text('${folder.mediaCount}'),
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
