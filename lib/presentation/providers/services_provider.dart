import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_services.dart';

/// Bridge between the [AppScope]/[AppServices] container and Riverpod.
///
/// Overridden with the production instance in `main()`:
///
/// ```dart
/// ProviderScope(
///   overrides: [appServicesProvider.overrideWithValue(services)],
///   child: HikmahApp(...),
/// )
/// ```
///
/// Tests override it with an [AppServices] built around an in-memory
/// database. Reading the un-overridden provider is a programming error.
final appServicesProvider = Provider<AppServices>((ref) {
  throw UnimplementedError(
    'appServicesProvider must be overridden with the AppServices instance '
    '(see main.dart / ProviderScope.overrides)',
  );
});
