import 'package:flutter/foundation.dart';

import '../../features/hikmah/domain/models/comprehension_check.dart';
import '../../features/hikmah/domain/models/hikmah_mode.dart';
import '../../features/hikmah/domain/models/learning_goal.dart';
import '../../features/hikmah/domain/models/session_journal.dart';

/// Orchestrates Hikmah (mindful consumption) mode: reflection pauses,
/// comprehension checks, teach-back, session journaling, focus scoring,
/// streak tracking, and learning goals.
class HikmahModeService extends ChangeNotifier {
  HikmahModeService();

  HikmahConfig config = const HikmahConfig();
  final List<HikmahSession> _sessions = [];
  final List<LearningGoal> _goals = [];
  final List<SessionJournalEntry> _journalEntries = [];
  final List<ComprehensionCheck> _checks = [];
  final List<ReflectionPrompt> _reflections = [];
  final List<TeachBackPrompt> _teachBacks = [];
  final List<Streak> _streaks = [];

  HikmahSession? _activeSession;
  DateTime? _lastReflectionAt;

  // ---------------------------------------------------------------------
  // Config
  // ---------------------------------------------------------------------

  void setConfig(HikmahConfig value) {
    config = value;
    notifyListeners();
  }

  void toggleEnabled() {
    config = config.copyWith(enabled: !config.enabled);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Active session
  // ---------------------------------------------------------------------

  HikmahSession? get activeSession => _activeSession;

  void startSession(String mediaId, {String? learningIntent}) {
    _activeSession = HikmahSession(
      id: 'hikmah-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      startedAt: DateTime.now(),
      learningIntent: learningIntent,
    );
    _lastReflectionAt = DateTime.now();
    notifyListeners();
  }

  void endSession() {
    if (_activeSession != null) {
      _sessions.add(_activeSession!);
      _maybeAutoSaveJournal(_activeSession!);
      _recordStreak('session');
    }
    _activeSession = null;
    _lastReflectionAt = null;
    notifyListeners();
  }

  void addActivity(HikmahActivityType type, {String? content, double? position}) {
    final session = _activeSession;
    if (session == null) return;
    final activity = HikmahActivity(
      type: type,
      timestamp: DateTime.now(),
      content: content,
      positionSeconds: position,
    );
    _activeSession = session.copyWith(
      activities: [...session.activities, activity],
    );
    if (type == HikmahActivityType.rewind || type == HikmahActivityType.pause) {
      _recordStreak(type.name);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Learning intent
  // ---------------------------------------------------------------------

  void setLearningIntent(String intent) {
    final session = _activeSession;
    if (session == null) return;
    _activeSession = session.copyWith(learningIntent: intent);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Reflection
  // ---------------------------------------------------------------------

  List<ReflectionPrompt> get reflections => List.unmodifiable(_reflections);

  bool shouldTriggerReflection() {
    if (!config.enabled || _activeSession == null) return false;
    if (_lastReflectionAt == null) return true;
    return DateTime.now().difference(_lastReflectionAt!).inMinutes >=
        config.reflectionIntervalMinutes;
  }

  ReflectionPrompt triggerReflection(String prompt, {double? position}) {
    final rp = ReflectionPrompt(
      id: 'refl-${DateTime.now().microsecondsSinceEpoch}',
      prompt: prompt,
      positionSeconds: position ?? 0,
      createdAt: DateTime.now(),
    );
    _reflections.add(rp);
    _lastReflectionAt = DateTime.now();
    addActivity(HikmahActivityType.reflection, content: prompt, position: position);
    notifyListeners();
    return rp;
  }

  void respondToReflection(String id, String response) {
    final idx = _reflections.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _reflections[idx] = _reflections[idx].respond(response);
    _recordStreak('reflection');
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Comprehension checks
  // ---------------------------------------------------------------------

  List<ComprehensionCheck> get checks => List.unmodifiable(_checks);

  bool shouldTriggerComprehensionCheck() {
    return config.enabled &&
        config.comprehensionChecksEnabled &&
        _activeSession != null;
  }

  ComprehensionCheck addCheck(ComprehensionCheck check) {
    _checks.add(check);
    addActivity(HikmahActivityType.comprehensionCheck,
        content: check.question, position: check.positionSeconds);
    notifyListeners();
    return check;
  }

  void answerCheck(String id, int selectedIndex) {
    final idx = _checks.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _checks[idx] = _checks[idx].answer(selectedIndex);
    _recordStreak('comprehension');
    notifyListeners();
  }

  double get comprehensionScore {
    if (_checks.isEmpty) return 0;
    final correct = _checks.where((c) => c.isCorrect == true).length;
    return correct / _checks.length;
  }

  // ---------------------------------------------------------------------
  // Teach-back
  // ---------------------------------------------------------------------

  List<TeachBackPrompt> get teachBacks => List.unmodifiable(_teachBacks);

  bool shouldTriggerTeachBack() {
    return config.enabled &&
        config.teachBackEnabled &&
        _activeSession != null;
  }

  TeachBackPrompt addTeachBack(TeachBackPrompt prompt) {
    _teachBacks.add(prompt);
    addActivity(HikmahActivityType.teachBack,
        content: prompt.prompt, position: prompt.positionSeconds);
    notifyListeners();
    return prompt;
  }

  void completeTeachBack(String id, String explanation) {
    final idx = _teachBacks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _teachBacks[idx] = _teachBacks[idx].complete(explanation);
    _recordStreak('teachBack');
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Session journal
  // ---------------------------------------------------------------------

  List<SessionJournalEntry> get journalEntries => List.unmodifiable(_journalEntries);

  SessionJournalEntry addJournalEntry({
    required String sessionId,
    required String mediaId,
    String? title,
    required String content,
    double? positionSeconds,
    bool autoSaved = false,
  }) {
    final entry = SessionJournalEntry(
      id: 'journal-${DateTime.now().microsecondsSinceEpoch}',
      sessionId: sessionId,
      mediaId: mediaId,
      title: title,
      content: content,
      positionSeconds: positionSeconds,
      createdAt: DateTime.now(),
      autoSaved: autoSaved,
    );
    _journalEntries.add(entry);
    notifyListeners();
    return entry;
  }

  void _maybeAutoSaveJournal(HikmahSession session) {
    if (!config.autoSaveJournals) return;
    if (session.activities.isEmpty) return;
    final summary = session.activities.map((a) => '${a.type.name}: ${a.content ?? "—"}').join('\n');
    addJournalEntry(
      sessionId: session.id,
      mediaId: session.mediaId,
      title: 'Session ${session.id}',
      content: 'Learning intent: ${session.learningIntent ?? "—"}\n\n$summary',
      autoSaved: true,
    );
  }

  // ---------------------------------------------------------------------
  // Focus score
  // ---------------------------------------------------------------------

  FocusScore computeFocusScore({
    int rewindCount = 0,
    int pauseCount = 0,
    required Duration totalDuration,
    required Duration activeDuration,
  }) {
    return FocusScore.compute(
      rewindCount: rewindCount,
      pauseCount: pauseCount,
      totalDuration: totalDuration,
      activeDuration: activeDuration,
    );
  }

  // ---------------------------------------------------------------------
  // Streaks
  // ---------------------------------------------------------------------

  List<Streak> get streaks => List.unmodifiable(_streaks);

  Streak streakFor(String type) {
    return _streaks.firstWhere(
      (s) => s.activityType == type,
      orElse: () => Streak(id: 'streak-$type', activityType: type),
    );
  }

  void _recordStreak(String type) {
    final idx = _streaks.indexWhere((s) => s.activityType == type);
    final current = idx >= 0 ? _streaks[idx] : streakFor(type);
    final updated = current.recordActivity();
    if (idx >= 0) {
      _streaks[idx] = updated;
    } else {
      _streaks.add(updated);
    }
  }

  // ---------------------------------------------------------------------
  // Learning goals
  // ---------------------------------------------------------------------

  List<LearningGoal> get goals => List.unmodifiable(_goals);

  LearningGoal addGoal({
    required String title,
    String? description,
    DateTime? targetDate,
    List<GoalMilestone> milestones = const [],
  }) {
    final goal = LearningGoal(
      id: 'goal-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      createdAt: DateTime.now(),
      targetDate: targetDate,
      milestones: milestones,
    );
    _goals.add(goal);
    notifyListeners();
    return goal;
  }

  void completeMilestone(String goalId, String milestoneId) {
    final gIdx = _goals.indexWhere((g) => g.id == goalId);
    if (gIdx == -1) return;
    final goal = _goals[gIdx];
    final mIdx = goal.milestones.indexWhere((m) => m.id == milestoneId);
    if (mIdx == -1) return;
    final updated = goal.milestones[mIdx].copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
    final newMilestones = [...goal.milestones];
    newMilestones[mIdx] = updated;
    _goals[gIdx] = goal.copyWith(milestones: newMilestones);
    _recordStreak('goal');
    notifyListeners();
  }

  void completeGoal(String goalId) {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    _goals[idx] = _goals[idx].copyWith(completed: true);
    _recordStreak('goal');
    notifyListeners();
  }

  void removeGoal(String goalId) {
    _goals.removeWhere((g) => g.id == goalId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------

  List<HikmahSession> get sessions => List.unmodifiable(_sessions);
}
