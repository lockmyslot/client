import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/bookings/data/bookings_repository.dart';
import 'package:lockmyslot_app/features/bookings/data/models/availability.dart';
import 'package:lockmyslot_app/features/bookings/providers/availability_provider.dart';
import 'package:lockmyslot_app/features/bookings/providers/bookings_provider.dart';
import 'package:lockmyslot_app/features/bookings/widgets/booking_details_form.dart';
import 'package:lockmyslot_app/features/resources/data/models/booking_rule.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/providers/booking_rules_provider.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/features/resources/providers/maintenance_provider.dart';
import 'package:lockmyslot_app/features/resources/screens/resource_detail_screen.dart';
import 'package:lockmyslot_app/features/groups/providers/groups_provider.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class FakeBookingsRepository extends BookingsRepository {
  FakeBookingsRepository() : super(ApiClient(storage: FakeSecureStorage()));
}

void main() {
  final sampleResource = Resource(
    id: 'res-1',
    groupId: 'grp-1',
    name: 'Tennis Court',
    description: 'Outdoor clay court',
    capacity: 2,
    slotDurationMinutes: 60,
    isActive: true,
    rulesConfigured: true,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  final sampleGroup = Group(
    id: 'grp-1',
    name: 'Sports Club',
    inviteCode: 'SPORT1',
    role: 'ADMIN',
    memberCount: 5,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  group('Working Hours Impact on Resource Booking Slots Page', () {
    testWidgets('displays operating hours banner and slots restricted by working hours (08:00 - 20:00)', (
      WidgetTester tester,
    ) async {
      final fakeBookingsRepo = FakeBookingsRepository();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // Slots from 08:00 to 20:00 (12 hours)
      final restrictedSlots = List.generate(12, (index) {
        final startH = (8 + index).toString().padLeft(2, '0');
        final endH = (9 + index).toString().padLeft(2, '0');
        return TimeSlot(
          startTime: DateTime.parse('${todayStr}T$startH:00:00Z'),
          endTime: DateTime.parse('${todayStr}T$endH:00:00Z'),
          status: 'available',
          booked: 0,
          capacity: 2,
        );
      });

      final availabilityData = Availability(
        date: todayStr,
        resourceId: 'res-1',
        slotDurationMinutes: 60,
        availableFrom: '08:00',
        availableUntil: '20:00',
        userStats: const UserStats(
          bookingsToday: 0,
          hoursToday: 0.0,
          maxBookingsPerDay: 2,
          maxHoursPerDay: 4,
          cooldownMinutes: 30,
        ),
        slots: restrictedSlots,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(fakeBookingsRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-1',
            )).overrideWith((ref) => sampleResource),
            availabilityProvider.overrideWith(
              (ref, arg) async => availabilityData,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BookingDetailsForm(
                groupId: 'grp-1',
                resourceId: 'res-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Operating hours banner is displayed
      expect(find.text('Operating hours: 8:00 AM – 8:00 PM'), findsOneWidget);

      // Verify the slots in the grid only start at 8:00 AM and end at 7:00 PM (starts)
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(find.text('7:00 PM'), findsOneWidget);

      // There should NOT be 6:00 AM or 11:00 PM slots
      expect(find.text('6:00 AM'), findsNothing);
      expect(find.text('11:00 PM'), findsNothing);
    });

    testWidgets('displays Open 24 hours banner when no working hours restriction (00:00 - 24:00)', (
      WidgetTester tester,
    ) async {
      final fakeBookingsRepo = FakeBookingsRepository();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final fullDaySlots = List.generate(24, (index) {
        final startH = index.toString().padLeft(2, '0');
        final endH = (index + 1).toString().padLeft(2, '0');
        return TimeSlot(
          startTime: DateTime.parse('${todayStr}T$startH:00:00Z'),
          endTime: DateTime.parse(index == 23 ? '${todayStr}T23:59:00Z' : '${todayStr}T$endH:00:00Z'),
          status: 'available',
          booked: 0,
          capacity: 2,
        );
      });

      final availabilityData = Availability(
        date: todayStr,
        resourceId: 'res-1',
        slotDurationMinutes: 60,
        availableFrom: '00:00',
        availableUntil: '24:00',
        userStats: const UserStats(
          bookingsToday: 0,
          hoursToday: 0.0,
          maxBookingsPerDay: 2,
          maxHoursPerDay: 4,
          cooldownMinutes: 30,
        ),
        slots: fullDaySlots,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(fakeBookingsRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-1',
            )).overrideWith((ref) => sampleResource),
            availabilityProvider.overrideWith(
              (ref, arg) async => availabilityData,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BookingDetailsForm(
                groupId: 'grp-1',
                resourceId: 'res-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open 24 hours banner is displayed
      expect(find.text('Operating hours: Open 24 hours (All day)'), findsOneWidget);
    });

    testWidgets('shows informative message when all slots within operating hours are empty or closed', (
      WidgetTester tester,
    ) async {
      final fakeBookingsRepo = FakeBookingsRepository();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final availabilityData = Availability(
        date: todayStr,
        resourceId: 'res-1',
        slotDurationMinutes: 60,
        availableFrom: '09:00',
        availableUntil: '17:00',
        userStats: const UserStats(
          bookingsToday: 0,
          hoursToday: 0.0,
          maxBookingsPerDay: 2,
          maxHoursPerDay: 4,
          cooldownMinutes: 30,
        ),
        slots: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(fakeBookingsRepo),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-1',
            )).overrideWith((ref) => sampleResource),
            availabilityProvider.overrideWith(
              (ref, arg) async => availabilityData,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BookingDetailsForm(
                groupId: 'grp-1',
                resourceId: 'res-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No bookable slots available for this date.'), findsOneWidget);
      expect(
        find.textContaining('Slots are only generated within operating hours (9:00 AM – 5:00 PM)'),
        findsOneWidget,
      );
    });

    testWidgets('ResourceDetailScreen renders Hours KPI chip when resource has configured working hours', (
      WidgetTester tester,
    ) async {
      final fakeBookingsRepo = FakeBookingsRepository();
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(fakeBookingsRepo),
            groupDetailProvider('grp-1').overrideWith((ref) => sampleGroup),
            resourceDetailProvider((
              groupId: 'grp-1',
              resourceId: 'res-1',
            )).overrideWith((ref) => sampleResource),
            bookingRulesProvider.overrideWith(
              (ref, arg) async => [
                const BookingRule(
                  dayScope: 'WEEKDAY',
                  availableFrom: '08:00',
                  availableUntil: '22:00',
                ),
              ],
            ),
            resourceBookingsProvider((
              groupId: 'grp-1',
              resourceId: 'res-1',
              date: null,
            )).overrideWith((ref) => []),
            resourceMaintenanceProvider((
              groupId: 'grp-1',
              resourceId: 'res-1',
              status: null,
            )).overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: ResourceDetailScreen(
              groupId: 'grp-1',
              resourceId: 'res-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('8:00 AM - 10:00 PM'), findsOneWidget);
    });
  });
}
