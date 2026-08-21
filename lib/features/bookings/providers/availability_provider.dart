import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/availability.dart';
import '../data/bookings_repository.dart';

final availabilityProvider =
    FutureProvider.family<
      Availability,
      ({String groupId, String resourceId, String date})
    >((ref, arg) async {
      final repo = ref.watch(bookingsRepositoryProvider);
      return await repo.getAvailability(arg.groupId, arg.resourceId, arg.date);
    });
