import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/features/groups/data/groups_repository.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/data/models/group_member.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/change_role_sheet.dart';
import 'package:lockmyslot_app/features/groups/screens/members_screen.dart';

class MockGroupsRepository extends Fake implements GroupsRepository {
  String? updatedGroupId;
  String? updatedUserId;
  String? updatedRole;
  DateTime? updatedExpiresAt;
  String? removedUserId;

  @override
  Future<GroupMember> updateMemberRole(
    String groupId,
    String userId,
    String role, {
    DateTime? expiresAt,
  }) async {
    updatedGroupId = groupId;
    updatedUserId = userId;
    updatedRole = role;
    updatedExpiresAt = expiresAt;
    return GroupMember(
      id: 'm2',
      groupId: groupId,
      userId: userId,
      displayName: 'Bob Member',
      role: role,
      expiresAt: expiresAt,
      joinedAt: DateTime.now(),
    );
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    removedUserId = userId;
  }
}

void main() {
  group('ChangeRoleSheet Widget Tests', () {
    late MockGroupsRepository mockRepo;
    final testMember = GroupMember(
      id: 'm2',
      groupId: 'g1',
      userId: 'u2',
      displayName: 'Bob Member',
      role: 'MEMBER',
      joinedAt: DateTime.now(),
    );

    setUp(() {
      mockRepo = MockGroupsRepository();
    });

    testWidgets('renders all 4 role options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChangeRoleSheet(groupId: 'g1', member: testMember),
            ),
          ),
        ),
      );

      expect(find.text('Change Member Role'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Moderator'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Save Role'), findsOneWidget);
    });

    testWidgets(
      'selecting Guest shows auto-removal date picker and submits with expiry',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              groupsRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ChangeRoleSheet(groupId: 'g1', member: testMember),
              ),
            ),
          ),
        );

        // Initially "Member" is selected, auto-removal date is not shown
        expect(find.text('Auto-Removal Date'), findsNothing);

        // Tap "Guest" option
        await tester.tap(find.text('Guest'));
        await tester.pumpAndSettle();

        // Now auto-removal date card is visible
        expect(find.text('Auto-Removal Date'), findsOneWidget);
        expect(find.text('Change Date'), findsOneWidget);

        // Ensure Save Role is scrolled into view and tap it
        await tester.ensureVisible(find.text('Save Role'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Role'));
        await tester.pump();

        expect(mockRepo.updatedGroupId, 'g1');
        expect(mockRepo.updatedUserId, 'u2');
        expect(mockRepo.updatedRole, 'GUEST');
        expect(mockRepo.updatedExpiresAt, isNotNull);
      },
    );

    testWidgets('selecting Moderator submits without expiry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ChangeRoleSheet(groupId: 'g1', member: testMember),
            ),
          ),
        ),
      );

      // Tap "Moderator"
      await tester.tap(find.text('Moderator'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Role'));
      await tester.pump();

      expect(mockRepo.updatedRole, 'MODERATOR');
      expect(mockRepo.updatedExpiresAt, isNull);
    });
  });

  group('Moderator permissions in MembersScreen', () {
    testWidgets(
      'moderator can remove guest but cannot remove regular member',
      (tester) async {
        final mockRepo = MockGroupsRepository();
        final modGroup = Group(
          id: 'g1',
          name: 'Gym Bros',
          role: 'MODERATOR',
          memberCount: 3,
          createdAt: DateTime.now(),
        );

        final members = [
          GroupMember(
            id: 'm1',
            groupId: 'g1',
            userId: 'u1',
            displayName: 'Alice Admin',
            role: 'ADMIN',
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: 'm2',
            groupId: 'g1',
            userId: 'u2',
            displayName: 'Bob Member',
            role: 'MEMBER',
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: 'm3',
            groupId: 'g1',
            userId: 'u3',
            displayName: 'Dave Guest',
            role: 'GUEST',
            expiresAt: DateTime.now().add(const Duration(days: 3)),
            joinedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              groupDetailProvider('g1').overrideWith((ref) => modGroup),
              groupMembersProvider('g1').overrideWith((ref) => members),
              groupsRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: MembersScreen(groupId: 'g1'),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Moderator should see only 1 delete icon (for the guest only, not for admin or member)
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);

        // Tap the delete icon
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Confirm dialog appears
        expect(find.text('Remove Member'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to remove Dave Guest from the group?',
          ),
          findsOneWidget,
        );

        // Tap confirm
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(mockRepo.removedUserId, 'u3');
      },
    );
  });
}
