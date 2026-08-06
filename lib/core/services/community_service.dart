import 'package:flutter/foundation.dart';

import '../../features/social/domain/models/best_moment.dart';
import '../../features/social/domain/models/bookmark.dart';
import '../../features/social/domain/models/collaborative_playlist.dart';
import '../../features/social/domain/models/comment_thread.dart';
import '../../features/social/domain/models/community_chapter.dart';
import '../../features/social/domain/models/reaction_heatmap.dart';
import '../../features/social/domain/models/shared_recommendation.dart';

class CommunityService extends ChangeNotifier {
  final List<Bookmark> _bookmarks = [];
  final Map<String, List<CommunityChapter>> _chapters = {};
  final Map<String, List<CommentThread>> _threads = {};
  final Map<String, ReactionHeatmap> _heatmaps = {};
  final List<CollaborativePlaylist> _playlists = [];
  final List<BestMoment> _moments = [];
  final List<SharedRecommendation> _recommendations = [];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  List<CommunityChapter> chaptersFor(String mediaId) =>
      List.unmodifiable(_chapters[mediaId] ?? []);

  List<CommentThread> threadsFor(String mediaId) =>
      List.unmodifiable(_threads[mediaId] ?? []);

  ReactionHeatmap? heatmapFor(String mediaId) => _heatmaps[mediaId];

  List<CollaborativePlaylist> get playlists =>
      List.unmodifiable(_playlists);

  List<BestMoment> get moments => List.unmodifiable(_moments);

  List<SharedRecommendation> get recommendations =>
      List.unmodifiable(_recommendations);

  // --- Bookmarks ---

