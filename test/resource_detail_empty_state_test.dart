import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:lockmyslot_app/features/bookings/providers/bookings_provider.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/providers/maintenance_provider.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/features/resources/screens/resource_detail_screen.dart';
import 'package:lockmyslot_app/shared/widgets/empty_state.dart';

void main() {
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

  final mockGroup = Group(
    id: testGroupId,
    name: 'Shared Flat',
    inviteCode: 'FLAT12',
    role: 'ADMIN',
    memberCount: 3,
    createdAt: DateTime.now(),
  );

  testWidgets('Empty state "No Upcoming Bookings" is wrapped in SliverFillRemaining and vertically centered',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

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
              .overrideWith((ref) async => mockGroup),
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

    // Verify "No Upcoming Bookings" EmptyState is rendered
    expect(find.text('No Upcoming Bookings'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);

    // Verify it is an ancestor of SliverFillRemaining
    final fillRemainingFinder = find.ancestor(
      of: find.byType(EmptyState),
      matching: find.byType(SliverFillRemaining),
    );
    expect(fillRemainingFinder, findsOneWidget);

    // Verify that EmptyState fills the remaining space and centers its content
    final emptyStateRect = tester.getRect(find.byType(EmptyState));
    final columnFinder = find.descendant(
      of: find.byType(EmptyState),
      matching: find.byType(Column),
    );
    final columnRect = tester.getRect(columnFinder);

    // EmptyState should extend downwards to fill remaining height
    expect(emptyStateRect.height, greaterThan(300.0));

    // Center of the Column should match the vertical center of EmptyState
    expect(
      (columnRect.center.dy - emptyStateRect.center.dy).abs(),
      lessThan(1.0),
    );
  });

  testWidgets('When bookings exist, bookings list is rendered and EmptyState is absent',
      (tester) async {
    final List<Booking> mockBookings = [
      Booking(
        id: 'booking-1',
        resourceId: testResourceId,
        groupId: testGroupId,
        userId: 'user-1',
        userDisplayName: 'Alice',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
      ),
    ];

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
          )).overrideWith((ref) async => mockBookings),
          resourceMaintenanceProvider((
            groupId: testGroupId,
            resourceId: testResourceId,
            status: null,
          )).overrideWith((ref) async => []),
          groupDetailProvider(testGroupId)
              .overrideWith((ref) async => mockGroup),
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

    expect(find.text('No Upcoming Bookings'), findsNothing);
    expect(
      find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      ),
      findsNothing,
    );
    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('Other Bookings'), findsOneWidget);
  });
}
