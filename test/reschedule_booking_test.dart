import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/api/api_response.dart';
import 'package:lockmyslot_app/core/constants/api_constants.dart';
import 'package:lockmyslot_app/features/bookings/data/bookings_repository.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:lockmyslot_app/features/bookings/screens/reschedule_booking_sheet.dart';
import 'package:lockmyslot_app/features/bookings/providers/availability_provider.dart';
import 'package:lockmyslot_app/features/bookings/data/models/availability.dart';

class MockApiClient extends Fake implements ApiClient {
  String? lastPatchPath;
  dynamic lastPatchBody;
  dynamic patchReturnValue;

  @override
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    lastPatchPath = path;
    lastPatchBody = body;
    final data = fromJson != null ? fromJson(patchReturnValue) : patchReturnValue as T;
    return ApiResponse<T>(
      data: data,
      meta: {},
    );
  }
}

void main() {
  group('Reschedule Booking Tests', () {
    test('ApiConstants.rescheduleBooking formats correctly', () {
      expect(
        ApiConstants.rescheduleBooking('group-123', 'booking-456'),
        '/groups/group-123/bookings/booking-456',
      );
    });

    test('BookingsRepository.rescheduleBooking calls API and parses response', () async {
      final mockClient = MockApiClient();
      final repo = BookingsRepository(mockClient);

      final now = DateTime.now().toUtc();
      final newStart = now.add(const Duration(days: 1));
      final newEnd = newStart.add(const Duration(hours: 1));

      mockClient.patchReturnValue = {
        'id': 'booking-456',
        'resource_id': 'res-1',
        'resource_name': 'Conference Room',
        'group_id': 'group-123',
        'user_id': 'user-1',
        'start_time': newStart.toIso8601String(),
        'end_time': newEnd.toIso8601String(),
        'status': 'CONFIRMED',
        'created_at': now.toIso8601String(),
      };

      final result = await repo.rescheduleBooking(
        'group-123',
        'booking-456',
        startTime: newStart,
        endTime: newEnd,
      );

      expect(mockClient.lastPatchPath, '/groups/group-123/bookings/booking-456');
      expect(mockClient.lastPatchBody, {
        'start_time': newStart.toIso8601String(),
        'end_time': newEnd.toIso8601String(),
      });
      expect(result.id, 'booking-456');
      expect(result.resourceName, 'Conference Room');
      expect(result.isConfirmed, true);
    });

    testWidgets('RescheduleBookingSheet renders header and booking details', (tester) async {
      final now = DateTime.now().toUtc().add(const Duration(days: 1));
      final booking = Booking(
        id: 'booking-test-1',
        resourceId: 'res-test-1',
        resourceName: 'Tennis Court',
        userId: 'usr-1',
        groupId: 'grp-1',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        status: 'CONFIRMED',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final fakeAvailability = Availability(
        date: now.toIso8601String().split('T')[0],
        resourceId: 'res-test-1',
        slotDurationMinutes: 60,
        availableFrom: '08:00',
        availableUntil: '20:00',
        userStats: const UserStats(
          bookingsToday: 1,
          hoursToday: 1.0,
        ),
        slots: [
          TimeSlot(
            startTime: DateTime.parse('${now.toIso8601String().split('T')[0]}T10:00:00Z'),
            endTime: DateTime.parse('${now.toIso8601String().split('T')[0]}T11:00:00Z'),
            status: 'available',
            booked: 0,
            capacity: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availabilityProvider.overrideWith(
              (ref, arg) async => fakeAvailability,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RescheduleBookingSheet(booking: booking),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reschedule Booking'), findsWidgets);
      expect(find.text('Tennis Court'), findsWidgets);
      expect(find.textContaining('Rescheduling Tennis Court'), findsOneWidget);
    });
  });
}
