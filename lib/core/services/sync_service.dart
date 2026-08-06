import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/social/domain/models/avatar_config.dart';
import '../../features/social/domain/models/emoji_reaction.dart';
import '../../features/social/domain/models/party_poll.dart';
import '../../features/social/domain/models/party_quiz.dart';
import '../../features/social/domain/models/party_settings.dart';
import '../../features/social/domain/models/shared_note.dart';
import '../../features/social/domain/models/voice_chat.dart';

/// Role of a member inside a watch party.
enum PartyRole { host, guest }

/// A member currently present in a watch party.
class PartyMember {
  final String id;
  final String name;
  final PartyRole role;
  final DateTime joinedAt;

  const PartyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory PartyMember.host(String id, String name) =>
      PartyMember(id: id, name: name, role: PartyRole.host, joinedAt: DateTime.now());

  PartyMember copyWith({PartyRole? role}) => PartyMember(
        id: id,
        name: name,
        role: role ?? this.role,
        joinedAt: joinedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory PartyMember.fromJson(Map<String, dynamic> json) => PartyMember(
        id: json['id'] as String,
        name: json['name'] as String,
        role: PartyRole.values.asNameMap()[json['role']] ?? PartyRole.guest,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );
}

/// A chat message inside a watch party.
class PartyMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  const PartyMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory PartyMessage.fromJson(Map<String, dynamic> json) => PartyMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}

/// Playback position shared with the party (drives synced seeking).
class PartyPlaybackState {
  final String? mediaId;
  final String? mediaTitle;
  final Duration position;
  final bool isPlaying;
  final Duration? duration;
  final String? sourceMemberId;

  const PartyPlaybackState({
    this.mediaId,
    this.mediaTitle,
    required this.position,
    required this.isPlaying,
    this.duration,
    this.sourceMemberId,
  });

  PartyPlaybackState copyWith({
    String? mediaId,
    String? mediaTitle,
    Duration? position,
    bool? isPlaying,
    Duration? duration,
    String? sourceMemberId,
  }) =>
      PartyPlaybackState(
        mediaId: mediaId ?? this.mediaId,
        mediaTitle: mediaTitle ?? this.mediaTitle,
        position: position ?? this.position,
        isPlaying: isPlaying ?? this.isPlaying,
        duration: duration ?? this.duration,
        sourceMemberId: sourceMemberId ?? this.sourceMemberId,
      );
}

/// A "watch together" session.
///
/// All members play the same media; the host's transport position is shared so
/// guests stay in sync. Chat messages are broadcast to every member.
class WatchParty {
  final String id;
  final String name;
  final String hostId;
  final List<PartyMember> members;
  final List<PartyMessage> messages;
  final PartyPlaybackState? playback;
  final List<EmojiReaction> reactions;
  final Map<String, VoiceChatState> voiceStates;
  final Map<String, AvatarConfig> avatars;
  final List<PartyPoll> polls;
  final List<PartyQuiz> quizzes;
  final List<SharedNote> notes;
  final PartySettings settings;
  final Map<String, bool> pendingVotes;

  const WatchParty({
    required this.id,
    required this.name,
    required this.hostId,
    this.members = const [],
    this.messages = const [],
    this.playback,
    this.reactions = const [],
    this.voiceStates = const {},
    this.avatars = const {},
    this.polls = const [],
    this.quizzes = const [],
    this.notes = const [],
    this.settings = const PartySettings(),
    this.pendingVotes = const {},
  });

  WatchParty copyWith({
    String? name,
    List<PartyMember>? members,
    List<PartyMessage>? messages,
    PartyPlaybackState? playback,
    List<EmojiReaction>? reactions,
    Map<String, VoiceChatState>? voiceStates,
    Map<String, AvatarConfig>? avatars,
    List<PartyPoll>? polls,
    List<PartyQuiz>? quizzes,
    List<SharedNote>? notes,
    PartySettings? settings,
    Map<String, bool>? pendingVotes,
  }) =>
      WatchParty(
        id: id,
        name: name ?? this.name,
        hostId: hostId,
        members: members ?? this.members,
        messages: messages ?? this.messages,
        playback: playback ?? this.playback,
        reactions: reactions ?? this.reactions,
        voiceStates: voiceStates ?? this.voiceStates,
        avatars: avatars ?? this.avatars,
        polls: polls ?? this.polls,
        quizzes: quizzes ?? this.quizzes,
        notes: notes ?? this.notes,
        settings: settings ?? this.settings,
        pendingVotes: pendingVotes ?? this.pendingVotes,
      );
}