  Bookmark addBookmark({
    required String mediaId,
    required String authorId,
    required String authorName,
    required Duration position,
    String? label,
    bool isPublic = true,
  }) {
    final bookmark = Bookmark(
      id: 'bm-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      authorId: authorId,
      authorName: authorName,
      position: position,
      label: label,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );
    _bookmarks.insert(0, bookmark);
    notifyListeners();
    return bookmark;
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  List<Bookmark> bookmarksFor(String mediaId) =>
      _bookmarks.where((b) => b.mediaId == mediaId).toList();

  // --- Community Chapters ---

  CommunityChapter addChapter({
    required String mediaId,
    required String authorId,
    required String authorName,
    required String title,
    required Duration startTime,
    Duration? endTime,
  }) {
    final chapter = CommunityChapter(
      id: 'ch-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      authorId: authorId,
      authorName: authorName,
      title: title,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
    );
    _chapters.putIfAbsent(mediaId, () => []).add(chapter);
    _chapters[mediaId]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
    return chapter;
  }

  void upvoteChapter(String mediaId, String chapterId, String userId) {
    final list = _chapters[mediaId];
    if (list == null) return;
    final idx = list.indexWhere((c) => c.id == chapterId);
    if (idx < 0) return;
    final old = list[idx];
    final upvoted = old.upvotedBy.contains(userId);
    final upvotedBy = Set<String>.from(old.upvotedBy);
    if (upvoted) {
      upvotedBy.remove(userId);
    } else {
      upvotedBy.add(userId);
    }
    list[idx] = old.copyWith(upvotes: upvotedBy.length, upvotedBy: upvotedBy);
    notifyListeners();
  }

  // --- Comment Threads ---

  CommentThread addThread({
    required String mediaId,
    required Duration position,
    required String authorId,
    required String authorName,
    required String text,
  }) {
    final comment = Comment(
      id: 'c-${DateTime.now().microsecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      text: text,
      createdAt: DateTime.now(),
    );
    final thread = CommentThread(
      id: 'ct-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      position: position,
      comments: [comment],
      createdAt: DateTime.now(),
    );
    _threads.putIfAbsent(mediaId, () => []).add(thread);
    _threads[mediaId]!.sort((a, b) => a.position.compareTo(b.position));
    notifyListeners();
    return thread;
  }

  void addComment({
    required String mediaId,
    required String threadId,
    required String authorId,
    required String authorName,
    required String text,
  }) {
    final list = _threads[mediaId];
    if (list == null) return;
    final idx = list.indexWhere((t) => t.id == threadId);
    if (idx < 0) return;
    final comment = Comment(
      id: 'c-${DateTime.now().microsecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      text: text,
      createdAt: DateTime.now(),
    );
    final old = list[idx];
    list[idx] = old.copyWith(comments: [...old.comments, comment]);
    notifyListeners();
  }

  void likeComment(String mediaId, String threadId, String commentId, String userId) {
    final list = _threads[mediaId];
    if (list == null) return;
    final tIdx = list.indexWhere((t) => t.id == threadId);
    if (tIdx < 0) return;
    final thread = list[tIdx];
    final cIdx = thread.comments.indexWhere((c) => c.id == commentId);
    if (cIdx < 0) return;
    final old = thread.comments[cIdx];
    final liked = old.likedBy.contains(userId);
    final likedBy = Set<String>.from(old.likedBy);
    if (liked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    final comments = [...thread.comments];
    comments[cIdx] = old.copyWith(likes: likedBy.length, likedBy: likedBy);
    list[tIdx] = thread.copyWith(comments: comments);
    notifyListeners();
  }

  // --- Reaction Heatmap ---

  void addReaction({
    required String mediaId,
    required String emoji,
    required Duration position,
    required String authorId,
  }) {
    final existing = _heatmaps[mediaId] ?? const ReactionHeatmap(mediaId: '');
    final entry = HeatmapEntry(emoji: emoji, position: position, authorId: authorId);
    _heatmaps[mediaId] = existing.copyWith(entries: [...existing.entries, entry]);
    notifyListeners();
  }

  // --- Collaborative Playlists ---

  CollaborativePlaylist createPlaylist({
    required String name,
    required String creatorId,
    String? description,
  }) {
    final playlist = CollaborativePlaylist(
      id: 'pl-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      creatorId: creatorId,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _playlists.insert(0, playlist);
    notifyListeners();
    return playlist;
  }

  void addToPlaylist(String playlistId, String mediaId, String userId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final old = _playlists[idx];
    final entry = CollaborativePlaylistEntry(
      mediaId: mediaId,
      addedBy: userId,
      addedAt: DateTime.now(),
    );
    _playlists[idx] = old.copyWith(entries: [...old.entries, entry]);
    notifyListeners();
  }

  void removeFromPlaylist(String playlistId, String mediaId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final old = _playlists[idx];
    _playlists[idx] = old.copyWith(
      entries: old.entries.where((e) => e.mediaId != mediaId).toList(),
    );
    notifyListeners();
  }

  void addCollaborator(String playlistId, String userId) {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final old = _playlists[idx];
    _playlists[idx] = old.copyWith(
      collaboratorIds: {...old.collaboratorIds, userId},
    );
    notifyListeners();
  }

  // --- Best Moments ---

  BestMoment addMoment({
    required String mediaId,
    required String authorId,
    required String authorName,
    required String title,
    required Duration startTime,
    required Duration endTime,
    String? thumbnailPath,
  }) {
    final moment = BestMoment(
      id: 'bm-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      authorId: authorId,
      authorName: authorName,
      title: title,
      startTime: startTime,
      endTime: endTime,
      thumbnailPath: thumbnailPath,
      createdAt: DateTime.now(),
    );
    _moments.insert(0, moment);
    notifyListeners();
    return moment;
  }

  void likeMoment(String momentId, String userId) {
    final idx = _moments.indexWhere((m) => m.id == momentId);
    if (idx < 0) return;
    final old = _moments[idx];
    final liked = old.likedBy.contains(userId);
    final likedBy = Set<String>.from(old.likedBy);
    if (liked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    _moments[idx] = old.copyWith(likes: likedBy.length, likedBy: likedBy);
    notifyListeners();
  }

  // --- Recommendations ---

  SharedRecommendation shareRecommendation({
    required String mediaId,
    required String mediaTitle,
    required String authorId,
    required String authorName,
    required String note,
    String? mediaArtwork,
  }) {
    final rec = SharedRecommendation(
      id: 'rec-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      mediaTitle: mediaTitle,
      mediaArtwork: mediaArtwork,
      authorId: authorId,
      authorName: authorName,
      note: note,
      createdAt: DateTime.now(),
    );
    _recommendations.insert(0, rec);
    notifyListeners();
    return rec;
  }

  void likeRecommendation(String recId, String userId) {
    final idx = _recommendations.indexWhere((r) => r.id == recId);
    if (idx < 0) return;
    final old = _recommendations[idx];
    final liked = old.likedBy.contains(userId);
    final likedBy = Set<String>.from(old.likedBy);
    if (liked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    _recommendations[idx] = old.copyWith(likes: likedBy.length, likedBy: likedBy);
    notifyListeners();
  }

  void reset() {
    _bookmarks.clear();
    _chapters.clear();
    _threads.clear();
    _heatmaps.clear();
    _playlists.clear();
    _moments.clear();
    _recommendations.clear();
    notifyListeners();
  }
}
