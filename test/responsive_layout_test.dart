import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_15/main.dart';

void main() {
  group('Responsive Layout Tests', () {
    testWidgets('Layout adapts to iPhone SE viewport (375×667)', (WidgetTester tester) async {
      // Set viewport size to iPhone SE dimensions
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify game is rendered
      expect(find.byType(PuzzleGame), findsOneWidget);
      expect(find.text('15 Puzzle'), findsOneWidget);
    });

    testWidgets('Layout adapts to iPad viewport (768×1024)', (WidgetTester tester) async {
      // Set viewport size to iPad dimensions
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify game is rendered
      expect(find.byType(PuzzleGame), findsOneWidget);
      expect(find.text('15 Puzzle'), findsOneWidget);
    });

    testWidgets('Layout adapts to desktop viewport (1920×1080)', (WidgetTester tester) async {
      // Set viewport size to desktop dimensions
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify game is rendered
      expect(find.byType(PuzzleGame), findsOneWidget);
      expect(find.text('15 Puzzle'), findsOneWidget);
    });

    testWidgets('No overflow errors on all viewport sizes', (WidgetTester tester) async {
      final List<Size> viewportSizes = [
        const Size(375, 667),   // iPhone SE
        const Size(414, 896),   // iPhone Pro Max
        const Size(768, 1024),  // iPad
        const Size(1024, 768),  // iPad landscape
        const Size(1280, 720),  // Desktop small
        const Size(1920, 1080), // Desktop large
      ];

      for (final size in viewportSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'No overflow errors should occur at ${size.width}×${size.height}',
        );

        // Reset for next iteration
        await tester.pumpWidget(Container());
      }

      tester.view.reset();
    });

    testWidgets('Tile size ≥44×44px on mobile viewport', (WidgetTester tester) async {
      // Set viewport to mobile size (logical pixels, not physical)
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0; // Use 1.0 to avoid shrinking
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Find a tile widget and verify its size
      final tileFinder = find.text('1');
      expect(tileFinder, findsOneWidget);

      // Get the tile's render box
      final RenderBox tileBox = tester.renderObject(tileFinder).parent! as RenderBox;
      
      // Verify tile size is at least 44×44px (WCAG touch target minimum)
      expect(tileBox.size.width, greaterThanOrEqualTo(44.0),
          reason: 'Tile width should be at least 44px for touch targets');
      expect(tileBox.size.height, greaterThanOrEqualTo(44.0),
          reason: 'Tile height should be at least 44px for touch targets');
    });
  });
}