/// A transport-level event that is sent to (or received from) the network.
sealed class PartyEvent {
  const PartyEvent();
  Map<String, dynamic> toJson();

  static PartyEvent fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'member_joined':
        return PartyMemberJoinedEvent(
          member: PartyMember.fromJson((json['member'] as Map).cast<String, dynamic>()),
        );
      case 'member_left':
        return PartyMemberLeftEvent(memberId: json['memberId'] as String);
      case 'message':
        return PartyMessageEvent(
          message: PartyMessage.fromJson((json['message'] as Map).cast<String, dynamic>()),
        );
      case 'playback':
        return PartyPlaybackEvent(
          state: PartyPlaybackState(
            mediaId: json['mediaId'] as String?,
            mediaTitle: json['mediaTitle'] as String?,
            position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
            isPlaying: json['isPlaying'] as bool? ?? false,
            duration: json['durationMs'] == null
                ? null
                : Duration(milliseconds: json['durationMs'] as int),
            sourceMemberId: json['sourceMemberId'] as String?,
          ),
        );
      case 'reaction':
        return PartyReactionEvent(
          reaction: EmojiReaction.fromJson((json['reaction'] as Map).cast<String, dynamic>()),
        );
      case 'voice':
        return PartyVoiceEvent(
          state: VoiceChatState.fromJson((json['state'] as Map).cast<String, dynamic>()),
        );
      case 'poll':
        return PartyPollEvent(
          poll: PartyPoll.fromJson((json['poll'] as Map).cast<String, dynamic>()),
        );
      case 'quiz':
        return PartyQuizEvent(
          quiz: PartyQuiz.fromJson((json['quiz'] as Map).cast<String, dynamic>()),
        );
      case 'note':
        return PartyNoteEvent(
          note: SharedNote.fromJson((json['note'] as Map).cast<String, dynamic>()),
        );
      case 'settings':
        return PartySettingsEvent(
          settings: PartySettings.fromJson((json['settings'] as Map).cast<String, dynamic>()),
        );
      case 'vote':
        return PartyVoteEvent(
          memberId: json['memberId'] as String,
          approved: json['approved'] as bool,
        );
      default:
        throw ArgumentError('Unknown party event: ${json['type']}');
    }
  }
}

class PartyMemberJoinedEvent extends PartyEvent {
  final PartyMember member;
  const PartyMemberJoinedEvent({required this.member});
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'member_joined', 'member': member.toJson()};
}

class PartyMemberLeftEvent extends PartyEvent {
  final String memberId;
  const PartyMemberLeftEvent({required this.memberId});
  @override
  Map<String, dynamic> toJson() => {'type': 'member_left', 'memberId': memberId};
}

class PartyMessageEvent extends PartyEvent {
  final PartyMessage message;
  const PartyMessageEvent({required this.message});
  @override
  Map<String, dynamic> toJson() => {'type': 'message', 'message': message.toJson()};
}

class PartyPlaybackEvent extends PartyEvent {
  final PartyPlaybackState state;
  const PartyPlaybackEvent({required this.state});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'playback',
        'mediaId': state.mediaId,
        'mediaTitle': state.mediaTitle,
        'positionMs': state.position.inMilliseconds,
        'isPlaying': state.isPlaying,
        'durationMs': state.duration?.inMilliseconds,
        'sourceMemberId': state.sourceMemberId,
      };
}

class PartyReactionEvent extends PartyEvent {
  final EmojiReaction reaction;
  const PartyReactionEvent({required this.reaction});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'reaction',
        'reaction': reaction.toJson(),
      };
}

class PartyVoiceEvent extends PartyEvent {
  final VoiceChatState state;
  const PartyVoiceEvent({required this.state});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'voice',
        'state': state.toJson(),
      };
}

class PartyPollEvent extends PartyEvent {
  final PartyPoll poll;
  const PartyPollEvent({required this.poll});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'poll',
        'poll': poll.toJson(),
      };
}

