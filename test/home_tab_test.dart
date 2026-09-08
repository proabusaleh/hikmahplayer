import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/presentation/screens/home/home_tab.dart';
import 'package:hikmahplayer/presentation/providers/media_provider.dart';
import 'package:hikmahplayer/presentation/providers/services_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _buildContainer() async {
  SharedPreferences.setMockInitialValues({});
  final sharedPrefs = await SharedPreferences.getInstance();
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final services =
      AppServices(prefs: PrefsService(sharedPrefs), database: database);
  return ProviderContainer(
    overrides: [appServicesProvider.overrideWithValue(services)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> pumpHome(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeTab()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders header, quick actions and empty state', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);
    await pumpHome(tester, container);

    expect(find.text('بارك الله فيك'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('No media found yet'), findsOneWidget);
  });

  testWidgets('shows continue watching once media exists', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);
    final services = container.read(appServicesProvider);
    await services.media.upsert(
      MediaItemsCompanion.insert(
        id: 'resume',
        filePath: '/library/resume.mp4',
        fileName: 'resume.mp4',
        title: const Value('Half watched'),
        mediaType: HikmahMediaType.video.value,
        folderPath: '/library',
        durationMs: const Value(120000),
        lastPosition: const Value(60000),
        lastPlayed: Value(DateTime.now().millisecondsSinceEpoch),
        dateAdded: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      ),
    );

    await container.read(mediaItemsStreamProvider.future);

    await pumpHome(tester, container);

    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('Half watched'), findsWidgets);
  });
}