import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/theme/app_theme.dart';

void main() {
  group('Heading Bar Font Size Tests', () {
    test('theme defines larger expanded heading size and smaller shrunk size', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      for (final theme in [lightTheme, darkTheme]) {
        // Expanded heading size from headlineMedium
        final expandedFontSize = theme.textTheme.headlineMedium?.fontSize;
        // Shrunk heading size from titleLarge
        final shrunkFontSize = theme.textTheme.titleLarge?.fontSize;

        expect(expandedFontSize, equals(32.0));
        expect(shrunkFontSize, equals(24.0));
        expect(shrunkFontSize! < expandedFontSize!, isTrue);

        // Verify font family and weight
        expect(theme.textTheme.headlineMedium?.fontFamily, equals('GoogleSansFlexRounded'));
        expect(theme.textTheme.headlineMedium?.fontWeight, equals(FontWeight.bold));
        expect(theme.textTheme.titleLarge?.fontFamily, equals('GoogleSansFlexRounded'));
        expect(theme.textTheme.titleLarge?.fontWeight, equals(FontWeight.bold));

        // appBarTheme should not override titleTextStyle so M3 SliverAppBar.large
        // can dynamically shrink font size between expanded and collapsed states
        expect(theme.appBarTheme.titleTextStyle, isNull);
      }
    });

    testWidgets('SliverAppBar.large font size shrinks when the heading bar is shrunk', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SliverAppBar.large(
                  title: Text('Resources'),
                  pinned: true,
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 1200,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the expanded title widget (in the flexible space)
      final textElements = find.text('Resources').evaluate().toList();
      expect(textElements.length, equals(2));

      // In SliverAppBar.large:
      // Element 0: FlexibleSpace expanded title
      // Element 1: Collapsed AppBar title (wrapped in AnimatedOpacity)
      final expandedElement = textElements.firstWhere(
        (e) => e.findAncestorWidgetOfExactType<AnimatedOpacity>() == null,
      );
      final collapsedElement = textElements.firstWhere(
        (e) => e.findAncestorWidgetOfExactType<AnimatedOpacity>() != null,
      );

      // In expanded state, expanded title is visible with fontSize 32
      final expandedStyle = DefaultTextStyle.of(expandedElement).style;
      expect(expandedStyle.fontSize, equals(32.0));

      // Shrunk element has opacity 0 when expanded
      final opacityBefore = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byWidget(collapsedElement.widget),
          matching: find.byType(AnimatedOpacity),
        ).first,
      );
      expect(opacityBefore.opacity, equals(0.0));

      // Scroll down to collapse / shrink the heading bar
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // In shrunk state, collapsed title in pinned toolbar has faded in with shrunk fontSize 24
      final shrunkStyle = DefaultTextStyle.of(collapsedElement).style;
      expect(shrunkStyle.fontSize, equals(24.0));
      expect(shrunkStyle.fontSize! < expandedStyle.fontSize!, isTrue);

      final opacityAfter = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byWidget(collapsedElement.widget),
          matching: find.byType(AnimatedOpacity),
        ).first,
      );
      expect(opacityAfter.opacity, equals(1.0));
    });
  });
}
