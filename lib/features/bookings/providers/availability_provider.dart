import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/availability.dart';
import '../data/bookings_repository.dart';

class AvailabilityParams {
  final String groupId;
  final String resourceId;
  final String date;
  final String? excludeBookingId;

  const AvailabilityParams({
    required this.groupId,
    required this.resourceId,
    required this.date,
    this.excludeBookingId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          resourceId == other.resourceId &&
          date == other.date &&
          excludeBookingId == other.excludeBookingId;

  @override
  int get hashCode => Object.hash(groupId, resourceId, date, excludeBookingId);
}

final availabilityProvider =
    FutureProvider.family<Availability, AvailabilityParams>((ref, arg) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return await repo.getAvailability(
    arg.groupId,
    arg.resourceId,
    arg.date,
    excludeBookingId: arg.excludeBookingId,
  );
});