class PartyQuizEvent extends PartyEvent {
  final PartyQuiz quiz;
  const PartyQuizEvent({required this.quiz});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'quiz',
        'quiz': quiz.toJson(),
      };
}

class PartyNoteEvent extends PartyEvent {
  final SharedNote note;
  const PartyNoteEvent({required this.note});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'note',
        'note': note.toJson(),
      };
}

class PartySettingsEvent extends PartyEvent {
  final PartySettings settings;
  const PartySettingsEvent({required this.settings});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'settings',
        'settings': settings.toJson(),
      };
}

class PartyVoteEvent extends PartyEvent {
  final String memberId;
  final bool approved;
  const PartyVoteEvent({required this.memberId, required this.approved});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'vote',
        'memberId': memberId,
        'approved': approved,
      };
}

/// Message framing for the party socket: `{op, partyId, event}`.
class PartyEnvelope {
  final String op;
  final String? partyId;
  final PartyEvent event;

  const PartyEnvelope({
    required this.op,
    this.partyId,
    required this.event,
  });

  Map<String, dynamic> toJson() =>
      {'op': op, 'partyId': partyId, 'event': event.toJson()};
}

/// Watch-together sync engine.
///
/// Local-first: the service keeps authoritative party state in memory and
/// applies events regardless of the transport. With no server configured a
/// [LocalPartyTransport] simply echoes events back (single-device preview of
/// the experience). When a server URL is set, events are broadcast over a
/// WebSocket so multiple devices stay in sync.
class SyncService extends ChangeNotifier {
  SyncService({PartyTransport? transport})
      : _transport = transport ?? LocalPartyTransport() {
    _sub = _transport.events.listen(_onEvent);
  }

  PartyTransport _transport;
  StreamSubscription<PartyEvent>? _sub;

  WatchParty? _party;

  /// Whether a party is currently active.
  bool get inParty => _party != null;

  /// The active party, or `null`.
  WatchParty? get party => _party;

  /// This device's member id inside the party.
  String? get selfId => _self?.id;

  PartyMember? _self;

  /// The current member (this device), or `null` when not in a party.
  PartyMember? get self => _self;

  /// Switches to a WebSocket transport pointed at [serverUrl].
  Future<void> configureServer(String serverUrl) async {
    final next = WebSocketPartyTransport(serverUrl);
    await next.connect();
    final old = _transport;
    _sub?.cancel();
    _transport = next;
    _sub = next.events.listen(_onEvent);
    await old.close();
    notifyListeners();
  }

  /// Creates a party as host with this device as [selfName].
  Future<WatchParty> createParty({
    required String selfId,
    required String selfName,
    required String name,
  }) async {
    _self = PartyMember.host(selfId, selfName);
    _party = WatchParty(
      id: 'party-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      hostId: selfId,
      members: [_self!],
    );
    notifyListeners();
    return _party!;
  }

  /// Joins an existing party (code lookup is transport-dependent; the local
  /// transport re-uses [joinCode] as the party id).
  Future<WatchParty> joinParty({
    required String joinCode,
    required String selfId,
    required String selfName,
  }) async {
    final existing = _party;
    if (existing == null) {
      _party = WatchParty(
        id: joinCode,
        name: 'Party $joinCode',
        hostId: joinCode,
      );
    }
    _self = PartyMember(id: selfId, name: selfName, role: PartyRole.guest, joinedAt: DateTime.now());
    _party = _party!.copyWith(
      members: [..._party!.members.where((m) => m.id != selfId), _self!],
    );
    _send(PartyMemberJoinedEvent(member: _self!));
    notifyListeners();
    return _party!;
  }

  /// Leaves the active party.
  Future<void> leaveParty() async {
    if (_party != null && _self != null) {
      _send(PartyMemberLeftEvent(memberId: _self!.id));
    }
    _party = null;
    _self = null;
    notifyListeners();
  }

