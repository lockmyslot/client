import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/theme/app_theme.dart';
import 'package:lockmyslot_app/shared/widgets/m3_collapsing_app_bar.dart';

void main() {
  group('M3CollapsingAppBar Widget Tests', () {
    testWidgets('renders expanded and collapsed titles with animated opacity on scroll', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const M3CollapsingAppBar(
                  title: Text('Settings'),
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

      // Both instances exist in the tree (expanded flexible space & collapsed toolbar)
      final textElements = find.text('Settings').evaluate().toList();
      expect(textElements.length, equals(2));

      // Verify font sizes
      final fontSizes = textElements
          .map((e) => DefaultTextStyle.of(e).style.fontSize)
          .toList();
      expect(fontSizes.contains(32.0), isTrue);
      expect(fontSizes.contains(24.0), isTrue);

      // Expanded is in flexibleSpace; Collapsed is in the toolbar
      final opacitiesBefore = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .toList();

      // At expanded rest state:
      // Flexible space opacity is 1.0
      // Collapsed toolbar title opacity is 0.0
      expect(opacitiesBefore.contains(1.0), isTrue);
      expect(opacitiesBefore.contains(0.0), isTrue);

      // Scroll down by 300 to fully collapse the header
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final opacitiesAfter = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .toList();

      // At fully collapsed state:
      // Flexible space opacity has faded out to 0.0
      // Collapsed toolbar title has faded in to 1.0
      expect(opacitiesAfter.contains(1.0), isTrue);
      expect(opacitiesAfter.contains(0.0), isTrue);
    });

    testWidgets('renders back button when canPop is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Scaffold(
                              body: CustomScrollView(
                                slivers: [
                                  M3CollapsingAppBar(
                                    title: Text('Subpage'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Go to Subpage'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to Subpage'));
      await tester.pumpAndSettle();

      // Standard BackButton should exist consistently
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('renders actions in the pinned toolbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                M3CollapsingAppBar(
                  title: const Text('Title'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
