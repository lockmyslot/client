import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/api/api_exceptions.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/core/utils/deep_link_utils.dart';
import 'package:lockmyslot_app/features/groups/data/groups_repository.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/data/models/group_member.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/invite_member_sheet.dart';
import 'package:lockmyslot_app/features/groups/screens/members_screen.dart';
import 'package:lockmyslot_app/features/groups/screens/unified_invite_sheet.dart';
import 'package:lockmyslot_app/shared/widgets/m3_collapsing_app_bar.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeGroupsRepository extends GroupsRepository {
  FakeGroupsRepository() : super(ApiClient(storage: FakeSecureStorage()));

  String? lastGroupId;
  String? lastUsername;
  Exception? throwError;

  @override
  Future<GroupMember> inviteMember(String groupId, String username) async {
    lastGroupId = groupId;
    lastUsername = username;
    if (throwError != null) {
      throw throwError!;
    }
    return GroupMember(
      id: 'user-new',
      groupId: groupId,
      userId: 'user-new',
      displayName: 'Invited User',
      username: username,
      role: 'MEMBER',
      joinedAt: DateTime.now(),
    );
  }
}

void main() {
  group('InviteMemberSheet Widget Tests', () {
    late FakeGroupsRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeGroupsRepository();
    });

    testWidgets('renders all sheet elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InviteMemberSheet(
                groupId: 'g1',
                groupName: 'Test Group',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Invite Member'), findsOneWidget);
      expect(
        find.text('Invite a user to Test Group by username'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Invite to Group'), findsOneWidget);
    });

    testWidgets('shows validation error when username is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InviteMemberSheet(
                groupId: 'g1',
                groupName: 'Test Group',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Invite to Group'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a username'), findsOneWidget);
      expect(fakeRepo.lastUsername, isNull);
    });

    testWidgets('invites user successfully and strips leading @', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => InviteMemberSheet.show(
                    context,
                    groupId: 'g1',
                    groupName: 'Test Group',
                  ),
                  child: const Text('Open Invite'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Invite'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '@charlie');
      await tester.tap(find.text('Invite to Group'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastGroupId, 'g1');
      expect(fakeRepo.lastUsername, 'charlie');
      expect(
        find.text('Successfully invited @charlie to the group!'),
        findsOneWidget,
      );
    });

    testWidgets('displays error when user not found', (
      WidgetTester tester,
    ) async {
      fakeRepo.throwError = const NotFoundException('user_not_found');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InviteMemberSheet(
                groupId: 'g1',
                groupName: 'Test Group',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'nobody');
      await tester.tap(find.text('Invite to Group'));
      await tester.pumpAndSettle();

      expect(
        find.text('User "@nobody" not found. Please verify the username.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error when user is already a member', (
      WidgetTester tester,
    ) async {
      fakeRepo.throwError = const ConflictException('already_a_member');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InviteMemberSheet(
                groupId: 'g1',
                groupName: 'Test Group',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'alice');
      await tester.tap(find.text('Invite to Group'));
      await tester.pumpAndSettle();

      expect(
        find.text('User "@alice" is already a member of this group.'),
        findsOneWidget,
      );
    });
  });

  group('MembersScreen Invite Tests', () {
    testWidgets('shows bottom bar invite button and no top-right invite icon', (
      WidgetTester tester,
    ) async {
      final adminGroup = Group(
        id: 'g1',
        name: 'Alpha Group',
        role: 'ADMIN',
        memberCount: 2,
        createdAt: DateTime.now(),
        inviteCode: 'AB12CD',
      );

      final members = [
        GroupMember(
          id: 'm1',
          groupId: 'g1',
          userId: 'u1',
          displayName: 'Admin User',
          username: 'admin_boss',
          role: 'ADMIN',
          joinedAt: DateTime.now(),
        ),
        GroupMember(
          id: 'm2',
          groupId: 'g1',
          userId: 'u2',
          displayName: 'Regular User',
          username: 'regular_joe',
          role: 'MEMBER',
          joinedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupDetailProvider('g1').overrideWith((ref) => adminGroup),
            groupMembersProvider('g1').overrideWith((ref) => members),
          ],
          child: const MaterialApp(
            home: MembersScreen(groupId: 'g1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No invite action in app bar
      expect(find.byTooltip('Invite by Username'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(M3CollapsingAppBar),
          matching: find.byIcon(Icons.person_add_outlined),
        ),
        findsNothing,
      );

      // Bottom bar has invite code and Invite button
      expect(find.text('AB12CD'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Invite'), findsOneWidget);
      expect(
        find.widgetWithIcon(TextButton, Icons.person_add_outlined),
        findsOneWidget,
      );

      // Check usernames rendered
      expect(find.text('@admin_boss'), findsOneWidget);
      expect(find.text('@regular_joe'), findsOneWidget);

      // Tapping Invite button opens UnifiedInviteSheet
      await tester.tap(find.widgetWithText(TextButton, 'Invite'));
      await tester.pumpAndSettle();
      expect(find.byType(UnifiedInviteSheet), findsOneWidget);
    });

    testWidgets('hides invite bottom bar when group has no invite code', (
      WidgetTester tester,
    ) async {
      final memberGroup = Group(
        id: 'g2',
        name: 'Beta Group',
        role: 'MEMBER',
        memberCount: 2,
        createdAt: DateTime.now(),
      );

      final members = [
        GroupMember(
          id: 'm1',
          groupId: 'g2',
          userId: 'u1',
          displayName: 'Owner',
          role: 'ADMIN',
          joinedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupDetailProvider('g2').overrideWith((ref) => memberGroup),
            groupMembersProvider('g2').overrideWith((ref) => members),
          ],
          child: const MaterialApp(
            home: MembersScreen(groupId: 'g2'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add_outlined), findsNothing);
      expect(find.text('Invite'), findsNothing);
    });
  });

  group('DeepLinkUtils Invite Sheet Tests', () {
    testWidgets('renders Invite by Username button when groupId is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DeepLinkUtils.showInviteSheet(
                  context,
                  groupName: 'Test Group',
                  inviteCode: 'XY98ZW',
                  groupId: 'g1',
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Invite by Username'), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsOneWidget);
    });
  });
}
