import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking.dart';
import '../data/bookings_repository.dart';

final resourceBookingsProvider = FutureProvider.family<List<Booking>, ({String groupId, String resourceId, String? date})>((ref, arg) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return await repo.getBookings(arg.groupId, arg.resourceId, date: arg.date);
});
