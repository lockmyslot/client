import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking.dart';
import '../data/bookings_repository.dart';
import '../../groups/providers/groups_provider.dart';

final myBookingsProvider =
    FutureProvider.family<List<Booking>, ({String groupId, String? status})>((
      ref,
      arg,
    ) async {
      final repo = ref.watch(bookingsRepositoryProvider);
      return await repo.getMyBookings(arg.groupId, status: arg.status);
    });

final allBookingsProvider =
    FutureProvider.family<List<Booking>, ({String? groupId, String? status})>((
      ref,
      arg,
    ) async {
      final repo = ref.watch(bookingsRepositoryProvider);
      if (arg.groupId != null && arg.groupId!.isNotEmpty) {
        return await repo.getMyBookings(arg.groupId!, status: arg.status);
      }

      final groups = await ref.watch(myGroupsProvider.future);
      if (groups.isEmpty) return [];

      final results = await Future.wait(
        groups.map((group) async {
          try {
            return await repo.getMyBookings(group.id, status: arg.status);
          } catch (_) {
            return <Booking>[];
          }
        }),
      );

      final List<Booking> allBookings = [];
      for (final list in results) {
        allBookings.addAll(list);
      }

      allBookings.sort((a, b) => b.startTime.compareTo(a.startTime));
      return allBookings;
    });
