import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/data/models/group_member.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/members_screen.dart';

void main() {
  group('MembersScreen Widget Tests', () {
    testWidgets(
      'renders admin shield badge for admin, guest badge for guest, and no badge or pill for member/mod',
      (WidgetTester tester) async {
        final testGroup = Group(
          id: 'g1',
          name: 'Gym Bros',
          role: 'ADMIN',
          memberCount: 4,
          createdAt: DateTime.now(),
        );

        final testMembers = [
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
            displayName: 'Charlie Mod',
            role: 'MOD',
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: 'm4',
            groupId: 'g1',
            userId: 'u4',
            displayName: 'Dave Guest',
            role: 'GUEST',
            joinedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              groupDetailProvider('g1').overrideWith((ref) => testGroup),
              groupMembersProvider('g1').overrideWith((ref) => testMembers),
            ],
            child: const MaterialApp(
              home: MembersScreen(groupId: 'g1'),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Display names are rendered
        expect(find.text('Alice Admin'), findsOneWidget);
        expect(find.text('Bob Member'), findsOneWidget);
        expect(find.text('Charlie Mod'), findsOneWidget);
        expect(find.text('Dave Guest'), findsOneWidget);

        // No role pills are rendered
        expect(find.text('ADMIN'), findsNothing);
        expect(find.text('Admin'), findsNothing);
        expect(find.text('MEMBER'), findsNothing);
        expect(find.text('Member'), findsNothing);
        expect(find.text('MOD'), findsNothing);
        expect(find.text('Mod'), findsNothing);
        expect(find.text('GUEST'), findsNothing);
        expect(find.text('Guest'), findsNothing);

        // Exactly one admin shield icon and one guest badge icon
        expect(find.byIcon(Icons.shield), findsOneWidget);
        expect(find.byIcon(Icons.badge), findsOneWidget);
      },
    );
  });
}
