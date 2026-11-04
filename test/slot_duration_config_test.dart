import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/data/models/slot_duration_unit.dart';
import 'package:lockmyslot_app/features/resources/data/resources_repository.dart';
import 'package:lockmyslot_app/features/resources/screens/create_resource_sheet.dart';
import 'package:lockmyslot_app/features/resources/screens/edit_resource_sheet.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeResourcesRepository extends ResourcesRepository {
  FakeResourcesRepository() : super(ApiClient(storage: FakeSecureStorage()));

  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;

  @override
  Future<Resource> createResource(
    String groupId, {
    required String name,
    String? description,
    String? icon,
    String? color,
    required int capacity,
    required int slotDurationMinutes,
  }) async {
    lastCreateArgs = {
      'groupId': groupId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'capacity': capacity,
      'slotDurationMinutes': slotDurationMinutes,
    };

    return Resource(
      id: 'res-new-1',
      groupId: groupId,
      name: name,
      description: description,
      icon: icon,
      capacity: capacity,
      slotDurationMinutes: slotDurationMinutes,
      isActive: true,
      rulesConfigured: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Resource> updateResource(
    String groupId,
    String resourceId, {
    String? name,
    String? description,
    String? icon,
    String? color,
    int? capacity,
    int? slotDurationMinutes,
    bool? isActive,
    Map<String, dynamic>? data,
  }) async {
    lastUpdateArgs = {
      'groupId': groupId,
      'resourceId': resourceId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'capacity': capacity,
      'slotDurationMinutes': slotDurationMinutes,
      'isActive': isActive,
    };

    return Resource(
      id: resourceId,
      groupId: groupId,
      name: name ?? 'Updated Resource',
      description: description,
      icon: icon,
      capacity: capacity ?? 1,
      slotDurationMinutes: slotDurationMinutes ?? 60,
      isActive: isActive ?? true,
      rulesConfigured: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('Admin Slot Configuration (Hours & Days) Tests', () {
    testWidgets('allows admin to configure slots in Hours when creating resource', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateResourceSheet(
                  groupId: 'grp-1',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name "Meeting Room B"
      final nameField = find.widgetWithText(TextFormField, 'Resource Name *');
      await tester.enterText(nameField, 'Meeting Room B');
      await tester.pumpAndSettle();

      // Select Hours in Unit dropdown
      final unitDropdown = find.widgetWithText(
        DropdownButtonFormField<SlotDurationUnit>,
        'Minutes',
      );
      expect(unitDropdown, findsOneWidget);
      await tester.tap(unitDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hours').last);
      await tester.pumpAndSettle();

      // Enter 2 hours
      final durationField = find.widgetWithText(TextFormField, 'Slot Duration');
      await tester.enterText(durationField, '2');
      await tester.pumpAndSettle();

      // Submit
      final createButton = find.text('Create Resource');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreateArgs, isNotNull);
      expect(fakeRepo.lastCreateArgs!['name'], 'Meeting Room B');
      // 2 hours = 120 minutes
      expect(fakeRepo.lastCreateArgs!['slotDurationMinutes'], 120);
    });

    testWidgets('allows admin to configure slots in Days when creating resource', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateResourceSheet(
                  groupId: 'grp-1',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name "Guest Suite"
      final nameField = find.widgetWithText(TextFormField, 'Resource Name *');
      await tester.enterText(nameField, 'Guest Suite');
      await tester.pumpAndSettle();

      // Select Days in Unit dropdown
      final unitDropdown = find.widgetWithText(
        DropdownButtonFormField<SlotDurationUnit>,
        'Minutes',
      );
      await tester.tap(unitDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Days').last);
      await tester.pumpAndSettle();

      // Enter 3 days
      final durationField = find.widgetWithText(TextFormField, 'Slot Duration');
      await tester.enterText(durationField, '3');
      await tester.pumpAndSettle();

      // Submit
      final createButton = find.text('Create Resource');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreateArgs, isNotNull);
      expect(fakeRepo.lastCreateArgs!['name'], 'Guest Suite');
      // 3 days = 4320 minutes
      expect(fakeRepo.lastCreateArgs!['slotDurationMinutes'], 4320);
    });

    testWidgets('allows admin to edit slot duration from minutes to days', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();
      final sampleResource = Resource(
        id: 'res-room',
        groupId: 'grp-1',
        name: 'Conference Room Alpha',
        capacity: 10,
        slotDurationMinutes: 60,
        isActive: true,
        rulesConfigured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditResourceSheet(
                  groupId: 'grp-1',
                  resource: sampleResource,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Unit dropdown and select Days
      final unitDropdown = find.widgetWithText(
        DropdownButtonFormField<SlotDurationUnit>,
        'Minutes',
      );
      await tester.tap(unitDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Days').last);
      await tester.pumpAndSettle();

      // Enter 1 day
      final durationField = find.widgetWithText(TextFormField, 'Slot Duration');
      await tester.enterText(durationField, '1');
      await tester.pumpAndSettle();

      // Save Changes
      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdateArgs, isNotNull);
      // 1 day = 1440 minutes
      expect(fakeRepo.lastUpdateArgs!['slotDurationMinutes'], 1440);
    });
  });
}
