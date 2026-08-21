import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/booking.dart';
import 'models/availability.dart';

class BookingsRepository {
  final ApiClient _apiClient;

  BookingsRepository(this._apiClient);

  Future<Availability> getAvailability(
    String groupId,
    String resourceId,
    String date,
  ) async {
    final response = await _apiClient.get<Availability>(
      ApiConstants.availability(groupId, resourceId),
      query: {'date': date},
      fromJson: (json) => Availability.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<List<Booking>> getBookings(
    String groupId,
    String resourceId, {
    String? date,
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{};
    if (date != null) query['date'] = date;
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;

    final response = await _apiClient.get<List<Booking>>(
      ApiConstants.bookings(groupId, resourceId),
      query: query.isNotEmpty ? query : null,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
    return response.data;
  }

  Future<Booking> createBooking(
    String groupId,
    String resourceId, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _apiClient.post<Booking>(
      ApiConstants.bookings(groupId, resourceId),
      body: {
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
      },
      fromJson: (json) => Booking.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<void> cancelBooking(String groupId, String bookingId) async {
    await _apiClient.delete(ApiConstants.cancelBooking(groupId, bookingId));
  }

  Future<List<Booking>> getMyBookings(
    String groupId, {
    String? status,
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;

    final response = await _apiClient.get<List<Booking>>(
      ApiConstants.myBookings(groupId),
      query: query.isNotEmpty ? query : null,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
    return response.data;
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(ref.watch(apiClientProvider));
});
