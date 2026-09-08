import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_scope.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/services/media_scan_service.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/utils/media_scanner.dart';
import 'package:hikmahplayer/features/videos/presentation/screens/videos_screen.dart';
import 'package:hikmahplayer/presentation/providers/services_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppServices> servicesWith(ScannedMedia scanned) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final services = await AppServices.create(database: db);
    await services.media.upsert(
      MediaScanService.companionFromScanned(
        scanned,
        type: HikmahMediaType.video,
      ),
    );
    return services;
  }

  Widget wrap(AppServices services) {
    return ProviderScope(
      overrides: [appServicesProvider.overrideWithValue(services)],
      child: AppScope(
        services: services,
        child: const MaterialApp(home: VideosScreen()),
      ),
    );
  }

  testWidgets('renders scanned videos from the library', (tester) async {
    final services = await servicesWith(
      const ScannedMedia(
        id: '1',
        uri: 'content://media/external/video/media/10',
        fileName: 'khutbah.mp4',
        title: 'Friday Khutbah',
        mimeType: 'video/mp4',
        size: 2048,
        durationMs: 120000,
        folderPath: 'Movies',
        folderName: 'Movies',
      ),
    );
    addTearDown(() => services.database.close());

    await tester.pumpWidget(wrap(services));
    // The drift watch() stream produces on real-async; let it emit before we
    // settle the widget tree.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Friday Khutbah'), findsOneWidget);
    expect(find.textContaining('2:00'), findsOneWidget);

    // Drift schedules a zero-duration timer when a watched query stream is
    // cancelled during widget disposal. Tear the screen down inside the test
    // body (and flush the timer) before the DB is closed so no timers are
    // pending when the test framework checks invariants.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('shows the empty state when nothing is indexed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final services = await AppServices.create(database: db);
    addTearDown(() => db.close());

    await tester.pumpWidget(wrap(services));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    // Guard: if nothing was indexed the empty state (not a spinner) shows.
    await tester.pump();

    expect(find.text('No videos yet'), findsOneWidget);
    expect(find.text('Rescan storage'), findsOneWidget);

    // See note in the previous test: settle the watched stream before the
    // test ends so no drift timers remain pending.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}