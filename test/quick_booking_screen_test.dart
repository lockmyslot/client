import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/theme/app_theme.dart';
import 'package:lockmyslot_app/features/bookings/data/models/availability.dart';
import 'package:lockmyslot_app/features/bookings/providers/availability_provider.dart';
import 'package:lockmyslot_app/features/bookings/screens/quick_booking_screen.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/widgets/group_avatar.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/features/resources/widgets/resource_avatar.dart';

class _FakeMyGroupsNotifier extends MyGroupsNotifier {
  final List<Group> groups;
  _FakeMyGroupsNotifier(this.groups);

  @override
  Future<List<Group>> build() async => groups;
}

void main() {
  const testGroupId = 'group-1';
  const testResourceId = 'resource-1';

  final sampleGroup = Group(
    id: testGroupId,
    name: 'SAFAA C811',
    color: '#3B82F6',
    memberCount: 5,
    role: 'MEMBER',
    createdAt: DateTime.now(),
  );

  final sampleResource = Resource(
    id: testResourceId,
    groupId: testGroupId,
    name: 'Washing Machine',
    icon: 'washing_machine',
    color: '#10B981',
    capacity: 1,
    slotDurationMinutes: 60,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final todayStr = DateTime.now().toIso8601String().split('T')[0];
  final sampleAvailability = Availability(
    date: todayStr,
    resourceId: testResourceId,
    slotDurationMinutes: 60,
    availableFrom: '08:00',
    availableUntil: '20:00',
    userStats: const UserStats(
      bookingsToday: 0,
      hoursToday: 0.0,
    ),
    slots: [],
  );

  Widget createTestWidget({String? initialGroupId}) {
    return ProviderScope(
      overrides: [
        myGroupsProvider.overrideWith(
          () => _FakeMyGroupsNotifier([sampleGroup]),
        ),
        groupResourcesProvider(testGroupId).overrideWith(
          (ref) async => [sampleResource],
        ),
        availabilityProvider.overrideWith(
          (ref, params) async => sampleAvailability,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: QuickBookingScreen(initialGroupId: initialGroupId),
      ),
    );
  }

  group('QuickBookingScreen Material 3 Selectors', () {
    testWidgets('renders M3 selector cards with dropdown icons and avatars', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(initialGroupId: testGroupId));
      await tester.pumpAndSettle();

      // Verify no iOS chevron_right icons are used for selection options
      expect(find.byIcon(Icons.chevron_right_outlined), findsNothing);

      // Verify Material 3 dropdown disclosure icons are present
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsWidgets);

      // Verify labels and selected names
      expect(find.text('Group'), findsOneWidget);
      expect(find.text('SAFAA C811'), findsOneWidget);
      expect(find.text('Resource'), findsOneWidget);

      // Verify GroupAvatar is rendered for the selected group
      expect(find.byType(GroupAvatar), findsOneWidget);
    });

    testWidgets('resource selection displays ResourceAvatar when selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(initialGroupId: testGroupId));
      await tester.pumpAndSettle();

      // Bottom sheet automatically opened because autoOpenResourcePicker is enabled when initialGroupId is provided
      expect(find.text('Washing Machine'), findsOneWidget);

      // Select resource
      await tester.tap(find.text('Washing Machine'));
      await tester.pumpAndSettle();

      // Verify ResourceAvatar is rendered in the selector card
      expect(find.byType(ResourceAvatar), findsOneWidget);
      expect(find.text('Washing Machine'), findsOneWidget);
    });
  });
}
