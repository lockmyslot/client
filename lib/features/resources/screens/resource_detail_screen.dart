import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../providers/maintenance_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookings/data/bookings_repository.dart';
import '../../bookings/data/models/booking.dart';
import '../../bookings/providers/bookings_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class ResourceDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;

  const ResourceDetailScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
  });


  @override
  ConsumerState<ResourceDetailScreen> createState() =>
      _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends ConsumerState<ResourceDetailScreen> {
  final Set<String> _cancellingIds = {};

  String get groupId => widget.groupId;
  String get resourceId => widget.resourceId;

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel Booking',
      message: 'Are you sure you want to cancel this booking?',
      confirmText: 'Cancel Booking',
      isDestructive: true,
    );
    if (confirmed != true) return;

    setState(() => _cancellingIds.add(bookingId));
    try {
      await ref
          .read(bookingsRepositoryProvider)
          .cancelBooking(groupId, bookingId);
      ref.invalidate(
        resourceBookingsProvider((
          groupId: groupId,
          resourceId: resourceId,
          date: null,
        )),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingIds.remove(bookingId));
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final currentUserId = ref.watch(authProvider).user?.id;
    final isAdmin = groupAsync.maybeWhen(
      data: (group) => group.isAdmin,
      orElse: () => false,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: resourceAsync.maybeWhen(
        data: (res) => res.isActive
            ? FloatingActionButton.extended(
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Book a Slot'),
                onPressed: () => context.push(
                  '/groups/$groupId/resources/$resourceId/book',
                ),
              )
            : null,
        orElse: () => null,
      ),
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
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.push(
                      '/groups/$groupId/resources/$resourceId/settings',
                    ),
                  ),
              ],
              pinned: true,
            ),
            resourceAsync.maybeWhen(
              data: (res) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!res.isActive)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This resource is currently inactive. New bookings are disabled.',
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // KPI Stat Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            KpiStatChip(
                              icon: Icons.people_outline,
                              value: '${res.capacity}',
                              label: 'Capacity',
                            ),
                            const SizedBox(width: 8),
                            KpiStatChip(
                              icon: Icons.timer_outlined,
                              value: '${res.slotDurationMinutes}m',
                              label: 'Slots',
                            ),
                            const SizedBox(width: 8),
                            KpiStatChip(
                              icon: res.isActive
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              value: res.isActive ? 'Active' : 'Inactive',
                              label: 'Status',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            if (isAdmin) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/groups/$groupId/resources/$resourceId/settings',
                                  ),
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Settings'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(
                                  '/groups/$groupId/resources/$resourceId/maintenance',
                                ),
                                icon: const Icon(
                                  Icons.handyman_outlined,
                                  size: 16,
                                ),
                                label: const Text('Maintenance'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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

                          final myBookings = sorted
                              .where((b) => b.userId == currentUserId)
                              .toList();
                          final othersBookings = sorted
                              .where((b) => b.userId != currentUserId)
                              .toList();

                          return KeyedSubtree(
                            key: const ValueKey('data'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // My Bookings Subsection
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('My Bookings')
                                          .textLarge()
                                          .semiBold(),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${myBookings.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh_outlined,
                                          size: 16,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
                                ),
                                if (myBookings.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'You have no upcoming bookings for this resource.',
                                    ).small().muted(),
                                  )
                                else
                                  ...myBookings.asMap().entries.map(
                                    (e) => _buildBookingCard(
                                      context,
                                      e.value,
                                      e.key,
                                      colorScheme,
                                      canCancel: true,
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                // Others' Bookings Subsection
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('Other Bookings')
                                          .textLarge()
                                          .semiBold(),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${othersBookings.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (othersBookings.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'No bookings from other members.',
                                    ).small().muted(),
                                  )
                                else
                                  ...othersBookings.asMap().entries.map(
                                    (e) => _buildBookingCard(
                                      context,
                                      e.value,
                                      e.key,
                                      colorScheme,
                                      canCancel: isAdmin,
                                    ),
                                  ),
                              ],
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

  Widget _buildBookingCard(
    BuildContext context,
    Booking booking,
    int index,
    ColorScheme colorScheme, {
    bool canCancel = false,
  }) {
    final duration = booking.endTime.difference(booking.startTime);
    final durationText = AppDateUtils.formatDuration(duration);
    final userName = (booking.userDisplayName != null &&
            booking.userDisplayName!.trim().isNotEmpty)
        ? booking.userDisplayName!
        : 'User';

    final isUpcoming = booking.startTime.isAfter(DateTime.now());
    final showCancel = canCancel && booking.isConfirmed && isUpcoming;
    final isCancelling = _cancellingIds.contains(booking.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Entrance(
        delay: Duration(milliseconds: 100 + (index * 25)),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: kCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateUtils.formatBookingHeader(
                    booking.startTime,
                  ),
                ).h4().semiBold(),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$durationText · $userName',
                        overflow: TextOverflow.ellipsis,
                      ).small().muted(),
                    ),
                    if (showCancel)
                      isCancelling
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.error,
                                ),
                              ),
                            )
                          : TextButton.icon(
                              onPressed: () =>
                                  _cancelBooking(context, booking.id),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.close_outlined,
                                size: 16,
                              ),
                              label: const Text('Cancel'),
                            ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
