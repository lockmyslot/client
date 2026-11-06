import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/groups/data/groups_repository.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/data/models/group_invite.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/groups_list_screen.dart';
import 'package:lockmyslot_app/features/groups/screens/join_group_sheet.dart';
import 'package:lockmyslot_app/features/groups/screens/unified_invite_sheet.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeGroupsRepository extends GroupsRepository {
  FakeGroupsRepository() : super(ApiClient(storage: FakeSecureStorage()));

  String? lastGroupId;
  String? lastUsername;
  String? lastRole;
  DateTime? lastExpiresAt;
  String? lastRegeneratedGroupId;
  Exception? throwError;

  @override
  Future<dynamic> inviteMember(
    String groupId,
    String username, {
    String role = 'GUEST',
    DateTime? expiresAt,
  }) async {
    lastGroupId = groupId;
    lastUsername = username;
    lastRole = role;
    lastExpiresAt = expiresAt;
    if (throwError != null) {
      throw throwError!;
    }
    return GroupInvite(
      id: 'inv-123',
      groupId: groupId,
      groupName: 'Test Group',
      invitedByUsername: 'admin',
      role: role,
      expiresAt: expiresAt,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Group> regenerateInviteCode(String groupId) async {
    lastRegeneratedGroupId = groupId;
    if (throwError != null) {
      throw throwError!;
    }
    return Group(
      id: groupId,
      name: 'Test Group',
      inviteCode: 'NEW999',
      role: 'ADMIN',
      memberCount: 2,
      createdAt: DateTime.now(),
    );
  }
}

class FakePendingInvitesNotifier extends PendingInvitesNotifier {
  final List<GroupInvite> initialInvites;
  String? lastAcceptedInviteId;
  String? lastDeclinedInviteId;

  FakePendingInvitesNotifier(this.initialInvites);

  @override
  Future<List<GroupInvite>> build() async => initialInvites;

  @override
  Future<void> accept(String inviteId) async {
    lastAcceptedInviteId = inviteId;
    state = AsyncData(
      state.value?.where((inv) => inv.id != inviteId).toList() ?? [],
    );
  }

  @override
  Future<void> decline(String inviteId) async {
    lastDeclinedInviteId = inviteId;
    state = AsyncData(
      state.value?.where((inv) => inv.id != inviteId).toList() ?? [],
    );
  }
}

class FakeMyGroupsNotifier extends MyGroupsNotifier {
  final List<Group> initialGroups;
  FakeMyGroupsNotifier(this.initialGroups);

  @override
  Future<List<Group>> build() async => initialGroups;
}

void main() {
  group('UnifiedInviteSheet Widget Tests', () {
    late FakeGroupsRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeGroupsRepository();
    });

    testWidgets('renders Share Link & Code tab elements by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedInviteSheet(
                groupName: 'Design Squad',
                inviteCode: 'DES123',
                groupId: 'group-1',
                initialTab: InviteTab.share,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Invite to Design Squad'), findsOneWidget);
      expect(find.text('Share Link & Code'), findsOneWidget);
      expect(find.text('Invite by Username'), findsOneWidget);
      expect(find.text('INVITE CODE'), findsOneWidget);
      expect(find.text('DES123'), findsOneWidget);
      expect(find.text('Share Invite'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Copy Code'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
    });

    testWidgets('switches to Invite by Username tab and shows form', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedInviteSheet(
                groupName: 'Design Squad',
                inviteCode: 'DES123',
                groupId: 'group-1',
                initialTab: InviteTab.share,
              ),
            ),
          ),
        ),
      );

      // Tap "Invite by Username" tab
      await tester.tap(find.text('Invite by Username'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Send Invitation'), findsOneWidget);
    });

    testWidgets('sends direct invite to username and shows success message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedInviteSheet(
                groupName: 'Design Squad',
                inviteCode: 'DES123',
                groupId: 'group-1',
                initialTab: InviteTab.direct,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '@johndoe');
      await tester.ensureVisible(find.text('Send Invitation'));
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUsername, 'johndoe');
      expect(fakeRepo.lastGroupId, 'group-1');
      expect(fakeRepo.lastRole, 'GUEST');
      expect(fakeRepo.lastExpiresAt, isNotNull);
      expect(find.text('Invitation sent to @johndoe!'), findsOneWidget);
    });

    testWidgets('allows admin to invite user as Member, Moderator, or Admin', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedInviteSheet(
                groupName: 'Design Squad',
                inviteCode: 'DES123',
                groupId: 'group-1',
                initialTab: InviteTab.direct,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'alice');
      // Select Moderator role chip
      await tester.tap(find.byKey(const Key('role_chip_moderator')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Invitation'));
      await tester.tap(find.text('Send Invitation'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUsername, 'alice');
      expect(fakeRepo.lastRole, 'MODERATOR');
      expect(fakeRepo.lastExpiresAt, isNull);
    });

    testWidgets('regenerates invite code after confirmation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedInviteSheet(
                groupName: 'Design Squad',
                inviteCode: 'DES123',
                groupId: 'group-1',
                initialTab: InviteTab.share,
              ),
            ),
          ),
        ),
      );

      expect(find.text('DES123'), findsOneWidget);

      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Regenerate Invite Code?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Regenerate'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastRegeneratedGroupId, 'group-1');
      expect(find.text('NEW999'), findsOneWidget);
    });
  });

  group('JoinGroupSheet with Pending Invites Tests', () {
    testWidgets('renders pending invitations section and handles Accept & Decline', (tester) async {
      final fakePendingNotifier = FakePendingInvitesNotifier([
        GroupInvite(
          id: 'inv-1',
          groupId: 'grp-1',
          groupName: 'Alpha Team',
          invitedByName: 'Sarah Connor',
          status: 'PENDING',
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingInvitesProvider.overrideWith(() => fakePendingNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: JoinGroupSheet(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PENDING INVITATIONS (1)'), findsOneWidget);
      expect(find.text('Alpha Team'), findsOneWidget);
      expect(find.text('Invited by Sarah Connor'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      // Tap Accept
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(fakePendingNotifier.lastAcceptedInviteId, 'inv-1');
    });
  });

  group('GroupsListScreen Pending Invites Banner Tests', () {
    testWidgets('shows banner when user has pending invitations', (tester) async {
      final fakePendingNotifier = FakePendingInvitesNotifier([
        GroupInvite(
          id: 'inv-1',
          groupId: 'grp-1',
          groupName: 'Beta Club',
          invitedByName: 'John Doe',
          status: 'PENDING',
          createdAt: DateTime.now(),
        ),
      ]);

      final fakeGroupsNotifier = FakeMyGroupsNotifier([
        Group(
          id: 'grp-exist',
          name: 'Existing Group',
          inviteCode: 'EXT123',
          role: 'MEMBER',
          memberCount: 5,
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingInvitesProvider.overrideWith(() => fakePendingNotifier),
            myGroupsProvider.overrideWith(() => fakeGroupsNotifier),
          ],
          child: const MaterialApp(
            home: GroupsListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1 Pending Invitation'), findsOneWidget);
      expect(find.text('Tap to review and join your groups'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });
  });
}
