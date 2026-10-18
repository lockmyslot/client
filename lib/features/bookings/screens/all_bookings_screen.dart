import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_bookings_provider.dart';
import '../data/bookings_repository.dart';
import '../../groups/providers/groups_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class AllBookingsScreen extends ConsumerStatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  ConsumerState<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends ConsumerState<AllBookingsScreen> {
  String? _selectedStatusFilter;
  String? _selectedGroupFilter;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bookingsAsync = ref.watch(
      allBookingsProvider((
        groupId: _selectedGroupFilter,
        status: _selectedStatusFilter,
      )),
    );

    final Map<String, String> groupNames = {};
    groupsAsync.whenData((groups) {
      for (final g in groups) {
        groupNames[g.id] = g.name;
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(
          allBookingsProvider((
            groupId: _selectedGroupFilter,
            status: _selectedStatusFilter,
          )),
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar.large(
              title: Text('Bookings'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildM3FilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildM3FilterChip('Confirmed', 'CONFIRMED'),
                      const SizedBox(width: 8),
                      _buildM3FilterChip('Cancelled', 'CANCELLED'),
                      groupsAsync.maybeWhen(
                        data: (groups) {
                          if (groups.length <= 1) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              _buildM3GroupFilterMenu(groups),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: bookingsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: ErrorDisplay(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(
                      allBookingsProvider((
                        groupId: _selectedGroupFilter,
                        status: _selectedStatusFilter,
                      )),
                    ),
                  ),
                ),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.bookmark_border_outlined,
                        title: 'No Bookings Found',
                        description:
                            'You have no bookings matching the criteria.',
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = bookings[index];
                        final isUpcoming = booking.startTime.isAfter(
                          DateTime.now(),
                        );
                        final groupName =
                            groupNames[booking.groupId] ?? 'Group Booking';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Entrance(
                            delay: Duration(milliseconds: index * 50),
                            child: Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withOpacity(0.4),
                                ),
                              ),
                              child: Padding(
                                padding: kCardPadding,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking.resourceName ??
                                                    'Resource Booking',
                                              ).h3(),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.group_outlined,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(groupName)
                                                      .small()
                                                      .muted(),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildStatusBadge(booking.status),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainer,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_outlined,
                                            size: 18,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${AppDateUtils.formatDisplayDate(booking.startTime)} · ${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ).small(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (booking.isConfirmed &&
                                        isUpcoming) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final confirmed =
                                                await ConfirmDialog.show(
                                              context,
                                              title: 'Cancel Booking',
                                              message:
                                                  'Are you sure you want to cancel this booking?',
                                              confirmText: 'Cancel Booking',
                                              isDestructive: true,
                                            );
                                            if (confirmed == true) {
                                              await ref
                                                  .read(
                                                    bookingsRepositoryProvider,
                                                  )
                                                  .cancelBooking(
                                                    booking.groupId,
                                                    booking.id,
                                                  );
                                              ref.invalidate(
                                                allBookingsProvider((
                                                  groupId: _selectedGroupFilter,
                                                  status: _selectedStatusFilter,
                                                )),
                                              );
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                colorScheme.error,
                                            side: BorderSide(
                                              color: colorScheme.error
                                                  .withOpacity(0.5),
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.close_outlined,
                                            size: 16,
                                          ),
                                          label: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: bookings.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3FilterChip(String label, String? value) {
    final isSelected = _selectedStatusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _selectedStatusFilter = value);
      },
      showCheckmark: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildM3GroupFilterMenu(List<dynamic> groups) {
    final selectedName = groups
        .firstWhere(
          (g) => g.id == _selectedGroupFilter,
          orElse: () => null,
        )
        ?.name;

    return PopupMenuButton<String?>(
      initialValue: _selectedGroupFilter,
      onSelected: (value) {
        setState(() => _selectedGroupFilter = value);
      },
      child: FilterChip(
        selected: _selectedGroupFilter != null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedName ?? 'All Groups'),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        onSelected: null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('All Groups'),
        ),
        ...groups.map(
          (g) => PopupMenuItem<String?>(
            value: g.id as String,
            child: Text(g.name as String),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfirmed = status.toUpperCase() == 'CONFIRMED';
    final isCancelled = status.toUpperCase() == 'CANCELLED';

    final bg = isConfirmed
        ? colorScheme.secondaryContainer
        : isCancelled
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerHighest;

    final fg = isConfirmed
        ? colorScheme.onSecondaryContainer
        : isCancelled
            ? colorScheme.onErrorContainer
            : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
