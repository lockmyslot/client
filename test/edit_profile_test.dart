import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/auth/data/models/user.dart';
import 'package:lockmyslot_app/features/auth/providers/auth_provider.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:lockmyslot_app/features/bookings/providers/my_bookings_provider.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/profile/screens/edit_profile_sheet.dart';
import 'package:lockmyslot_app/features/profile/screens/me_profile_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  String? lastUpdatedDisplayName;
  String? lastUpdatedUsername;
  String? lastUpdatedPassword;

  @override
  Future<User> updateProfile({
    String? displayName,
    String? username,
    String? password,
  }) async {
    lastUpdatedDisplayName = displayName;
    lastUpdatedUsername = username;
    lastUpdatedPassword = password;

    final updated = state.user!.copyWith(
      displayName: displayName ?? state.user!.displayName,
      username: username ?? state.user!.username,
    );
    state = state.copyWith(user: updated);
    return updated;
  }

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

void main() {
  final testUser = User(
    id: 'user-1',
    displayName: 'Alex Smith',
    username: 'alex',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  Widget createMeScreen({required _FakeAuthNotifier authNotifier}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
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

  testWidgets('Me tab displays Edit Profile buttons in header and account tile',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authNotifier = _FakeAuthNotifier(
      AuthState(
        user: testUser,
        isAuthenticated: true,
        isInitialized: true,
      ),
    );

    await tester.pumpWidget(createMeScreen(authNotifier: authNotifier));
    await tester.pumpAndSettle();

    // Verify Edit Profile button in user header card
    expect(find.widgetWithText(FilledButton, 'Edit Profile'), findsOneWidget);

    // Verify Account section heading
    expect(find.text('Account'), findsOneWidget);

    // Verify Edit Profile list tile
    expect(find.widgetWithText(ListTile, 'Edit Profile'), findsOneWidget);
    expect(find.text('Name, username, password'), findsOneWidget);

    // Verify app bar action icon
    expect(find.byTooltip('Edit Profile'), findsOneWidget);
  });

  testWidgets('tapping Edit Profile opens EditProfileSheet prefilled',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authNotifier = _FakeAuthNotifier(
      AuthState(
        user: testUser,
        isAuthenticated: true,
        isInitialized: true,
      ),
    );

    await tester.pumpWidget(createMeScreen(authNotifier: authNotifier));
    await tester.pumpAndSettle();

    // Tap Edit Profile button on header card
    await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
    await tester.pumpAndSettle();

    // Verify EditProfileSheet opened
    expect(find.byType(EditProfileSheet), findsOneWidget);
    expect(find.text('Edit Profile'), findsWidgets);
    expect(find.text('Update your name, username, or password'), findsOneWidget);

    // Verify prefilled values
    expect(find.text('Alex Smith'), findsWidgets);
    expect(find.text('alex'), findsOneWidget);

    // Verify password fields
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
  });

  testWidgets('EditProfileSheet validates name and password confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authNotifier = _FakeAuthNotifier(
      AuthState(
        user: testUser,
        isAuthenticated: true,
        isInitialized: true,
      ),
    );

    await tester.pumpWidget(createMeScreen(authNotifier: authNotifier));
    await tester.pumpAndSettle();

    // Open sheet via Account tile
    await tester.tap(find.widgetWithText(ListTile, 'Edit Profile'));
    await tester.pumpAndSettle();

    // Clear name
    final nameFinder = find.widgetWithText(TextFormField, 'Display Name *');
    await tester.enterText(nameFinder, '');

    // Enter short password
    final newPassFinder = find.widgetWithText(TextFormField, 'New Password');
    await tester.enterText(newPassFinder, '12');

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Validation errors should appear
    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.text('Password must be at least 4 characters'), findsOneWidget);

    // Fix name and password, but mismatch confirmation
    await tester.enterText(nameFinder, 'Alexander');
    await tester.enterText(newPassFinder, 'secret123');
    final confirmFinder =
        find.widgetWithText(TextFormField, 'Confirm New Password');
    await tester.enterText(confirmFinder, 'different123');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets(
      'EditProfileSheet updates name, username, and password successfully',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authNotifier = _FakeAuthNotifier(
      AuthState(
        user: testUser,
        isAuthenticated: true,
        isInitialized: true,
      ),
    );

    await tester.pumpWidget(createMeScreen(authNotifier: authNotifier));
    await tester.pumpAndSettle();

    // Open sheet
    await tester.tap(find.widgetWithText(FilledButton, 'Edit Profile'));
    await tester.pumpAndSettle();

    // Update Name
    final nameFinder = find.widgetWithText(TextFormField, 'Display Name *');
    await tester.enterText(nameFinder, 'Alex Great');

    // Update Username
    final userFinder = find.widgetWithText(TextFormField, 'Username');
    await tester.enterText(userFinder, 'alex_great');

    // Update Password
    final newPassFinder = find.widgetWithText(TextFormField, 'New Password');
    await tester.enterText(newPassFinder, 'newSecret123');
    final confirmFinder =
        find.widgetWithText(TextFormField, 'Confirm New Password');
    await tester.enterText(confirmFinder, 'newSecret123');

    // Submit
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify updateProfile was called with new values
    expect(authNotifier.lastUpdatedDisplayName, 'Alex Great');
    expect(authNotifier.lastUpdatedUsername, 'alex_great');
    expect(authNotifier.lastUpdatedPassword, 'newSecret123');

    // Sheet should be closed
    expect(find.byType(EditProfileSheet), findsNothing);

    // Success snackbar displayed
    expect(find.text('Profile updated successfully'), findsOneWidget);

    // Me tab should now reflect the updated name and username
    expect(find.text('Alex Great'), findsOneWidget);
    expect(find.text('@alex_great'), findsOneWidget);
  });
}
