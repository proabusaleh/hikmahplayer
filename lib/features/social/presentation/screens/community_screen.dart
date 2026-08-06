import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/community_service.dart';
import '../../domain/models/community_chapter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  CommunityService? _community;
  late final TabController _tab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_community == null) {
      _community = AppScope.of(context).community;
      _community!.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _community?.removeListener(_onChanged);
    _tab.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  CommunityService get _svc => _community!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Bookmarks'),
            Tab(text: 'Chapters'),
            Tab(text: 'Comments'),
            Tab(text: 'Playlists'),
            Tab(text: 'Recommendations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BookmarksTab(service: _svc),
          _ChaptersTab(service: _svc),
          _CommentsTab(service: _svc),
          _PlaylistsTab(service: _svc),
          _RecommendationsTab(service: _svc),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }
}

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab({required this.service});
  final CommunityService service;

  @override
  Widget build(BuildContext context) {
    final bookmarks = service.bookmarks;
    if (bookmarks.isEmpty) {
      return const Center(child: Text('No public bookmarks yet'));
    }
    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bm = bookmarks[index];
        return ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(bm.label ?? _fmtDuration(bm.position)),
          subtitle: Text('${bm.authorName} · ${_fmtDuration(bm.position)}'),
          trailing: Text(
            bm.mediaId.substring(0, bm.mediaId.length.clamp(0, 8)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ChaptersTab extends StatelessWidget {
  const _ChaptersTab({required this.service});
  final CommunityService service;

  @override
  Widget build(BuildContext context) {
    final allChapters = <CommunityChapter>[];
    // In real app, iterate known media IDs; for now show empty state
    if (allChapters.isEmpty) {
      return const Center(child: Text('No community chapters yet'));
    }
    return ListView.builder(
      itemCount: allChapters.length,
      itemBuilder: (context, index) {
        final ch = allChapters[index];
        return ListTile(
          leading: const Icon(Icons.bookmark_add),
          title: Text(ch.title),
          subtitle: Text('${ch.authorName} · ${_fmtDuration(ch.startTime)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, size: 16),
              Text('${ch.upvotes}'),
            ],
          ),
        );
      },
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:${s.toString().padLeft(2, '0')}';
  }
}

class _CommentsTab extends StatelessWidget {
  const _CommentsTab({required this.service});
  final CommunityService service;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No comment threads yet'));
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({required this.service});
  final CommunityService service;

  @override
  Widget build(BuildContext context) {
    final playlists = service.playlists;
    if (playlists.isEmpty) {
      return const Center(child: Text('No collaborative playlists yet'));
    }
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final pl = playlists[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(pl.name),
            subtitle: Text(
              '${pl.itemCount} items · ${pl.collaboratorIds.length} collaborators',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _RecommendationsTab extends StatelessWidget {
  const _RecommendationsTab({required this.service});
  final CommunityService service;

  @override
  Widget build(BuildContext context) {
    final recs = service.recommendations;
    if (recs.isEmpty) {
      return const Center(child: Text('No recommendations yet'));
    }
    return ListView.builder(
      itemCount: recs.length,
      itemBuilder: (context, index) {
        final rec = recs[index];
        return Card(
          child: ListTile(
            leading: rec.mediaArtwork != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      rec.mediaArtwork!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.movie),
                    ),
                  )
                : const Icon(Icons.movie),
            title: Text(rec.mediaTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${rec.authorName} · ${rec.likes} likes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
