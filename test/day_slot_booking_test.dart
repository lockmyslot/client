import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/storage/secure_storage.dart';
import 'package:lockmyslot_app/features/bookings/data/bookings_repository.dart';
import 'package:lockmyslot_app/features/bookings/data/models/availability.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:lockmyslot_app/features/bookings/providers/availability_provider.dart';
import 'package:lockmyslot_app/features/bookings/widgets/booking_details_form.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/resources/providers/resources_provider.dart';

class FakeSecureStorage extends Fake implements SecureStorageService {}

class RecordingBookingsRepository extends BookingsRepository {
  RecordingBookingsRepository()
      : super(ApiClient(storage: FakeSecureStorage()));

  DateTime? lastStartTime;
  DateTime? lastEndTime;

  @override
  Future<Booking> createBooking(
    String groupId,
    String resourceId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    lastStartTime = startTime;
    lastEndTime = endTime;
    return Booking(
      id: 'b-1',
      resourceId: resourceId,
      userId: 'user-1',
      groupId: groupId,
      startTime: startTime,
      endTime: endTime,
      status: 'CONFIRMED',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  final dayResource = Resource(
    id: 'res-day',
    groupId: 'grp-1',
    name: 'Beach House',
    description: 'Day rental',
    capacity: 1,
    slotDurationMinutes: 1440,
    isActive: true,
    rulesConfigured: false,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  testWidgets('renders day slot for today and confirms booking with correct dates', (
    WidgetTester tester,
  ) async {
    final fakeRepo = RecordingBookingsRepository();
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final slotStart = DateTime.parse('${todayStr}T00:00:00.000Z');
    final slotEnd = slotStart.add(const Duration(minutes: 1440));

    final availabilityData = Availability(
      date: todayStr,
      resourceId: 'res-day',
      slotDurationMinutes: 1440,
      userStats: const UserStats(bookingsToday: 0, hoursToday: 0),
      slots: [
        TimeSlot(
          startTime: slotStart,
          endTime: slotEnd,
          status: 'available',
          booked: 0,
          capacity: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingsRepositoryProvider.overrideWithValue(fakeRepo),
          resourceDetailProvider((
            groupId: 'grp-1',
            resourceId: 'res-day',
          )).overrideWith((ref) => dayResource),
          availabilityProvider.overrideWith(
            (ref, arg) async => availabilityData,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BookingDetailsForm(
              groupId: 'grp-1',
              resourceId: 'res-day',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify day slot duration selector is present
    expect(find.text('Select Duration'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);

    // Verify confirm booking button is visible and tap it
    final bookButton = find.text('Confirm Booking');
    expect(bookButton, findsOneWidget);

    await tester.tap(bookButton);
    await tester.pumpAndSettle();

    // Verify booking was submitted with slot times
    expect(fakeRepo.lastStartTime, equals(slotStart));
    expect(fakeRepo.lastEndTime, equals(slotEnd));
  });
}
