import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/core/theme/app_theme.dart';
import 'package:lockmyslot_app/core/utils/date_utils.dart';
import 'package:lockmyslot_app/features/bookings/data/bookings_repository.dart';
import 'package:lockmyslot_app/features/bookings/data/models/availability.dart';
import 'package:lockmyslot_app/features/bookings/providers/availability_provider.dart';
import 'package:lockmyslot_app/features/bookings/screens/availability_screen.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';
import 'package:lockmyslot_app/shared/widgets/m3_collapsing_app_bar.dart';

class _FakeSecureStorage extends Fake implements SecureStorageService {}

class _FakeBookingsRepository extends BookingsRepository {
  _FakeBookingsRepository() : super(ApiClient(storage: _FakeSecureStorage()));
}

void main() {
  const groupId = 'grp-123';
  const resourceId = 'res-456';

  final sampleResource = Resource(
    id: resourceId,
    groupId: groupId,
    name: 'Tennis Court',
    icon: 'sports_tennis',
    capacity: 2,
    slotDurationMinutes: 60,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final todayStr = DateTime.now().toIso8601String().split('T')[0];
  final availabilityData = Availability(
    date: todayStr,
    resourceId: resourceId,
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
    slots: [
      TimeSlot(
        startTime: DateTime.parse('${todayStr}T08:00:00Z'),
        endTime: DateTime.parse('${todayStr}T09:00:00Z'),
        status: 'available',
        booked: 0,
        capacity: 2,
      ),
    ],
  );

  testWidgets('AvailabilityScreen renders M3CollapsingAppBar with resource title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingsRepositoryProvider.overrideWithValue(_FakeBookingsRepository()),
          resourceDetailProvider((groupId: groupId, resourceId: resourceId)).overrideWith(
            (ref) => sampleResource,
          ),
          availabilityProvider.overrideWith((ref, arg) async => availabilityData),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const AvailabilityScreen(
            groupId: groupId,
            resourceId: resourceId,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(M3CollapsingAppBar), findsOneWidget);
    expect(find.text('Book Tennis Court'), findsWidgets);
  });

  testWidgets(
    'AvailabilityScreen date pills horizontal scroll view does not clip chips with Clip.none',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(
              _FakeBookingsRepository(),
            ),
            resourceDetailProvider((
              groupId: groupId,
              resourceId: resourceId,
            )).overrideWith((ref) => sampleResource),
            availabilityProvider.overrideWith(
              (ref, arg) async => availabilityData,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const AvailabilityScreen(
              groupId: groupId,
              resourceId: resourceId,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      final todayFinder = find.text('Today');
      final dateScrollView = tester.widget<SingleChildScrollView>(
        find.ancestor(
          of: todayFinder,
          matching: find.byType(SingleChildScrollView),
        ).first,
      );
      expect(dateScrollView.clipBehavior, equals(Clip.none));
      expect(dateScrollView.scrollDirection, equals(Axis.horizontal));
    },
  );

  testWidgets(
    'AvailabilityScreen changing date keeps date strip mounted and updates availability without resetting page',
    (WidgetTester tester) async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = tomorrow.toIso8601String().split('T')[0];

      final tomorrowAvailability = Availability(
        date: tomorrowStr,
        resourceId: resourceId,
        slotDurationMinutes: 60,
        availableFrom: '08:00',
        availableUntil: '20:00',
        userStats: const UserStats(
          bookingsToday: 1,
          hoursToday: 1.0,
          maxBookingsPerDay: 2,
          maxHoursPerDay: 4,
          cooldownMinutes: 30,
        ),
        slots: [
          TimeSlot(
            startTime: DateTime.parse('${tomorrowStr}T10:00:00Z'),
            endTime: DateTime.parse('${tomorrowStr}T11:00:00Z'),
            status: 'available',
            booked: 0,
            capacity: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(
              _FakeBookingsRepository(),
            ),
            resourceDetailProvider((
              groupId: groupId,
              resourceId: resourceId,
            )).overrideWith((ref) => sampleResource),
            availabilityProvider.overrideWith((ref, arg) async {
              if (arg.date == tomorrowStr) {
                return tomorrowAvailability;
              }
              return availabilityData;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const AvailabilityScreen(
              groupId: groupId,
              resourceId: resourceId,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial date data is rendered
      expect(find.text('Change Date'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      final initialSlotTime = AppDateUtils.formatTime(availabilityData.slots.first.startTime);
      expect(find.text(initialSlotTime), findsOneWidget);

      // Find the tomorrow date chip by text and tap it
      await tester.tap(find.text(AppDateUtils.formatShortDate(tomorrow)));
      await tester.pumpAndSettle();

      // The date strip and Change Date button remain mounted throughout
      expect(find.text('Change Date'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Tomorrow's slot should now be displayed
      final tomorrowSlotTime = AppDateUtils.formatTime(tomorrowAvailability.slots.first.startTime);
      expect(find.text(tomorrowSlotTime), findsOneWidget);
    },
  );
}
