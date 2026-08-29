import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/utils/deep_link_utils.dart';
import 'package:lockmyslot_app/features/groups/screens/join_group_screen.dart';

void main() {
  group('DeepLinkUtils Tests', () {
    test('buildWebInviteLink builds valid https link', () {
      final link = DeepLinkUtils.buildWebInviteLink('ab12cd');
      expect(link, 'https://lockmyslot.app/join?code=AB12CD');
    });

    test('buildCustomSchemeInviteLink builds valid lockmyslot scheme link', () {
      final link = DeepLinkUtils.buildCustomSchemeInviteLink('xy99zz');
      expect(link, 'lockmyslot://join?code=XY99ZZ');
    });
  });

  group('JoinGroupScreen Deep Link Prefill Widget Tests', () {
    testWidgets('populates initialCode into the text field when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JoinGroupScreen(initialCode: 'LMS123'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, 'LMS123');
    });

    testWidgets('leaves text field empty when no initialCode is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JoinGroupScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, '');
    });
  });
}
