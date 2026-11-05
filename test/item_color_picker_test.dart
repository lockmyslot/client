import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/shared/widgets/item_color_picker.dart';

void main() {
  group('ItemColorPickerRow Widget Tests', () {
    testWidgets('renders title and swatches for all palette colors plus default',
        (tester) async {
      String? selectedHex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ItemColorPickerRow(
              selectedHex: selectedHex,
              onChanged: (hex) => selectedHex = hex,
              title: 'Select Item Color',
            ),
          ),
        ),
      );

      expect(find.text('Select Item Color'), findsOneWidget);
      // Tooltip for Theme Default
      expect(find.byTooltip('Theme Default'), findsOneWidget);
      // Tooltips for palette colors
      expect(find.byTooltip('Slate'), findsOneWidget);
      expect(find.byTooltip('Red'), findsOneWidget);
      expect(find.byTooltip('Blue'), findsOneWidget);
      expect(find.byTooltip('Emerald'), findsOneWidget);
    });

    testWidgets('tapping a color swatch fires onChanged with that hex color',
        (tester) async {
      String? selectedHex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ItemColorPickerRow(
                  selectedHex: selectedHex,
                  onChanged: (hex) {
                    setState(() => selectedHex = hex);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap Blue
      await tester.tap(find.byTooltip('Blue'));
      await tester.pumpAndSettle();

      expect(selectedHex, equals('#3B82F6'));

      // Tap again toggles to null
      await tester.tap(find.byTooltip('Blue'));
      await tester.pumpAndSettle();

      expect(selectedHex, isNull);
    });

    testWidgets('tapping Theme Default resets selected color to null',
        (tester) async {
      String? selectedHex = '#EF4444';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ItemColorPickerRow(
                  selectedHex: selectedHex,
                  onChanged: (hex) {
                    setState(() => selectedHex = hex);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      expect(selectedHex, isNull);
    });
  });
}
