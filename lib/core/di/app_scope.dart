import 'package:flutter/widgets.dart';

import 'app_services.dart';

/// Provides the application's shared [AppServices] instance to the widget
/// tree. Every screen reads services through [AppScope.of].
///
/// ```dart
/// final services = AppScope.of(context);
/// services.playback.openItem(item);
/// ```
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.services,
    required super.child,
  });

  /// The shared service container.
  final AppServices services;

  /// Returns the nearest [AppScope]'s [AppServices].
  ///
  /// Fails (in debug builds) when called outside an [AppScope].
  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this context.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.services != services;
}
