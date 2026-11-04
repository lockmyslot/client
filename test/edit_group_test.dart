import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/groups/data/groups_repository.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/screens/create_group_sheet.dart';
import 'package:lockmyslot_app/features/groups/screens/edit_group_sheet.dart';
import 'package:lockmyslot_app/features/groups/widgets/group_avatar.dart';

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
}
