import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_scope.dart';

class PlaylistCreateScreen extends StatefulWidget {
  const PlaylistCreateScreen({super.key});

  @override
  State<PlaylistCreateScreen> createState() => _PlaylistCreateScreenState();
}

class _PlaylistCreateScreenState extends State<PlaylistCreateScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final id = 'pl_${DateTime.now().microsecondsSinceEpoch}';
    await AppScope.of(context).playlists.create(id: id, name: name);
    if (mounted) context.pushReplacement('/home/playlists/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New playlist'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Create'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Playlist name',
                hintText: 'e.g. Evening Recitations',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}
