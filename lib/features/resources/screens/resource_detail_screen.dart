import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../../bookings/data/models/booking.dart';
import '../../bookings/providers/bookings_provider.dart';
import '../../../core/ui/ui.dart';
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
      appBar: AppBar(
        title: resourceAsync.when(
          data: (res) => Text(res.name),
          loading: () => const Text('Loading Resource...'),
          error: (_, __) => const Text('Resource Detail'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/groups/$groupId/resources/$resourceId/rules'),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        // Fixed Bottom Action Bar for Booking a Slot
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: PrimaryButton(
          expand: true,
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
      body: resourceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.invalidate(resourceDetailProvider((groupId: groupId, resourceId: resourceId))),
        ),
        data: (resource) {
          final content = RefreshIndicator(
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      IconButton(
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

                      final sorted = [...bookings]
                        ..sort((a, b) => a.startTime.compareTo(b.startTime));

                      final grouped = <String, List<Booking>>{};
                      for (final booking in sorted) {
                        grouped.putIfAbsent(AppDateUtils.formatDate(booking.startTime), () => []).add(booking);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      AppDateUtils.formatDisplayDate(entry.value.first.startTime),
                                    ).textLarge().semiBold(),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context).colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...entry.value.map((booking) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Time Range
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                              ).mono().semiBold(),
                                              const Spacer(),
                                              PrimaryBadge(child: Text(booking.status)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Booked By
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  booking.userDisplayName ?? 'User',
                                                  overflow: TextOverflow.ellipsis,
                                                ).small().muted(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
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
