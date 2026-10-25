import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/auth/data/models/user.dart';
import 'package:lockmyslot_app/features/auth/providers/auth_provider.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:lockmyslot_app/features/bookings/providers/my_bookings_provider.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/data/models/group_invite.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/profile/screens/me_profile_screen.dart';

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

class _FakePendingInvitesNotifier extends PendingInvitesNotifier {
  final List<GroupInvite> initialInvites;
  String? lastAcceptedId;
  String? lastDeclinedId;

  _FakePendingInvitesNotifier(this.initialInvites);

  @override
  Future<List<GroupInvite>> build() async => initialInvites;

  @override
  Future<void> accept(String inviteId) async {
    lastAcceptedId = inviteId;
    state = AsyncValue.data(
      (state.value ?? []).where((i) => i.id != inviteId).toList(),
    );
  }

  @override
  Future<void> decline(String inviteId) async {
    lastDeclinedId = inviteId;
    state = AsyncValue.data(
      (state.value ?? []).where((i) => i.id != inviteId).toList(),
    );
  }
}

void main() {
  final testUser = User(
    id: 'user-1',
    displayName: 'Alex Smith',
    username: 'alex',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  Widget createMeScreen({
    required _FakePendingInvitesNotifier fakeInvitesNotifier,
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
        pendingInvitesProvider.overrideWith(() => fakeInvitesNotifier),
      ],
      child: const MaterialApp(
        home: MeProfileScreen(),
      ),
    );
  }

  group('MeProfileScreen Pending Invites Tests', () {
    testWidgets('renders "No pending invitations" when list is empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeNotifier = _FakePendingInvitesNotifier([]);

      await tester.pumpWidget(
        createMeScreen(fakeInvitesNotifier: fakeNotifier),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Invites'), findsOneWidget);
      expect(find.text('No pending invitations'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('renders pending invite cards with Accept and Decline buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleInvites = [
        GroupInvite(
          id: 'inv-1',
          groupId: 'g-1',
          groupName: 'Board Game Crew',
          invitedById: 'admin-1',
          invitedByName: 'Charlie Admin',
          invitedByUsername: 'charlie',
          status: 'PENDING',
          createdAt: DateTime(2026, 10, 25),
        ),
      ];

      final fakeNotifier = _FakePendingInvitesNotifier(sampleInvites);

      await tester.pumpWidget(
        createMeScreen(fakeInvitesNotifier: fakeNotifier),
      );
      await tester.pumpAndSettle();

      // Heading and badge
      expect(find.text('Board Game Crew'), findsOneWidget);
      expect(find.text('Invited by Charlie Admin (@charlie)'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('tapping Accept calls notifier accept and shows snackbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleInvites = [
        GroupInvite(
          id: 'inv-1',
          groupId: 'g-1',
          groupName: 'Board Game Crew',
          invitedById: 'admin-1',
          invitedByName: 'Charlie Admin',
          invitedByUsername: 'charlie',
          status: 'PENDING',
          createdAt: DateTime(2026, 10, 25),
        ),
      ];

      final fakeNotifier = _FakePendingInvitesNotifier(sampleInvites);

      await tester.pumpWidget(
        createMeScreen(fakeInvitesNotifier: fakeNotifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.lastAcceptedId, 'inv-1');
      expect(find.text('Joined Board Game Crew!'), findsOneWidget);
    });

    testWidgets('tapping Decline shows confirmation and declines invite', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleInvites = [
        GroupInvite(
          id: 'inv-2',
          groupId: 'g-2',
          groupName: 'Tennis Club',
          invitedById: 'admin-2',
          invitedByName: 'Coach Sam',
          invitedByUsername: 'sam',
          status: 'PENDING',
          createdAt: DateTime(2026, 10, 25),
        ),
      ];

      final fakeNotifier = _FakePendingInvitesNotifier(sampleInvites);

      await tester.pumpWidget(
        createMeScreen(fakeInvitesNotifier: fakeNotifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      // ConfirmDialog is shown
      expect(find.text('Decline Invite'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to decline the invitation to "Tennis Club"?',
        ),
        findsOneWidget,
      );

      // Tap confirm decline button inside dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.lastDeclinedId, 'inv-2');
      expect(find.text('Declined invite to Tennis Club'), findsOneWidget);
    });
  });
}
