import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/resources_provider.dart';
import '../../bookings/providers/bookings_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class ResourceDetailScreen extends ConsumerWidget {
  final String groupId;
  final String resourceId;

  const ResourceDetailScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceAsync = ref.watch(resourceDetailProvider((groupId: groupId, resourceId: resourceId)));
    final bookingsAsync = ref.watch(resourceBookingsProvider((groupId: groupId, resourceId: resourceId, date: null)));

    return Scaffold(
      headers: [
        AppBar(
          title: resourceAsync.when(
            data: (res) => Text(res.name),
            loading: () => const Text('Loading Resource...'),
            error: (_, __) => const Text('Resource Detail'),
          ),
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/groups/$groupId/resources/$resourceId/rules'),
            ),
          ],
        ),
      ],
      footers: [
        // Fixed Bottom Action Bar for Booking a Slot
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.border,
                width: 1,
              ),
            ),
          ),
          child: PrimaryButton(
            onPressed: () => context.push('/groups/$groupId/resources/$resourceId/book'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 18),
                SizedBox(width: 8),
                Text('Book a Slot'),
              ],
            ),
          ),
        ),
      ],
      child: resourceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.invalidate(resourceDetailProvider((groupId: groupId, resourceId: resourceId))),
        ),
        data: (resource) {
          final content = RefreshTrigger(
            onRefresh: () async {
              ref.invalidate(resourceDetailProvider((groupId: groupId, resourceId: resourceId)));
              ref.invalidate(resourceBookingsProvider((groupId: groupId, resourceId: resourceId, date: null)));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description (if present)
                  if (resource.description != null && resource.description!.isNotEmpty) ...[
                    Text(resource.description!).muted().p(),
                    const SizedBox(height: 10),
                  ],

                  // Icon-based Metadata Row (No Card, No explicit Active pill)
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      // Capacity
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.muted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 14),
                            const SizedBox(width: 5),
                            Text('${resource.capacity}').small().semiBold(),
                          ],
                        ),
                      ),

                      // Slot Duration
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.muted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14),
                            const SizedBox(width: 5),
                            Text('${resource.slotDurationMinutes} min').small().semiBold(),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Resource Schedule Section (Upcoming Bookings)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Schedule').h3(),
                      IconButton.ghost(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () => ref.invalidate(resourceBookingsProvider((groupId: groupId, resourceId: resourceId, date: null))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  bookingsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => ErrorDisplay(
                      error: err.toString(),
                      onRetry: () => ref.invalidate(resourceBookingsProvider((groupId: groupId, resourceId: resourceId, date: null))),
                    ),
                    data: (bookings) {
                      if (bookings.isEmpty) {
                        return const EmptyState(
                          icon: Icons.calendar_today,
                          title: 'No Upcoming Bookings',
                          description: 'There are no bookings scheduled for this resource yet.',
                        );
                      }

                      return Column(
                        children: bookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Line: Date & Status Badge
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            AppDateUtils.formatDisplayDate(booking.startTime),
                                          ).small().semiBold(),
                                        ),
                                        PrimaryBadge(child: Text(booking.status)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Middle Line: Time Range
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${AppDateUtils.formatTime(booking.startTime)} - ${AppDateUtils.formatTime(booking.endTime)}',
                                        ).mono().small(),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Bottom Line: Booked By
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 14),
                                        const SizedBox(width: 6),
                                        Text('Booked by: ${booking.userDisplayName ?? 'User'}').small().muted(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 70), // Bottom spacing for fixed action bar
                ],
              ),
            ),
          );

          if (!resource.isActive) {
            return Opacity(opacity: 0.5, child: content);
          }
          return content;
        },
      ),
    );
  }
}
