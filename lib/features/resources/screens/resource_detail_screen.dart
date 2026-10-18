import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../providers/maintenance_provider.dart';
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

  Widget _toolbarDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceAsync = ref.watch(
      resourceDetailProvider((groupId: groupId, resourceId: resourceId)),
    );
    final bookingsAsync = ref.watch(
      resourceBookingsProvider((
        groupId: groupId,
        resourceId: resourceId,
        date: null,
      )),
    );
    final maintenanceAsync = ref.watch(
      resourceMaintenanceProvider((
        groupId: groupId,
        resourceId: resourceId,
        status: null,
      )),
    );

    final colorScheme = Theme.of(context).colorScheme;

    final bottomBar = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
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
          onPressed: () => context.push(
            '/groups/$groupId/resources/$resourceId/book',
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 18),
              SizedBox(width: 8),
              Text('Book a Slot'),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      bottomNavigationBar: bottomBar,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            resourceDetailProvider((groupId: groupId, resourceId: resourceId)),
          );
          ref.invalidate(
            resourceBookingsProvider((
              groupId: groupId,
              resourceId: resourceId,
              date: null,
            )),
          );
          ref.invalidate(
            resourceMaintenanceProvider((
              groupId: groupId,
              resourceId: resourceId,
              status: null,
            )),
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: resourceAsync.when(
                data: (res) => Text(res.name),
                loading: () => const Text('Loading Resource...'),
                error: (_, __) => const Text('Resource Detail'),
              ),
              pinned: true,
              actions: [
                IconButton(
                  tooltip: 'Maintenance',
                  icon: const Icon(Icons.handyman_outlined),
                  onPressed: () => context.push(
                    '/groups/$groupId/resources/$resourceId/maintenance',
                  ),
                ),
                IconButton(
                  tooltip: 'Rules',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(
                    '/groups/$groupId/resources/$resourceId/rules',
                  ),
                ),
              ],
            ),
            resourceAsync.maybeWhen(
              data: (res) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 18),
                                const SizedBox(width: 6),
                                Text('${res.capacity}'),
                              ],
                            ),
                          ),
                          _toolbarDivider(context),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_outlined, size: 18),
                                const SizedBox(width: 6),
                                Text('${res.slotDurationMinutes} min'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: resourceAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: ErrorDisplay(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(
                      resourceDetailProvider((
                        groupId: groupId,
                        resourceId: resourceId,
                      )),
                    ),
                  ),
                ),
                data: (resource) => SliverList(
                  delegate: SliverChildListDelegate([
                    if (resource.description != null &&
                        resource.description!.isNotEmpty) ...[
                      Text(resource.description!).muted().p(),
                      const SizedBox(height: 10),
                    ],

                    // Maintenance Alert Banner
                    maintenanceAsync.when(
                      data: (tasks) {
                        final active = tasks
                            .where((t) => t.isInProgress || t.isScheduled)
                            .toList();
                        if (active.isEmpty) return const SizedBox.shrink();

                        final inProgress =
                            active.where((t) => t.isInProgress).toList();
                        final isCurrentlyUnderMaintenance =
                            inProgress.isNotEmpty;
                        final displayTask = isCurrentlyUnderMaintenance
                            ? inProgress.first
                            : active.first;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrentlyUnderMaintenance
                                ? Colors.orange.withValues(alpha: 0.12)
                                : colorScheme.primaryContainer.withValues(
                                    alpha: 0.35,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentlyUnderMaintenance
                                  ? Colors.orange.shade400
                                  : colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCurrentlyUnderMaintenance
                                    ? Icons.build_circle
                                    : Icons.info_outline,
                                color: isCurrentlyUnderMaintenance
                                    ? Colors.orange.shade800
                                    : colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrentlyUnderMaintenance
                                          ? 'Currently Under Maintenance'
                                          : 'Maintenance Scheduled',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isCurrentlyUnderMaintenance
                                            ? Colors.orange.shade900
                                            : colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${displayTask.title} (${displayTask.isRecurring ? displayTask.recurrenceSummary : AppDateUtils.formatDate(displayTask.startTime)})',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/groups/$groupId/resources/$resourceId/maintenance',
                                ),
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Schedule Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Schedule').h3(),
                        IconButton(
                          icon: const Icon(Icons.refresh_outlined, size: 16),
                          onPressed: () => ref.invalidate(
                            resourceBookingsProvider((
                              groupId: groupId,
                              resourceId: resourceId,
                              date: null,
                            )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    SlideFadeSwitcher(
                      child: bookingsAsync.when(
                        loading: () => const KeyedSubtree(
                          key: ValueKey('loading'),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => KeyedSubtree(
                          key: const ValueKey('error'),
                          child: ErrorDisplay(
                            error: err.toString(),
                            onRetry: () => ref.invalidate(
                              resourceBookingsProvider((
                                groupId: groupId,
                                resourceId: resourceId,
                                date: null,
                              )),
                            ),
                          ),
                        ),
                        data: (bookings) {
                          if (bookings.isEmpty) {
                            return const KeyedSubtree(
                              key: ValueKey('empty'),
                              child: EmptyState(
                                icon: Icons.calendar_today_outlined,
                                title: 'No Upcoming Bookings',
                                description:
                                    'There are no bookings scheduled for this resource yet.',
                              ),
                            );
                          }

                          final sorted = [...bookings]
                            ..sort(
                              (a, b) => a.startTime.compareTo(b.startTime),
                            );

                          final grouped = <String, List<Booking>>{};
                          for (final booking in sorted) {
                            grouped
                                .putIfAbsent(
                                  AppDateUtils.formatDate(booking.startTime),
                                  () => [],
                                )
                                .add(booking);
                          }

                          return KeyedSubtree(
                            key: const ValueKey('data'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: grouped.entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Entrance(
                                            delay: const Duration(
                                              milliseconds: 120,
                                            ),
                                            child: Text(
                                              AppDateUtils.formatDisplayDate(
                                                entry.value.first.startTime,
                                              ),
                                            ).textLarge().semiBold(),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Divider(
                                              color: colorScheme.outlineVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...entry.value.map((booking) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Entrance(
                                          delay: const Duration(
                                            milliseconds: 140,
                                          ),
                                          child: Card(
                                            elevation: 0,
                                            color: colorScheme
                                                .surfaceContainerLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: BorderSide(
                                                color: colorScheme
                                                    .outlineVariant
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: kCardPadding,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.schedule_outlined,
                                                        size: 16,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                                      ).mono().semiBold(),
                                                      const Spacer(),
                                                      PrimaryBadge(
                                                        child: Text(
                                                          booking.status,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person_outline,
                                                        size: 16,
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          booking.userDisplayName ??
                                                              'User',
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ).small().muted(),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 70),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
