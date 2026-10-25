import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/group_detail_screen.dart';
import 'package:lockmyslot_app/features/bookings/providers/bookings_provider.dart';
import 'package:lockmyslot_app/features/resources/providers/maintenance_provider.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/features/resources/screens/resource_detail_screen.dart';
import 'package:lockmyslot_app/features/resources/widgets/resource_avatar.dart';
import 'package:lockmyslot_app/features/resources/widgets/resource_icon_picker.dart';

void main() {
  group('Resource Icon Utilities Tests', () {
    test('getResourceInitials extracts initials accurately', () {
      // Multi-word names
      expect(getResourceInitials('Washing Machine'), 'WM');
      expect(getResourceInitials('Room 101'), 'R1');
      expect(getResourceInitials('Conference Room Alpha'), 'CR');
      expect(getResourceInitials('Tennis Court'), 'TC');

      // Single-word names
      expect(getResourceInitials('Room'), 'RO');
      expect(getResourceInitials('Computer'), 'CO');
      expect(getResourceInitials('Gym'), 'GY');
      expect(getResourceInitials('A'), 'A');

      // Edge cases: null, empty, whitespace
      expect(getResourceInitials(null), '?');
      expect(getResourceInitials(''), '?');
      expect(getResourceInitials('   '), '?');
    });

    test('getResourceIcon retrieves IconData for common resource items', () {
      // Definitely included items
      expect(
        getResourceIcon('washing_machine'),
        Icons.local_laundry_service,
      );
      expect(getResourceIcon('room'), Icons.meeting_room);
      expect(getResourceIcon('computer'), Icons.computer);

      // Other common items
      expect(getResourceIcon('laptop'), Icons.laptop);
      expect(getResourceIcon('tv'), Icons.tv);
      expect(getResourceIcon('gym'), Icons.fitness_center);
      expect(getResourceIcon('kitchen'), Icons.kitchen);

      // Unknown or null/empty keys return null
      expect(getResourceIcon('unknown_key'), isNull);
      expect(getResourceIcon(null), isNull);
      expect(getResourceIcon(''), isNull);
    });

    test('kCommonResourceIcons list contains washing machine, room, computer', () {
      final keys = kCommonResourceIcons.map((e) => e.key).toList();
      expect(keys, contains('washing_machine'));
      expect(keys, contains('room'));
      expect(keys, contains('computer'));

      // Check labels
      expect(
        kCommonResourceIcons.firstWhere((e) => e.key == 'washing_machine').label,
        'Washing Machine',
      );
      expect(
        kCommonResourceIcons.firstWhere((e) => e.key == 'room').label,
        'Room',
      );
      expect(
        kCommonResourceIcons.firstWhere((e) => e.key == 'computer').label,
        'Computer',
      );
    });
  });

  group('ResourceAvatar Widget Tests', () {
    testWidgets('renders Icon when iconKey is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResourceAvatar(
              iconKey: 'washing_machine',
              name: 'Washing Machine #1',
            ),
          ),
        ),
      );

      // Must find the icon
      expect(find.byIcon(Icons.local_laundry_service), findsOneWidget);
      // Must NOT find initials text "WM"
      expect(find.text('WM'), findsNothing);
    });

    testWidgets('renders initials when left alone (iconKey is null)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResourceAvatar(
              iconKey: null,
              name: 'Washing Machine #1',
            ),
          ),
        ),
      );

      // Left alone: uses initials "WM"
      expect(find.text('WM'), findsOneWidget);
      // No icon rendered
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders single word initials when left alone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ResourceAvatar(iconKey: null, name: 'Room'),
                ResourceAvatar(iconKey: null, name: 'Computer'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('RO'), findsOneWidget);
      expect(find.text('CO'), findsOneWidget);
    });
  });

  group('ResourceIconPicker & Selector Widget Tests', () {
    testWidgets('ResourceIconPickerSheet displays initials option and common icons',
        (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResourceIconPickerSheet(
              initialIconKey: null,
              resourceName: 'Meeting Room',
              onSelect: (val) => selected = val,
            ),
          ),
        ),
      );

      // Should show Use Initials ("MR")
      expect(find.textContaining('Use Initials'), findsOneWidget);

      // Should show common item labels
      expect(find.text('Washing Machine'), findsOneWidget);
      expect(find.text('Room'), findsOneWidget);
      expect(find.text('Computer'), findsOneWidget);

      // Tap on Washing Machine
      await tester.tap(find.text('Washing Machine'));
      expect(selected, 'washing_machine');
    });

    testWidgets('ResourceIconSelector allows quick selection and initials fallback',
        (tester) async {
      String? currentIcon;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ResourceIconSelector(
                  selectedIconKey: currentIcon,
                  resourceName: 'Computer Lab',
                  onChanged: (val) {
                    setState(() => currentIcon = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially left alone -> initials "CL"
      expect(find.text('CL'), findsWidgets);

      // Tap Computer quick chip
      await tester.tap(find.text('Computer'));
      await tester.pumpAndSettle();
      expect(currentIcon, 'computer');

      // Tap Initials chip to reset back to initials
      await tester.tap(find.text('Initials'));
      await tester.pumpAndSettle();
      expect(currentIcon, isNull);
    });

    testWidgets(
        'GroupDetailScreen displays resource icon in the list and initials when left alone',
        (tester) async {
      const testGroupId = 'grp-123';
      final mockGroup = Group(
        id: testGroupId,
        name: 'Shared Flat',
        inviteCode: 'FLAT12',
        role: 'ADMIN',
        memberCount: 3,
        createdAt: DateTime.now(),
      );

      final mockResources = [
        Resource(
          id: 'res-wm',
          groupId: testGroupId,
          name: 'Washing Machine',
          icon: 'washing_machine',
          capacity: 1,
          slotDurationMinutes: 60,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Resource(
          id: 'res-none',
          groupId: testGroupId,
          name: 'Tennis Court',
          icon: null, // Left alone: uses initials "TC"
          capacity: 4,
          slotDurationMinutes: 60,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupDetailProvider(testGroupId)
                .overrideWith((ref) async => mockGroup),
            groupResourcesProvider(testGroupId)
                .overrideWith((ref) async => mockResources),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: testGroupId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Washing machine icon should be rendered in the list
      expect(find.byIcon(Icons.local_laundry_service), findsOneWidget);

      // Left alone item: initials "TC" rendered in avatar in the list
      expect(find.text('TC'), findsOneWidget);

      // Capacity and slot duration shown below the name
      expect(find.text('Capacity: 1'), findsOneWidget);
      expect(find.text('60m slot'), findsWidgets);

      // Book button removed from list item
      expect(find.text('Book'), findsNothing);
    });

    testWidgets('ResourceDetailScreen does NOT display resource icon or avatar',
        (tester) async {
      const testGroupId = 'grp-123';
      const testResourceId = 'res-wm';
      final mockResource = Resource(
        id: testResourceId,
        groupId: testGroupId,
        name: 'Washing Machine',
        icon: 'washing_machine',
        capacity: 1,
        slotDurationMinutes: 60,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourceDetailProvider((
              groupId: testGroupId,
              resourceId: testResourceId,
            )).overrideWith((ref) async => mockResource),
            resourceBookingsProvider((
              groupId: testGroupId,
              resourceId: testResourceId,
              date: null,
            )).overrideWith((ref) async => []),
            resourceMaintenanceProvider((
              groupId: testGroupId,
              resourceId: testResourceId,
              status: null,
            )).overrideWith((ref) async => []),
            groupDetailProvider(testGroupId)
                .overrideWith((ref) async => Group(
                      id: testGroupId,
                      name: 'Shared Flat',
                      inviteCode: 'FLAT12',
                      role: 'ADMIN',
                      memberCount: 3,
                      createdAt: DateTime.now(),
                    )),
          ],
          child: const MaterialApp(
            home: ResourceDetailScreen(
              groupId: testGroupId,
              resourceId: testResourceId,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Detail page should NOT display ResourceAvatar
      expect(find.byType(ResourceAvatar), findsNothing);
    });
  });
}