  /// Sends a chat [text] from [senderName].
  void sendMessage(String text, {required String senderName}) {
    if (_party == null || _self == null) return;
    final message = PartyMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      senderId: _self!.id,
      senderName: senderName,
      text: text,
      sentAt: DateTime.now(),
    );
    _send(PartyMessageEvent(message: message));
  }

  /// Broadcasts the current playback state so members can sync.
  void sharePlayback(PartyPlaybackState state) {
    if (_party == null) return;
    _send(PartyPlaybackEvent(state: state.copyWith(sourceMemberId: _self?.id)));
  }

  /// Sends an emoji reaction at the current playback position.
  void sendReaction(String emoji, {required Duration position, required String senderName}) {
    if (_party == null || _self == null) return;
    final reaction = EmojiReaction(
      id: 'rxn-${DateTime.now().microsecondsSinceEpoch}',
      memberId: _self!.id,
      memberName: senderName,
      emoji: emoji,
      position: position,
      sentAt: DateTime.now(),
    );
    _send(PartyReactionEvent(reaction: reaction));
  }

  /// Updates voice chat state for this member.
  void updateVoiceState(VoiceState state) {
    if (_party == null || _self == null) return;
    final voiceState = VoiceChatState(
      memberId: _self!.id,
      memberName: _self!.name,
      state: state,
    );
    _send(PartyVoiceEvent(state: voiceState));
  }

  /// Creates a poll in the party.
  void createPoll({required String question, required List<PartyPollOption> options}) {
    if (_party == null || _self == null) return;
    final poll = PartyPoll(
      id: 'poll-${DateTime.now().microsecondsSinceEpoch}',
      creatorId: _self!.id,
      question: question,
      options: options,
      createdAt: DateTime.now(),
    );
    _send(PartyPollEvent(poll: poll));
  }

  /// Votes on a poll.
  void votePoll(String pollId, int optionIndex) {
    if (_party == null || _self == null) return;
    final party = _party!;
    final idx = party.polls.indexWhere((p) => p.id == pollId);
    if (idx < 0) return;
    final old = party.polls[idx];
    final updated = old.copyWith(votes: {...old.votes, _self!.id: optionIndex});
    final polls = [...party.polls];
    polls[idx] = updated;
    _party = party.copyWith(polls: polls);
    _send(PartyPollEvent(poll: updated));
  }

  /// Creates a quiz in the party.
  void createQuiz({required String title, required List<PartyQuizQuestion> questions}) {
    if (_party == null || _self == null) return;
    final quiz = PartyQuiz(
      id: 'quiz-${DateTime.now().microsecondsSinceEpoch}',
      creatorId: _self!.id,
      title: title,
      questions: questions,
      createdAt: DateTime.now(),
    );
    _send(PartyQuizEvent(quiz: quiz));
  }

  /// Answers the current quiz question.
  void answerQuiz(String quizId, int questionIndex, int answerIndex) {
    if (_party == null || _self == null) return;
    final party = _party!;
    final idx = party.quizzes.indexWhere((q) => q.id == quizId);
    if (idx < 0) return;
    final old = party.quizzes[idx];
    final memberAnswers = old.answers[_self!.id] ?? {};
    final updated = old.copyWith(
      answers: {...old.answers, _self!.id: {...memberAnswers, questionIndex: answerIndex}},
    );
    final quizzes = [...party.quizzes];
    quizzes[idx] = updated;
    _party = party.copyWith(quizzes: quizzes);
    _send(PartyQuizEvent(quiz: updated));
  }

  /// Posts a shared note.
  void postNote(String content, {Duration? position}) {
    if (_party == null || _self == null) return;
    final now = DateTime.now();
    final note = SharedNote(
      id: 'note-${now.microsecondsSinceEpoch}',
      authorId: _self!.id,
      authorName: _self!.name,
      content: content,
      position: position,
      createdAt: now,
      updatedAt: now,
    );
    _send(PartyNoteEvent(note: note));
  }

  /// Updates party settings (host only).
  void updateSettings(PartySettings settings) {
    if (_party == null) return;
    _send(PartySettingsEvent(settings: settings));
  }

  /// Casts a vote in democratic mode.
  void castVote(bool approved) {
    if (_party == null || _self == null) return;
    _send(PartyVoteEvent(memberId: _self!.id, approved: approved));
  }

  /// Sets avatar for this member.
  void setAvatar(AvatarConfig avatar) {
    if (_party == null || _self == null) return;
    _party = _party!.copyWith(
      avatars: {..._party!.avatars, _self!.id: avatar},
    );
    notifyListeners();
  }

  void _send(PartyEvent event) {
    final partyId = _party?.id;
    _transport.send(PartyEnvelope(op: 'event', partyId: partyId, event: event));
    // Local transport echoes; a real transport returns from the network.
    if (_transport is LocalPartyTransport) {
      _onEvent(event);
    }
  }

  void _onEvent(PartyEvent event) {
    final party = _party;
    if (party == null) return;
    switch (event) {
      case PartyMemberJoinedEvent(:final member):
        if (party.members.any((m) => m.id == member.id)) return;
        _party = party.copyWith(members: [...party.members, member]);
      case PartyMemberLeftEvent(:final memberId):
        _party = party.copyWith(
          members: party.members.where((m) => m.id != memberId).toList(),
        );
      case PartyMessageEvent(:final message):
        _party = party.copyWith(messages: [...party.messages, message]);
      case PartyPlaybackEvent(:final state):
        _party = party.copyWith(playback: state);
      case PartyReactionEvent(:final reaction):
        _party = party.copyWith(reactions: [...party.reactions, reaction]);
      case PartyVoiceEvent(:final state):
        _party = party.copyWith(
          voiceStates: {...party.voiceStates, state.memberId: state},
        );
      case PartyPollEvent(:final poll):
        final polls = [...party.polls];
        final idx = polls.indexWhere((p) => p.id == poll.id);
        if (idx >= 0) {
          polls[idx] = poll;
        } else {
          polls.add(poll);
        }
        _party = party.copyWith(polls: polls);
      case PartyQuizEvent(:final quiz):
        final quizzes = [...party.quizzes];
        final idx = quizzes.indexWhere((q) => q.id == quiz.id);
        if (idx >= 0) {
          quizzes[idx] = quiz;
        } else {
          quizzes.add(quiz);
        }
        _party = party.copyWith(quizzes: quizzes);
      case PartyNoteEvent(:final note):
        final notes = [...party.notes];
        final idx = notes.indexWhere((n) => n.id == note.id);
        if (idx >= 0) {
          notes[idx] = note;
        } else {
          notes.add(note);
        }
        _party = party.copyWith(notes: notes);
      case PartySettingsEvent(:final settings):
        _party = party.copyWith(settings: settings);
      case PartyVoteEvent(:final memberId, :final approved):
        _party = party.copyWith(
          pendingVotes: {...party.pendingVotes, memberId: approved},
        );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _transport.close();
    super.dispose();
  }
}

