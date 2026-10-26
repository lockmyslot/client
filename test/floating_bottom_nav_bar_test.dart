import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/shared/widgets/floating_bottom_nav_bar.dart';

void main() {
  group('FloatingBottomNavBar Widget Tests', () {
    testWidgets('renders all tabs with labels positioned below icons', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNavBar(
              currentIndex: selectedIndex,
              onTap: (index) => selectedIndex = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final groupsFinder = find.text('Groups');
      final bookingsFinder = find.text('Bookings');
      final meFinder = find.text('Me');

      expect(groupsFinder, findsOneWidget);
      expect(bookingsFinder, findsOneWidget);
      expect(meFinder, findsOneWidget);

      // Verify label is positioned vertically below the icon in each tab
      for (final label in ['Groups', 'Bookings', 'Me']) {
        final labelFinder = find.text(label);
        final tabItemColumnFinder = find.ancestor(
          of: labelFinder,
          matching: find.byType(Column),
        );
        expect(tabItemColumnFinder, findsOneWidget);

        // Find the icon within the same Column
        final iconFinder = find.descendant(
          of: tabItemColumnFinder,
          matching: find.byType(Icon),
        );
        expect(iconFinder, findsOneWidget);

        // Verify vertical coordinates: icon is above label (icon.top < label.top)
        final iconOffset = tester.getTopLeft(iconFinder);
        final labelOffset = tester.getTopLeft(labelFinder);
        expect(
          labelOffset.dy,
          greaterThan(iconOffset.dy),
          reason: 'Label "$label" must be below the icon',
        );
      }
    });

    testWidgets('tapping on tabs triggers onTap callback with correct index', (
      WidgetTester tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNavBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Bookings tab (index 1)
      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(1));

      // Tap Me tab (index 2)
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(2));

      // Tap Groups tab (index 0)
      await tester.tap(find.text('Groups'));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(0));
    });

    testWidgets('renders action FAB when provided and responds to tap', (
      WidgetTester tester,
    ) async {
      bool fabTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              fabIcon: Icons.add,
              fabTooltip: 'Add Item',
              onFabPressed: () => fabTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fabFinder = find.byTooltip('Add Item');
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder);
      await tester.pumpAndSettle();
      expect(fabTapped, isTrue);
    });

    testWidgets('smoothly handles pageProgress interpolation without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingBottomNavBar(
              currentIndex: 0,
              pageProgress: 0.5,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
