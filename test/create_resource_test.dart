import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/data/resources_repository.dart';
import 'package:lockmyslot_app/features/resources/screens/create_resource_sheet.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeResourcesRepository extends ResourcesRepository {
  FakeResourcesRepository() : super(ApiClient(storage: FakeSecureStorage()));

  Map<String, dynamic>? lastCreateArgs;

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
}

void main() {
  group('CreateResourceSheet Widget Tests', () {
    testWidgets('allows leaving icon alone (using initials)', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();
      Resource? created;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateResourceSheet(
                  groupId: 'grp-1',
                  onSuccess: (res) => created = res,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name "Room 101"
      final nameField = find.widgetWithText(TextFormField, 'Resource Name *');
      await tester.enterText(nameField, 'Room 101');
      await tester.pumpAndSettle();

      // Initials "R1" should appear
      expect(find.text('R1'), findsWidgets);

      // Submit
      final createButton = find.text('Create Resource');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreateArgs, isNotNull);
      expect(fakeRepo.lastCreateArgs!['name'], 'Room 101');
      expect(fakeRepo.lastCreateArgs!['icon'], isNull);
      expect(created, isNotNull);
      expect(created!.icon, isNull);
    });

    testWidgets('allows selecting an icon (e.g. Washing Machine or Computer)', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();
      Resource? created;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CreateResourceSheet(
                  groupId: 'grp-1',
                  onSuccess: (res) => created = res,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name
      final nameField = find.widgetWithText(TextFormField, 'Resource Name *');
      await tester.enterText(nameField, 'Laundry Room Washer');
      await tester.pumpAndSettle();

      // Tap "Washing Machine" icon chip
      final washingMachineChip = find.text('Washing Machine');
      await tester.ensureVisible(washingMachineChip);
      await tester.tap(washingMachineChip);
      await tester.pumpAndSettle();

      // Submit
      final createButton = find.text('Create Resource');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCreateArgs, isNotNull);
      expect(fakeRepo.lastCreateArgs!['icon'], 'washing_machine');
      expect(created, isNotNull);
      expect(created!.icon, 'washing_machine');
    });
  });
}