/// Abstraction over the party network. Local echoes events back; the WebSocket
/// implementation broadcasts to other devices.
abstract class PartyTransport {
  Stream<PartyEvent> get events;

  Future<void> send(PartyEnvelope envelope);

  Future<void> close();
}

/// Single-device transport: every sent event is immediately replayed locally.
class LocalPartyTransport implements PartyTransport {
  final _controller = StreamController<PartyEvent>.broadcast();

  @override
  Stream<PartyEvent> get events => _controller.stream;

  @override
  Future<void> send(PartyEnvelope envelope) async {
    _controller.add(envelope.event);
  }

  @override
  Future<void> close() => _controller.close();
}

/// WebSocket transport. The server is expected to relay `{op:event}` envelopes
/// tagged with `partyId` to all members of that party.
class WebSocketPartyTransport implements PartyTransport {
  WebSocketPartyTransport(this.serverUrl);

  final String serverUrl;
  final _controller = StreamController<PartyEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  bool _closed = false;

  Future<void> connect() async {
    final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _channel = channel;
    _sub = channel.stream.listen(
      (data) {
        try {
          final envelope = (jsonDecode(data as String) as Map).cast<String, dynamic>();
          final event = PartyEvent.fromJson((envelope['event'] as Map).cast<String, dynamic>());
          _controller.add(event);
        } catch (_) {
          // Ignore malformed frames.
        }
      },
      onError: (e) => _controller.addError(e),
      onDone: _controller.close,
    );
    await _channel!.ready;
  }

  @override
  Stream<PartyEvent> get events => _controller.stream;

  @override
  Future<void> send(PartyEnvelope envelope) async {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(envelope.toJson()));
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _sub?.cancel();
    await _channel?.sink.close();
    await _controller.close();
  }
}
