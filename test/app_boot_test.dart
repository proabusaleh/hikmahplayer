import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/app.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/router/app_router.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/presentation/providers/services_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app widget tree (HikmahApp + GoRouter + splash) in a test
/// environment. This exercises the exact startup path shown to users instead
/// of a silent blank screen: theme building, the shared AppScope, the router
/// redirect and the splash -> onboarding navigation.
///
/// MediaKit native libs are not loaded here (PlaybackService is lazy), so a
/// failure in this tree is a pure Dart/widget-layer startup bug.
void main() {
  testWidgets('app boots and navigates splash -> onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final services = await AppServices.create(database: db);
    final router = createAppRouter(prefs: services.prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appServicesProvider.overrideWithValue(services)],
        child: HikmahApp(services: services, routerConfig: router),
      ),
    );

    // First frame: splash must render its branding, not a blank screen.
    await tester.pump();
    expect(find.text('Hikmah'), findsWidgets, reason: 'splash did not render');
    expect(tester.takeException(), isNull, reason: 'first frame threw');

    // Wait past the 2.2s splash timer; first launch must land on onboarding.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: 'navigation threw');
    expect(find.text('Welcome · 1/4'), findsOneWidget,
        reason: 'did not reach onboarding');

    // Tapping through the pages must not throw either.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}