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

  @override
  Future<void> togglePin(String groupId, {bool? isPinned}) async {
    final currentList = state.value ?? groups;
    final currentGroup =
        currentList.where((g) => g.id == groupId).firstOrNull;
    final nextPinned = isPinned ?? !(currentGroup?.isPinned ?? false);

    final updatedList = currentList.map((g) {
      if (g.id == groupId) {
        return g.copyWith(isPinned: nextPinned);
      }
      return g;
    }).toList();

    updatedList.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

    state = AsyncValue.data(updatedList);
  }
}

void main() {
  group('GroupsListScreen Widget Tests', () {
    testWidgets(
      'renders role in subtitle metadata and member counts for each group',
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
          Group(
            id: 'g3',
            name: 'Gaming Lounge',
            role: 'MOD',
            memberCount: 8,
            createdAt: DateTime.now(),
          ),
          Group(
            id: 'g4',
            name: 'Open Coworking',
            role: 'GUEST',
            memberCount: 12,
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
        expect(find.text('Gaming Lounge'), findsOneWidget);
        expect(find.text('Open Coworking'), findsOneWidget);

        // Subtitle displays role and member counts
        expect(find.text('Admin • 5 members'), findsOneWidget);
        expect(find.text('Member • 3 members'), findsOneWidget);
        expect(find.text('Member • 8 members'), findsOneWidget);
        expect(find.text('Guest • 12 members'), findsOneWidget);
      },
    );

    testWidgets(
      'renders pinned group at the top with Pinned header and pin icon',
      (WidgetTester tester) async {
        final testGroups = [
          Group(
            id: 'g1',
            name: 'Study Room',
            role: 'MEMBER',
            memberCount: 3,
            createdAt: DateTime.now(),
            isPinned: true,
          ),
          Group(
            id: 'g2',
            name: 'Gym Bros',
            role: 'ADMIN',
            memberCount: 5,
            createdAt: DateTime.now(),
            isPinned: false,
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

        // Section headers
        expect(find.text('Pinned'), findsOneWidget);
        expect(find.text('All Groups'), findsOneWidget);

        // No persistent pin IconButton tooltip directly on the cards
        expect(find.byTooltip('Pin to top'), findsNothing);

        // Pin icon is rendered for the pinned group
        expect(find.byIcon(Icons.push_pin), findsNWidgets(2)); // 1 for Pinned header, 1 for the pinned card

        // Verify order: Study Room should appear above Gym Bros
        final studyRoomOffset = tester.getTopLeft(find.text('Study Room')).dy;
        final gymBrosOffset = tester.getTopLeft(find.text('Gym Bros')).dy;
        expect(studyRoomOffset, lessThan(gymBrosOffset));
      },
    );

    testWidgets(
      'long pressing a group reveals pinning option and pins group to top',
      (WidgetTester tester) async {
        final testGroups = [
          Group(
            id: 'g1',
            name: 'Group Alpha',
            role: 'MEMBER',
            memberCount: 2,
            createdAt: DateTime.now(),
            isPinned: false,
          ),
          Group(
            id: 'g2',
            name: 'Group Beta',
            role: 'MEMBER',
            memberCount: 4,
            createdAt: DateTime.now(),
            isPinned: false,
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

        // Initially no pinned headers
        expect(find.text('PINNED'), findsNothing);

        // Long press on Group Beta to reveal pinning option
        await tester.longPress(find.text('Group Beta'));
        await tester.pumpAndSettle();

        // Bottom sheet reveals "Pin to top"
        expect(find.text('Pin to top'), findsOneWidget);

        // Tap "Pin to top"
        await tester.tap(find.text('Pin to top'));
        await tester.pumpAndSettle();

        // Group Beta is now pinned at top
        expect(find.text('Pinned'), findsOneWidget);
        expect(find.text('All Groups'), findsOneWidget);

        final betaOffset = tester.getTopLeft(find.text('Group Beta')).dy;
        final alphaOffset = tester.getTopLeft(find.text('Group Alpha')).dy;
        expect(betaOffset, lessThan(alphaOffset));

        // Long press Group Beta again to unpin
        await tester.longPress(find.text('Group Beta'));
        await tester.pumpAndSettle();

        expect(find.text('Unpin from top'), findsOneWidget);
        await tester.tap(find.text('Unpin from top'));
        await tester.pumpAndSettle();

        // No more pinned header
        expect(find.text('Pinned'), findsNothing);
      },
    );

    testWidgets(
      'long press menu displays larger group name and invite option which opens invite sheet',
      (WidgetTester tester) async {
        final testGroups = [
          Group(
            id: 'g1',
            name: 'Robotics Club',
            role: 'ADMIN',
            inviteCode: 'ROBO99',
            memberCount: 8,
            createdAt: DateTime.now(),
            isPinned: false,
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

        // Long press to open menu
        await tester.longPress(find.text('Robotics Club'));
        await tester.pumpAndSettle();

        // Group name is rendered in the bottom sheet with larger typography
        final titleTextWidgets = tester
            .widgetList<Text>(find.text('Robotics Club'))
            .toList();
        expect(titleTextWidgets.length, 2); // 1 on card, 1 in bottom sheet
        final sheetTitle = titleTextWidgets.firstWhere(
          (t) => t.style?.fontSize == 22,
        );
        expect(sheetTitle.style?.fontWeight, FontWeight.bold);

        // Invite option is present
        expect(find.text('Invite'), findsOneWidget);
        expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);

        // Tap Invite
        await tester.tap(find.text('Invite'));
        await tester.pumpAndSettle();

        // Invite sheet should appear
        expect(find.text('Invite to Robotics Club'), findsOneWidget);
        expect(find.text('ROBO99'), findsOneWidget);
      },
    );
  });
}
