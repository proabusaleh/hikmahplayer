import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/videos/presentation/screens/videos_screen.dart';

void main() {
  testWidgets('videos screen loads', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: VideosScreen()),
    );
    expect(find.byType(VideosScreen), findsOneWidget);
  });
}