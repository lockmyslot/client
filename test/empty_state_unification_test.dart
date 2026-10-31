import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/bookings/providers/bookings_provider.dart';
import 'package:lockmyslot_app/features/bookings/providers/my_bookings_provider.dart';
import 'package:lockmyslot_app/features/bookings/screens/my_bookings_screen.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/screens/groups_list_screen.dart';
import 'package:lockmyslot_app/features/groups/screens/group_detail_screen.dart';
import 'package:lockmyslot_app/features/groups/screens/members_screen.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/features/resources/providers/maintenance_provider.dart';
import 'package:lockmyslot_app/features/resources/screens/resources_list_screen.dart';
import 'package:lockmyslot_app/features/resources/screens/maintenance_tasks_screen.dart';
import 'package:lockmyslot_app/features/resources/screens/resource_detail_screen.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/shared/widgets/empty_state.dart';

class _FakeMyGroupsNotifier extends MyGroupsNotifier {
  @override
  Future<List<Group>> build() async => [];
}

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

  group('Unified Empty State Screen Heights and Scroll Extents', () {
    testWidgets('GroupsListScreen empty state has 0.0 maxScrollExtent and does not shrink header', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myGroupsProvider.overrideWith(() => _FakeMyGroupsNotifier()),
          ],
          child: const MaterialApp(
            home: GroupsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      final fillRemainingFinder = find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      );
      expect(fillRemainingFinder, findsOneWidget);
      final sliver = tester.widget<SliverFillRemaining>(fillRemainingFinder);
      expect(sliver.hasScrollBody, isFalse);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('ResourcesListScreen empty state has 0.0 maxScrollExtent and does not scroll', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupResourcesProvider(testGroupId).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: ResourcesListScreen(groupId: testGroupId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      final fillRemainingFinder = find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      );
      expect(fillRemainingFinder, findsOneWidget);
      final sliver = tester.widget<SliverFillRemaining>(fillRemainingFinder);
      expect(sliver.hasScrollBody, isFalse);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('GroupDetailScreen empty state has 0.0 maxScrollExtent and does not scroll too much', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupDetailProvider(testGroupId).overrideWith((ref) async => mockGroup),
            groupResourcesProvider(testGroupId).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: GroupDetailScreen(groupId: testGroupId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      final fillRemainingFinder = find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      );
      expect(fillRemainingFinder, findsOneWidget);
      final sliver = tester.widget<SliverFillRemaining>(fillRemainingFinder);
      expect(sliver.hasScrollBody, isFalse);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('MaintenanceTasksScreen empty state has 0.0 maxScrollExtent and does not clip pills under header', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourceMaintenanceProvider((groupId: testGroupId, resourceId: testResourceId, status: null))
                .overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: MaintenanceTasksScreen(groupId: testGroupId, resourceId: testResourceId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      final fillRemainingFinder = find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      );
      expect(fillRemainingFinder, findsOneWidget);
      final sliver = tester.widget<SliverFillRemaining>(fillRemainingFinder);
      expect(sliver.hasScrollBody, isFalse);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('ResourceDetailScreen empty state has 0.0 maxScrollExtent', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourceDetailProvider((groupId: testGroupId, resourceId: testResourceId))
                .overrideWith((ref) async => mockResource),
            resourceBookingsProvider((groupId: testGroupId, resourceId: testResourceId, date: null))
                .overrideWith((ref) async => []),
            resourceMaintenanceProvider((groupId: testGroupId, resourceId: testResourceId, status: null))
                .overrideWith((ref) async => []),
            groupDetailProvider(testGroupId).overrideWith((ref) async => mockGroup),
          ],
          child: const MaterialApp(
            home: ResourceDetailScreen(groupId: testGroupId, resourceId: testResourceId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      final fillRemainingFinder = find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      );
      expect(fillRemainingFinder, findsOneWidget);
      final sliver = tester.widget<SliverFillRemaining>(fillRemainingFinder);
      expect(sliver.hasScrollBody, isFalse);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('MyBookingsScreen empty state has 0.0 maxScrollExtent and chips do not overflow on narrow screens', (tester) async {
      // Narrow screen: 360 width
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myBookingsProvider((groupId: testGroupId, status: null)).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: MyBookingsScreen(groupId: testGroupId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EmptyState), findsOneWidget);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('MembersScreen empty state has 0.0 maxScrollExtent', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupDetailProvider(testGroupId).overrideWith((ref) async => mockGroup),
            groupMembersProvider(testGroupId).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: MembersScreen(groupId: testGroupId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      final fillRemainingFinder = find.ancestor(
        of: find.byType(EmptyState),
        matching: find.byType(SliverFillRemaining),
      );
      expect(fillRemainingFinder, findsOneWidget);
      final sliver = tester.widget<SliverFillRemaining>(fillRemainingFinder);
      expect(sliver.hasScrollBody, isFalse);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });
  });
}
