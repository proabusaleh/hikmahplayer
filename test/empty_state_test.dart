import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('EmptyState displays title and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.movie,
            title: 'No Videos',
            message: 'Scan your device',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.movie), findsOneWidget);
    expect(find.text('No Videos'), findsOneWidget);
    expect(find.text('Scan your device'), findsOneWidget);
  });

  testWidgets('EmptyState shows action button when provided', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.music_note,
            title: 'No Music',
            actionLabel: 'Scan',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Scan'), findsOneWidget);
    await tester.tap(find.text('Scan'));
    expect(tapped, true);
  });

  testWidgets('EmptyState without message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.folder,
            title: 'Empty Folder',
          ),
        ),
      ),
    );

    expect(find.text('Empty Folder'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
