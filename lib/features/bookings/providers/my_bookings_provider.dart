import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking.dart';
import '../data/bookings_repository.dart';

final myBookingsProvider =
    FutureProvider.family<List<Booking>, ({String groupId, String? status})>((
      ref,
      arg,
    ) async {
      final repo = ref.watch(bookingsRepositoryProvider);
      return await repo.getMyBookings(arg.groupId, status: arg.status);
    });
