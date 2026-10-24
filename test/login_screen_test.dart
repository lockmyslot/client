import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/features/auth/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders all essential login elements and demo accounts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Welcome back to\nLockMySlot'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Alice (admin)'), findsOneWidget);
      expect(find.text('Bob (member)'), findsOneWidget);
    });

    testWidgets('tapping Alice demo chip autofills username and password', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final aliceChip = find.text('Alice (admin)');
      await tester.tap(aliceChip);
      await tester.pump();

      expect(find.text('alice'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter your username'), findsOneWidget);
    });
  });
}
