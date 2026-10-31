import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/core/theme/app_theme.dart';
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
}
