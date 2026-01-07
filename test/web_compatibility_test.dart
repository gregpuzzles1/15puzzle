import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_15/main.dart';

void main() {
  group('Web Compatibility Tests', () {
    testWidgets('Game UI renders without errors on web', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify that the app builds without errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(PuzzleGame), findsOneWidget);
    });

    testWidgets('All 15 tiles are present in initial state', (WidgetTester tester) async {
      // Build the game
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find all tiles (numbered 1-15, empty space doesn't have text)
      for (int i = 1; i <= 15; i++) {
        expect(find.text('$i'), findsOneWidget, reason: 'Tile $i should be present');
      }

      // Verify move counter exists
      expect(find.textContaining('Moves:'), findsOneWidget);
    });

    testWidgets('Basic game load test', (WidgetTester tester) async {
      // Build the game
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify the game title
      expect(find.text('15 Puzzle'), findsOneWidget);

      // Verify the New Game button exists
      expect(find.text('New Game'), findsOneWidget);

      // Verify the board exists (Container or grid structure)
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
