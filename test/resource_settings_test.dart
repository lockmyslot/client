import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/resources/data/models/booking_rule.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/data/resources_repository.dart';
import 'package:lockmyslot_app/features/resources/providers/booking_rules_provider.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/features/resources/screens/resource_settings_screen.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeResourcesRepository extends ResourcesRepository {
  FakeResourcesRepository() : super(ApiClient(storage: FakeSecureStorage()));

  Map<String, dynamic>? lastConfigUpdate;
  List<BookingRule>? lastSavedRules;

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
    lastConfigUpdate = {
      'groupId': groupId,
      'resourceId': resourceId,
      'name': name,
      'description': description,
      'capacity': capacity,
      'slotDurationMinutes': slotDurationMinutes,
      'isActive': isActive,
    };

    return Resource(
      id: resourceId,
      groupId: groupId,
      name: name ?? 'Updated',
      description: description,
      capacity: capacity ?? 1,
      slotDurationMinutes: slotDurationMinutes ?? 60,
      isActive: isActive ?? true,
      rulesConfigured: true,
      createdAt: DateTime.parse('2026-10-24T10:00:00Z'),
      updatedAt: DateTime.parse('2026-10-24T12:00:00Z'),
    );
  }

  @override
  Future<List<BookingRule>> updateBookingRules(
    String groupId,
    String resourceId,
    List<BookingRule> rules,
  ) async {
    lastSavedRules = rules;
    return rules;
  }
}

void main() {
  final sampleResource = Resource(
    id: 'res-101',
    groupId: 'grp-1',
    name: 'Conference Room Alpha',
    description: 'Level 2 west wing room',
    capacity: 10,
    slotDurationMinutes: 30,
    isActive: true,
    rulesConfigured: true,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  final sampleRules = [
    BookingRule(
      id: 'rule-1',
      dayScope: 'WEEKDAY',
      maxBookingsPerDay: 2,
      maxHoursPerDay: 4,
      cooldownMinutes: 30,
      maxAdvanceBookingDays: 7,
    ),
  ];

  group('ResourceSettingsScreen Widget Tests', () {
    testWidgets('renders Settings with Configurations and Booking Rules tabs', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleResource),
            bookingRulesProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleRules),
          ],
          child: const MaterialApp(
            home: ResourceSettingsScreen(
              groupId: 'grp-1',
              resourceId: 'res-101',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Resource Settings'), findsOneWidget);
      expect(find.text('Configurations'), findsOneWidget);
      expect(find.text('Booking Rules'), findsOneWidget);

      // Configurations tab is selected by default
      expect(find.text('Resource Properties'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Conference Room Alpha'),
        findsOneWidget,
      );
      expect(find.text('Level 2 west wing room'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Active for Bookings'), findsOneWidget);

      // Booking Rules link card is present in Configurations tab
      expect(find.text('Booking Rules & Policies'), findsOneWidget);
    });

    testWidgets('switches to Booking Rules tab and shows day scopes and rules', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleResource),
            bookingRulesProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleRules),
          ],
          child: const MaterialApp(
            home: ResourceSettingsScreen(
              groupId: 'grp-1',
              resourceId: 'res-101',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Booking Rules tab
      await tester.tap(find.text('Booking Rules'));
      await tester.pumpAndSettle();

      expect(find.text('Save Rules'), findsOneWidget);
      expect(find.text('WEEKDAY'), findsOneWidget);
      expect(find.text('WEEKEND'), findsOneWidget);
      expect(find.text('Enable rules for WEEKDAY'), findsOneWidget);
      expect(find.text('Usage Limits'), findsOneWidget);
    });

    testWidgets('tapping Booking Rules & Policies card in config tab navigates to rules tab', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleResource),
            bookingRulesProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleRules),
          ],
          child: const MaterialApp(
            home: ResourceSettingsScreen(
              groupId: 'grp-1',
              resourceId: 'res-101',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to the card and tap it
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      final cardFinder = find.text('Booking Rules & Policies');
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      // Should now be on Booking Rules tab
      expect(find.text('Save Rules'), findsOneWidget);
      expect(find.text('Enable rules for WEEKDAY'), findsOneWidget);
    });

    testWidgets('updates configuration properties and submits successfully', (
      WidgetTester tester,
    ) async {
      final fakeRepo = FakeResourcesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesRepositoryProvider.overrideWithValue(fakeRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleResource),
            bookingRulesProvider((
              groupId: 'grp-1',
              resourceId: 'res-101',
            )).overrideWith((ref) => sampleRules),
          ],
          child: const MaterialApp(
            home: ResourceSettingsScreen(
              groupId: 'grp-1',
              resourceId: 'res-101',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Edit name
      final nameField = find.widgetWithText(TextFormField, 'Conference Room Alpha');
      await tester.enterText(nameField, 'Meeting Room Gamma');

      // Edit capacity
      final capField = find.widgetWithText(TextFormField, '10');
      await tester.enterText(capField, '15');

      // Edit slot duration
      final durationField = find.widgetWithText(TextFormField, '30');
      await tester.enterText(durationField, '60');

      // Tap Save Configurations
      await tester.tap(find.text('Save Configurations'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeRepo.lastConfigUpdate, isNotNull);
      expect(fakeRepo.lastConfigUpdate!['name'], 'Meeting Room Gamma');
      expect(fakeRepo.lastConfigUpdate!['capacity'], 15);
      expect(fakeRepo.lastConfigUpdate!['slotDurationMinutes'], 60);
      expect(fakeRepo.lastConfigUpdate!['isActive'], true);
    });
  });
}
