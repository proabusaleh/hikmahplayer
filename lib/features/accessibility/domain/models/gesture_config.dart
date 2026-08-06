/// Actions that can be bound to a gesture.
enum GestureAction {
  playPause('Play / pause'),
  seekForward('Seek forward'),
  seekBackward('Seek backward'),
  volumeUp('Volume up'),
  volumeDown('Volume down'),
  nextTrack('Next'),
  previousTrack('Previous'),
  toggleSubtitles('Toggle subtitles'),
  boostDialogue('Toggle dialogue boost'),
  toggleFocusMode('Toggle focus mode'),
  enterPictureInPicture('Picture in picture'),
  showMenu('Open menu'),
  none('None');

  const GestureAction(this.label);

  final String label;
}

/// Gesture shapes that can trigger an action.
enum GestureTrigger {
  singleTap('Single tap'),
  doubleTap('Double tap'),
  doubleTapHold('Double tap + hold'),
  longPress('Long press'),
  swipeUp('Swipe up'),
  swipeDown('Swipe down'),
  swipeLeft('Swipe left'),
  swipeRight('Swipe right'),
  twoFingerTap('Two-finger tap'),
  threeFingerTap('Three-finger tap');

  const GestureTrigger(this.label);

  final String label;
}

/// A single trigger→action binding.
class GestureBinding {
  final GestureTrigger trigger;
  final GestureAction action;
  final bool enabled;

  const GestureBinding({
    required this.trigger,
    required this.action,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'trigger': trigger.name,
        'action': action.name,
        'enabled': enabled,
      };

  factory GestureBinding.fromJson(Map<String, dynamic> json) {
    return GestureBinding(
      trigger: GestureTrigger.values.asNameMap()[json['trigger']] ??
          GestureTrigger.singleTap,
      action: GestureAction.values.asNameMap()[json['action']] ??
          GestureAction.none,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  String toString() => '${trigger.label} → ${action.label}';
}

/// Full customisable gesture configuration (motor accessibility).
class GestureConfig {
  /// Whether custom gestures are enabled at all.
  final bool customGesturesEnabled;

  /// Play haptic feedback on recognised gestures.
  final bool hapticFeedback;

  /// Movement (px) a touch must travel before it counts as a swipe.
  final double swipeDeadzonePx;

  /// Current bindings, one per [GestureTrigger].
  final List<GestureBinding> bindings;

  const GestureConfig({
    this.customGesturesEnabled = true,
    this.hapticFeedback = true,
    this.swipeDeadzonePx = 32,
    this.bindings = _defaultBindings,
  });

  static const List<GestureBinding> _defaultBindings = [
    GestureBinding(trigger: GestureTrigger.singleTap, action: GestureAction.playPause),
    GestureBinding(trigger: GestureTrigger.doubleTap, action: GestureAction.toggleSubtitles),
    GestureBinding(trigger: GestureTrigger.doubleTapHold, action: GestureAction.seekForward),
    GestureBinding(trigger: GestureTrigger.longPress, action: GestureAction.toggleFocusMode),
    GestureBinding(trigger: GestureTrigger.swipeUp, action: GestureAction.volumeUp),
    GestureBinding(trigger: GestureTrigger.swipeDown, action: GestureAction.volumeDown),
    GestureBinding(trigger: GestureTrigger.swipeLeft, action: GestureAction.seekBackward),
    GestureBinding(trigger: GestureTrigger.swipeRight, action: GestureAction.seekForward),
    GestureBinding(trigger: GestureTrigger.twoFingerTap, action: GestureAction.showMenu),
    GestureBinding(trigger: GestureTrigger.threeFingerTap, action: GestureAction.enterPictureInPicture),
  ];

  static const GestureConfig defaults = GestureConfig();

  /// The action bound to [trigger], honouring [customGesturesEnabled] and
  /// per-binding [GestureBinding.enabled].
  GestureAction actionFor(GestureTrigger trigger) {
    if (!customGesturesEnabled) return GestureAction.none;
    for (final b in bindings) {
      if (b.trigger == trigger) return b.enabled ? b.action : GestureAction.none;
    }
    return GestureAction.none;
  }

  /// A copy with [trigger] bound to [action].
  GestureConfig withBinding(GestureTrigger trigger, GestureAction action) {
    return GestureConfig(
      customGesturesEnabled: customGesturesEnabled,
      hapticFeedback: hapticFeedback,
      swipeDeadzonePx: swipeDeadzonePx,
      bindings: [
        for (final b in bindings)
          if (b.trigger == trigger)
            GestureBinding(trigger: trigger, action: action, enabled: b.enabled)
          else
            b,
      ],
    );
  }

  /// A copy with [trigger] toggled on/off.
  GestureConfig toggleBinding(GestureTrigger trigger) {
    return GestureConfig(
      customGesturesEnabled: customGesturesEnabled,
      hapticFeedback: hapticFeedback,
      swipeDeadzonePx: swipeDeadzonePx,
      bindings: [
        for (final b in bindings)
          if (b.trigger == trigger)
            GestureBinding(
                trigger: trigger, action: b.action, enabled: !b.enabled)
          else
            b,
      ],
    );
  }

  GestureConfig copyWith({
    bool? customGesturesEnabled,
    bool? hapticFeedback,
    double? swipeDeadzonePx,
    List<GestureBinding>? bindings,
  }) {
    return GestureConfig(
      customGesturesEnabled: customGesturesEnabled ?? this.customGesturesEnabled,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      swipeDeadzonePx: swipeDeadzonePx ?? this.swipeDeadzonePx,
      bindings: bindings ?? this.bindings,
    );
  }

  Map<String, dynamic> toJson() => {
        'customGesturesEnabled': customGesturesEnabled,
        'hapticFeedback': hapticFeedback,
        'swipeDeadzonePx': swipeDeadzonePx,
        'bindings': bindings.map((b) => b.toJson()).toList(),
      };

  factory GestureConfig.fromJson(Map<String, dynamic> json) {
    return GestureConfig(
      customGesturesEnabled: json['customGesturesEnabled'] as bool? ?? true,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      swipeDeadzonePx: (json['swipeDeadzonePx'] as num?)?.toDouble() ?? 32,
      bindings: (json['bindings'] as List<dynamic>? ?? const [])
          .map((b) => GestureBinding.fromJson((b as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
