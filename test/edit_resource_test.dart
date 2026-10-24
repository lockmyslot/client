import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/data/resources_repository.dart';
import 'package:lockmyslot_app/features/resources/screens/edit_resource_sheet.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeResourcesRepository extends ResourcesRepository {
  FakeResourcesRepository() : super(ApiClient(storage: FakeSecureStorage()));

  Map<String, dynamic>? lastUpdateArgs;
  Resource? updatedResult;

  @override
  Future<Resource> updateResource(
    String groupId,
    String resourceId, {
    String? name,
    String? description,
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
      'capacity': capacity,
      'slotDurationMinutes': slotDurationMinutes,
      'isActive': isActive,
    };

    final result = Resource(
      id: resourceId,
      groupId: groupId,
      name: name ?? 'Updated Resource',
      description: description,
      capacity: capacity ?? 1,
      slotDurationMinutes: slotDurationMinutes ?? 60,
      isActive: isActive ?? true,
      rulesConfigured: true,
      createdAt: DateTime.parse('2026-10-24T10:00:00Z'),
      updatedAt: DateTime.parse('2026-10-24T12:00:00Z'),
    );
    updatedResult = result;
    return result;
  }
}

void main() {
  final sampleResource = Resource(
    id: 'res-101',
    groupId: 'grp-1',
    name: 'Conference Room Alpha',
    description: 'Level 2 west wing conference room',
    capacity: 12,
    slotDurationMinutes: 45,
    isActive: true,
    rulesConfigured: true,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  group('EditResourceSheet Widget Tests', () {
    testWidgets('pre-fills all existing resource configuration properties', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EditResourceSheet(
                groupId: 'grp-1',
                resource: sampleResource,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Resource'), findsOneWidget);
      expect(
        find.text('Update configuration for Conference Room Alpha'),
        findsOneWidget,
      );
      expect(find.text('Conference Room Alpha'), findsOneWidget);
      expect(find.text('Level 2 west wing conference room'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Active for Bookings'), findsOneWidget);

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, true);
    });

    testWidgets('shows validation errors for invalid slot duration and capacity', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

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

      // Clear the name field
      final nameField = find.widgetWithText(TextFormField, 'Conference Room Alpha');
      await tester.enterText(nameField, '');

      // Enter invalid slot duration (not multiple of 15)
      final durationField = find.widgetWithText(TextFormField, '45');
      await tester.enterText(durationField, '25');

      // Enter invalid capacity (0)
      final capacityField = find.widgetWithText(TextFormField, '12');
      await tester.enterText(capacityField, '0');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Resource name is required'), findsOneWidget);
      expect(find.text('Must be > 0'), findsOneWidget);
      expect(find.text('Multiple of 15'), findsOneWidget);
      expect(fakeRepo.lastUpdateArgs, isNull);
    });

    testWidgets('updates all configuration properties and submits successfully', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();
      Resource? savedResource;

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
                  onSuccess: (res) {
                    savedResource = res;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Update name
      final nameField = find.widgetWithText(TextFormField, 'Conference Room Alpha');
      await tester.enterText(nameField, 'Meeting Room Beta');

      // Update description
      final descField = find.widgetWithText(
        TextFormField,
        'Level 2 west wing conference room',
      );
      await tester.enterText(descField, 'Level 3 east wing room with 4K screen');

      // Update capacity
      final capacityField = find.widgetWithText(TextFormField, '12');
      await tester.enterText(capacityField, '20');

      // Update slot duration
      final durationField = find.widgetWithText(TextFormField, '45');
      await tester.enterText(durationField, '60');

      // Toggle active status to false
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.lastUpdateArgs, isNotNull);
      expect(fakeRepo.lastUpdateArgs!['groupId'], 'grp-1');
      expect(fakeRepo.lastUpdateArgs!['resourceId'], 'res-101');
      expect(fakeRepo.lastUpdateArgs!['name'], 'Meeting Room Beta');
      expect(
        fakeRepo.lastUpdateArgs!['description'],
        'Level 3 east wing room with 4K screen',
      );
      expect(fakeRepo.lastUpdateArgs!['capacity'], 20);
      expect(fakeRepo.lastUpdateArgs!['slotDurationMinutes'], 60);
      expect(fakeRepo.lastUpdateArgs!['isActive'], false);

      expect(savedResource, isNotNull);
      expect(savedResource!.name, 'Meeting Room Beta');
      expect(savedResource!.capacity, 20);
      expect(savedResource!.slotDurationMinutes, 60);
      expect(savedResource!.isActive, false);
    });
  });
}
