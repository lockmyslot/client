import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/groups_list_screen.dart';

class FakeMyGroupsNotifier extends MyGroupsNotifier {
  final List<Group> groups;
  FakeMyGroupsNotifier(this.groups);

  @override
  Future<List<Group>> build() async => groups;
}

void main() {
  group('GroupsListScreen Widget Tests', () {
    testWidgets(
      'renders admin shield badge on initial box and no role pill for admin group, and no badge for member group',
      (WidgetTester tester) async {
        final testGroups = [
          Group(
            id: 'g1',
            name: 'Gym Bros',
            role: 'ADMIN',
            memberCount: 5,
            createdAt: DateTime.now(),
          ),
          Group(
            id: 'g2',
            name: 'Study Room',
            role: 'MEMBER',
            memberCount: 3,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              myGroupsProvider.overrideWith(
                () => FakeMyGroupsNotifier(testGroups),
              ),
            ],
            child: const MaterialApp(
              home: GroupsListScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Group names are displayed
        expect(find.text('Gym Bros'), findsOneWidget);
        expect(find.text('Study Room'), findsOneWidget);

        // No "ADMIN", "Admin", "MEMBER", or "Member" role pills are displayed
        expect(find.text('ADMIN'), findsNothing);
        expect(find.text('Admin'), findsNothing);
        expect(find.text('MEMBER'), findsNothing);
        expect(find.text('Member'), findsNothing);

        // Admin shield icon is displayed exactly once (only on the Admin group)
        expect(find.byIcon(Icons.shield), findsOneWidget);

        // Member counts are rendered
        expect(find.text('5 members'), findsOneWidget);
        expect(find.text('3 members'), findsOneWidget);
      },
    );
  });
}
