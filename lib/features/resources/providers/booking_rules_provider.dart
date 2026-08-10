import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_rule.dart';
import '../data/resources_repository.dart';

final bookingRulesProvider = FutureProvider.family<List<BookingRule>, ({String groupId, String resourceId})>((ref, arg) async {
  final repo = ref.watch(resourcesRepositoryProvider);
  return await repo.getBookingRules(arg.groupId, arg.resourceId);
});
