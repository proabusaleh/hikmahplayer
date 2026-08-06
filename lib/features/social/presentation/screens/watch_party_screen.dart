import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/models/avatar_config.dart';
import '../../domain/models/party_poll.dart';
import '../../domain/models/party_quiz.dart';
import '../../domain/models/party_settings.dart';
import '../../domain/models/voice_chat.dart';
import 'chat_overlay.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  SyncService? _sync;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showChat = false;
  bool _showMembers = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sync == null) {
      _sync = AppScope.of(context).sync;
      _sync!.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _sync?.removeListener(_onChanged);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  SyncService get _svc => _sync!;
  WatchParty? get _party => _svc.party;

  @override
  Widget build(BuildContext context) {
    if (_party == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Watch Party')),
        body: _buildNoParty(),
      );
    }
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              if (_party!.playback != null) _buildPlaybackBanner(),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_showChat)
            Positioned(
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ChatOverlay(
                messages: _party!.messages,
                onSend: (text) {
                  _svc.sendMessage(text, senderName: _svc.self?.name ?? 'You');
                },
                onClose: () => setState(() => _showChat = false),
              ),
            ),
          if (_showMembers) _buildMembersDrawer(),
        ],
      ),
      floatingActionButton: _party != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'members',
                  onPressed: () => setState(() => _showMembers = !_showMembers),
                  child: Badge(
                    label: Text('${_party!.members.length}'),
                    child: const Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'chat',
                  onPressed: () => setState(() => _showChat = !_showChat),
                  child: Badge(
                    label: Text('${_party!.messages.length}'),
                    child: const Icon(Icons.chat),
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'reactions',
                  onPressed: _showReactionPicker,
                  child: const Icon(Icons.emoji_emotions),
                ),
              ],
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isHost = _party!.hostId == _svc.selfId;
    return AppBar(
      title: Text(_party!.name),
      actions: [
        if (isHost)
          PopupMenuButton<String>(
            onSelected: _onMenuAction,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'poll', child: Text('Create Poll')),
              const PopupMenuItem(value: 'quiz', child: Text('Create Quiz')),
              const PopupMenuItem(value: 'note', child: Text('Shared Note')),
              const PopupMenuItem(value: 'settings', child: Text('Party Settings')),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Leave party',
          onPressed: () async {
            await _svc.leaveParty();
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildNoParty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_add, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No active party', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Create or join a watch party to get started.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _createParty,
            icon: const Icon(Icons.add),
            label: const Text('Create Party'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _joinParty,
            icon: const Icon(Icons.login),
            label: const Text('Join Party'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackBanner() {
    final p = _party!.playback!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            p.isPlaying ? Icons.play_arrow : Icons.pause,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.mediaTitle ?? 'Playing',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_fmtDuration(p.position)} / ${_fmtDuration(p.duration ?? Duration.zero)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Members (${_party!.members.length})'),
        _buildMemberList(),
        if (_party!.polls.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Active Polls'),
          for (final poll in _party!.polls.reversed.take(3))
            _PollCard(poll: poll, selfId: _svc.selfId, onVote: (idx) {
              _svc.votePoll(poll.id, idx);
            }),
        ],
        if (_party!.quizzes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Quizzes'),
          for (final quiz in _party!.quizzes.reversed.take(3))
            _QuizCard(quiz: quiz),
        ],
        if (_party!.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Shared Notes'),
          for (final note in _party!.notes.reversed.take(10))
            Card(
              child: ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(note.content),
                subtitle: Text(
                  '${note.authorName} · ${_fmtDuration(note.position ?? Duration.zero)}',
                ),
              ),
            ),
        ],
        if (_party!.reactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: 'Recent Reactions'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _party!.reactions.reversed.take(20).map((r) {
              return Chip(
                avatar: Text(r.emoji),
                label: Text('${r.memberName} at ${_fmtDuration(r.position)}'),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberList() {
    return Card(
      child: Column(
        children: [
          for (final member in _party!.members)
            ListTile(
              leading: _buildAvatar(member.id),
              title: Text(member.name),
              subtitle: Text(
                member.role == PartyRole.host ? 'Host' : 'Guest',
                style: TextStyle(
                  color: member.role == PartyRole.host
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              trailing: _buildVoiceIndicator(member.id),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String memberId) {
    final avatar = _party!.avatars[memberId] ?? const AvatarConfig();
    return CircleAvatar(
      backgroundColor: Color(avatar.color),
      child: Text(avatar.emoji, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget? _buildVoiceIndicator(String memberId) {
    final voice = _party!.voiceStates[memberId];
    if (voice == null) return null;
    switch (voice.state) {
      case VoiceState.active:
        return const Icon(Icons.mic, color: Colors.green, size: 20);
      case VoiceState.muted:
        return const Icon(Icons.mic_off, color: Colors.orange, size: 20);
      case VoiceState.connecting:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case VoiceState.idle:
        return null;
    }
  }

  Widget _buildMembersDrawer() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 260,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Members', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _showMembers = false),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildMemberList()),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionPicker() {
    final emojis = ['😂', '❤️', '🔥', '👏', '😮', '😢', '👍', '🎉'];
    final playback = _party!.playback;
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('React', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...emojis.map((e) => InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _svc.sendReaction(
                    e,
                    position: playback?.position ?? Duration.zero,
                    senderName: _svc.self?.name ?? 'You',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'poll':
        _showCreatePollDialog();
        break;
      case 'quiz':
        _showCreateQuizDialog();
        break;
      case 'note':
        _showCreateNoteDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  void _showCreatePollDialog() {
    final questionCtrl = TextEditingController();
    final optionsCtrl = [TextEditingController(), TextEditingController()];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Poll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Question')),
            const SizedBox(height: 8),
            for (final ctrl in optionsCtrl)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Option')),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final options = optionsCtrl
                  .map((c) => c.text.trim())
                  .where((t) => t.isNotEmpty)
                  .map((t) => PartyPollOption(label: t))
                  .toList();
              if (questionCtrl.text.isNotEmpty && options.length >= 2) {
                _svc.createPoll(question: questionCtrl.text, options: options);
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateQuizDialog() {
    final titleCtrl = TextEditingController();
    final qCtrl = TextEditingController();
    final optsCtrl = [TextEditingController(), TextEditingController()];
    final correctIdx = ValueNotifier<int>(0);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Quiz Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Quiz title')),
            const SizedBox(height: 8),
            TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Question')),
            const SizedBox(height: 8),
            for (var i = 0; i < optsCtrl.length; i++)
              ValueListenableBuilder<int>(
                valueListenable: correctIdx,
                builder: (_, correct, _) => ListTile(
                  dense: true,
                  leading: Radio<int>(
                    value: i,
                    groupValue: correct,
                    onChanged: (v) => correctIdx.value = v ?? 0,
                  ),
                  title: TextField(controller: optsCtrl[i], decoration: InputDecoration(labelText: 'Option ${i + 1}')),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final options = optsCtrl.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
              if (qCtrl.text.isNotEmpty && options.length >= 2) {
                _svc.createQuiz(
                  title: titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Quiz',
                  questions: [
                    PartyQuizQuestion(
                      question: qCtrl.text,
                      options: options,
                      correctIndex: correctIdx.value,
                    ),
                  ],
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateNoteDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Shared Note'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write a note for the group…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                _svc.postNote(ctrl.text, position: _party!.playback?.position);
              }
              Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    var settings = _party!.settings;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Party Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Democratic control'),
                subtitle: const Text('Guests can vote on playback actions'),
                value: settings.controlMode == PartyControlMode.democratic,
                onChanged: (v) {
                  setDialogState(() {
                    settings = settings.copyWith(
                      controlMode: v ? PartyControlMode.democratic : PartyControlMode.host,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Allow guest seek'),
                value: settings.allowGuestSeek,
                onChanged: (v) => setDialogState(() => settings = settings.copyWith(allowGuestSeek: v)),
              ),
              SwitchListTile(
                title: const Text('Allow guest pause'),
                value: settings.allowGuestPause,
                onChanged: (v) => setDialogState(() => settings = settings.copyWith(allowGuestPause: v)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                _svc.updateSettings(settings);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _createParty() {
    final nameCtrl = TextEditingController();
    final selfCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Watch Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Party name')),
            const SizedBox(height: 8),
            TextField(controller: selfCtrl, decoration: const InputDecoration(labelText: 'Your name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && selfCtrl.text.isNotEmpty) {
                final id = 'user-${DateTime.now().microsecondsSinceEpoch}';
                _svc.createParty(selfId: id, selfName: selfCtrl.text, name: nameCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinParty() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join Watch Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Party code')),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (codeCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                final id = 'user-${DateTime.now().microsecondsSinceEpoch}';
                _svc.joinParty(joinCode: codeCtrl.text, selfId: id, selfName: nameCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll, required this.selfId, required this.onVote});
  final PartyPoll poll;
  final String? selfId;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final myVote = selfId != null ? poll.votes[selfId] : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll.question, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (var i = 0; i < poll.options.length; i++)
              ListTile(
                dense: true,
                leading: Radio<int>(
                  value: i,
                  groupValue: myVote,
                  onChanged: poll.closed ? null : (_) => onVote(i),
                ),
                title: Text(poll.options[i].label),
                trailing: Text('${poll.votesFor(i)}'),
              ),
            if (poll.closed)
              Text('Poll closed · ${poll.totalVotes} votes',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});
  final PartyQuiz quiz;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.quiz),
        title: Text(quiz.title),
        subtitle: Text(
          quiz.isFinished
              ? 'Finished · ${quiz.questions.length} questions'
              : 'Question ${quiz.currentIndex + 1}/${quiz.questions.length}',
        ),
      ),
    );
  }
}
