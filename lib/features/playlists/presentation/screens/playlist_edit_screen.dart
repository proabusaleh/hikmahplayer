import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/playlist_repository.dart';

class PlaylistEditScreen extends StatefulWidget {
  const PlaylistEditScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

class _PlaylistEditScreenState extends State<PlaylistEditScreen> {
  PlaylistRepository? _repo;
  final _controller = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo == null) {
      _repo = AppScope.of(context).playlists;
      _load();
    }
  }

  Future<void> _load() async {
    final playlist = await _repo!.byId(widget.playlistId);
    if (!mounted) return;
    setState(() {
      _controller.text = playlist?.name ?? '';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await _repo!.rename(widget.playlistId, name);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit playlist'),
        actions: [
          TextButton(
            onPressed: _loaded ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'Playlist name'),
        ),
      ),
    );
  }
}
