import 'package:flutter/foundation.dart';

/// Tracks whether a library is in multi-select mode and which ids are
/// currently selected. Kept as plain [ChangeNotifier]s so both the videos and
/// music libraries can share one implementation (Riverpod wraps them via
/// `ChangeNotifierProvider`).
class LibrarySelectionController extends ChangeNotifier {
  bool _active = false;
  final Set<String> _selected = {};

  /// Whether multi-select mode is active.
  bool get isActive => _active;

  /// The currently selected ids (ordered, insertion order).
  List<String> get selected => List.unmodifiable(_selected);

  /// Number of selected ids.
  int get count => _selected.length;

  /// Whether [id] is currently selected.
  bool contains(String id) => _selected.contains(id);

  /// Enters multi-select mode, optionally selecting [seedId] immediately.
  void begin(String? seedId) {
    _active = true;
    if (seedId != null) _selected.add(seedId);
    notifyListeners();
  }

  /// Toggles [id]. When [begin] was never called this simply selects the
  /// single id (tap-to-play behaviour is preserved by callers).
  void toggle(String id) {
    if (!_active) {
      begin(id);
      return;
    }
    if (!_selected.remove(id)) _selected.add(id);
    if (_selected.isEmpty) _active = false;
    notifyListeners();
  }

  /// Selects only [id], keeping multi-select mode active.
  void selectOnly(String id) {
    _selected
      ..clear()
      ..add(id);
    if (!_active) _active = true;
    notifyListeners();
  }

  /// Selects all ids that are currently loaded.
  void selectAll(Iterable<String> ids) {
    _selected
      ..clear()
      ..addAll(ids);
    _active = _selected.isNotEmpty;
    notifyListeners();
  }

  /// Clears the selection and leaves multi-select mode.
  void clear() {
    if (!_active && _selected.isEmpty) return;
    _active = false;
    _selected.clear();
    notifyListeners();
  }

  /// Removes [id] from the selection (e.g. after the row is deleted).
  void removeId(String id) {
    if (!_selected.remove(id)) return;
    if (_selected.isEmpty) _active = false;
    notifyListeners();
  }
}