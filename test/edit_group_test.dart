import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/groups/data/groups_repository.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/create_group_sheet.dart';
import 'package:lockmyslot_app/features/groups/screens/edit_group_sheet.dart';
import 'package:lockmyslot_app/features/groups/screens/group_detail_screen.dart';
import 'package:lockmyslot_app/features/groups/widgets/group_avatar.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/shared/widgets/m3_collapsing_app_bar.dart';

class FakeGroupsRepository extends Fake implements GroupsRepository {
  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;

  @override
  Future<Group> createGroup(
    String name, {
    String? color,
    String? icon,
  }) async {
    lastCreateArgs = {
      'name': name,
      'color': color,
      'icon': icon,
    };
    return Group(
      id: 'grp-new',
      name: name,
      color: color,
      icon: icon,
      inviteCode: 'CODE12',
      role: 'ADMIN',
      memberCount: 1,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Group> updateGroup(
    String groupId, {
    String? name,
    String? color,
    String? icon,
  }) async {
    lastUpdateArgs = {
      'groupId': groupId,
      'name': name,
      'color': color,
      'icon': icon,
    };
    return Group(
      id: groupId,
      name: name ?? 'Existing',
      color: color,
      icon: icon,
      inviteCode: 'CODE12',
      role: 'ADMIN',
      memberCount: 2,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('CreateGroupSheet with Color Coding Tests', () {
    testWidgets('allows choosing a color and submits group with color',
        (tester) async {
      final fakeRepo = FakeGroupsRepository();
      Group? createdGroup;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CreateGroupSheet(
                onSuccess: (g) => createdGroup = g,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Create Group'), findsWidgets);
      expect(find.byType(GroupAvatar), findsOneWidget);

      // Enter group name
      final nameField = find.widgetWithText(TextFormField, 'Group Name *');
      await tester.enterText(nameField, 'Squash Club');
      await tester.pumpAndSettle();

      // Pick emerald color
      await tester.tap(find.byTooltip('Emerald'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create Group').last);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreateArgs, isNotNull);
      expect(fakeRepo.lastCreateArgs!['name'], equals('Squash Club'));
      expect(fakeRepo.lastCreateArgs!['color'], equals('#10B981'));
      expect(createdGroup?.color, equals('#10B981'));
    });
  });

  group('EditGroupSheet with Color Coding Tests', () {
    testWidgets('pre-fills existing name and color, allows updating color',
        (tester) async {
      final fakeRepo = FakeGroupsRepository();
      final initialGroup = Group(
        id: 'grp-edit-1',
        name: 'Design Team',
        color: '#3B82F6',
        inviteCode: 'DES123',
        role: 'ADMIN',
        memberCount: 5,
        createdAt: DateTime.now(),
      );

      Group? updatedGroup;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EditGroupSheet(
                group: initialGroup,
                onSuccess: (g) => updatedGroup = g,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Edit Group'), findsOneWidget);
      expect(find.text('Design Team'), findsWidgets);

      // Change color to Rose (#F43F5E)
      await tester.tap(find.byTooltip('Rose'));
      await tester.pumpAndSettle();

      // Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdateArgs, isNotNull);
      expect(fakeRepo.lastUpdateArgs!['groupId'], equals('grp-edit-1'));
      expect(fakeRepo.lastUpdateArgs!['name'], equals('Design Team'));
      expect(fakeRepo.lastUpdateArgs!['color'], equals('#F43F5E'));
      expect(updatedGroup?.color, equals('#F43F5E'));
    });
  });

  group('GroupDetailScreen Edit Action Tests', () {
    testWidgets(
        'admin sees Edit button in quick action row and no top-right edit icon or invite button',
        (tester) async {
      final fakeRepo = FakeGroupsRepository();
      final adminGroup = Group(
        id: 'grp-admin',
        name: 'Tennis Club',
        color: '#10B981',
        inviteCode: 'TEN123',
        role: 'ADMIN',
        memberCount: 4,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
            groupDetailProvider('grp-admin')
                .overrideWith((ref) async => adminGroup),
            groupResourcesProvider('grp-admin').overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: 'grp-admin'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top right edit icon in M3CollapsingAppBar should NOT exist
      final m3AppBar = find.byType(M3CollapsingAppBar);
      expect(m3AppBar, findsOneWidget);
      expect(
        find.descendant(of: m3AppBar, matching: find.byTooltip('Edit Group')),
        findsNothing,
      );

      // "Invite" button should NOT exist in quick actions
      expect(find.text('Invite'), findsNothing);

      // Group code pill should exist
      expect(find.textContaining('TEN123'), findsOneWidget);

      // "Edit" action button should exist in quick actions as OutlinedButton
      final editButton = find.widgetWithText(OutlinedButton, 'Edit');
      expect(editButton, findsOneWidget);

      // Tapping Edit button opens EditGroupSheet
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(EditGroupSheet), findsOneWidget);
    });

    testWidgets(
        'non-admin does not see Edit button in quick action row or top-right edit icon',
        (tester) async {
      final fakeRepo = FakeGroupsRepository();
      final memberGroup = Group(
        id: 'grp-member',
        name: 'Book Club',
        color: '#3B82F6',
        inviteCode: 'BOOK12',
        role: 'MEMBER',
        memberCount: 3,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupsRepositoryProvider.overrideWithValue(fakeRepo),
            groupDetailProvider('grp-member')
                .overrideWith((ref) async => memberGroup),
            groupResourcesProvider('grp-member')
                .overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: 'grp-member'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No edit button in quick actions or app bar
      expect(find.widgetWithText(OutlinedButton, 'Edit'), findsNothing);
      expect(find.text('Invite'), findsNothing);
      expect(find.byTooltip('Edit Group'), findsNothing);

      // Group code pill is still displayed for member
      expect(find.textContaining('BOOK12'), findsOneWidget);
      // My Bookings button is displayed
      expect(
          find.widgetWithText(OutlinedButton, 'My Bookings'), findsOneWidget);
    });
  });
}
