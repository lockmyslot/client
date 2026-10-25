import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/auth/data/models/user.dart';
import 'package:lockmyslot_app/features/auth/providers/auth_provider.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:lockmyslot_app/features/bookings/providers/my_bookings_provider.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/profile/screens/me_profile_screen.dart';
import 'package:lockmyslot_app/features/profile/screens/theme_selection_sheet.dart';

void main() {
  final testUser = User(
    id: 'user-1',
    displayName: 'Alex Smith',
    username: 'alex',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  Widget createMeScreen({
    ThemeMode initialMode = ThemeMode.system,
    void Function(ThemeMode)? onThemeChanged,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) {
          return _FakeAuthNotifier(
            AuthState(
              user: testUser,
              isAuthenticated: true,
              isInitialized: true,
            ),
          );
        }),
        myGroupsProvider.overrideWith(() => _FakeMyGroupsNotifier()),
        allBookingsProvider((groupId: null, status: 'CONFIRMED')).overrideWith(
          (ref) async => <Booking>[],
        ),
      ],
      child: const MaterialApp(
        home: MeProfileScreen(),
      ),
    );
  }

  testWidgets('renders App Settings section with Theme tile', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createMeScreen());
    await tester.pumpAndSettle();

    // Verify App Settings heading exists
    expect(find.text('App Settings'), findsOneWidget);

    // Verify group options are removed from Me tab
    expect(find.text('Join a Group'), findsNothing);
    expect(find.text('Create a Group'), findsNothing);

    // Verify Theme tile and default title exist
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System default'), findsWidgets);
  });

  testWidgets('tapping Theme tile opens ThemeSelectionSheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createMeScreen());
    await tester.pumpAndSettle();

    // Tap the Theme tile
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    // ThemeSelectionSheet should be visible
    expect(find.byType(ThemeSelectionSheet), findsOneWidget);
    expect(find.text('Choose how Lock My Slot looks to you'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System default'), findsWidgets);
  });

  testWidgets('selecting Dark theme updates the theme mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createMeScreen());
    await tester.pumpAndSettle();

    // Open ThemeSelectionSheet
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    // Tap the Dark option
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    // Tap Done to close sheet
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // MeProfileScreen should now display Dark
    expect(find.text('Dark'), findsWidgets);
  });

  testWidgets('selecting Light theme updates the theme mode', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createMeScreen(initialMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    // Open ThemeSelectionSheet
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    // Tap the Light option
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    // Tap Done to close sheet
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // MeProfileScreen should now display Light
    expect(find.text('Light'), findsWidgets);
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMyGroupsNotifier extends AsyncNotifier<List<Group>>
    implements MyGroupsNotifier {
  @override
  Future<List<Group>> build() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
