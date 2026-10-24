import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_bookings_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../data/bookings_repository.dart';
import 'reschedule_booking_sheet.dart';
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
  String? _selectedGroupFilter;
  String? _selectedStatusFilter;

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        break;
      case 'CANCELLED':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red.shade700;
        break;
      case 'COMPLETED':
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue.shade700;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bookingsAsync = ref.watch(
      allBookingsProvider((
        groupId: _selectedGroupFilter,
        status: _selectedStatusFilter,
      )),
    );

    final groupsAsync = ref.watch(myGroupsProvider);
    final groupNames = <String, String>{};
    groupsAsync.whenData((groups) {
      for (final g in groups) {
        groupNames[g.id] = g.name;
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            allBookingsProvider((
              groupId: _selectedGroupFilter,
              status: _selectedStatusFilter,
            )),
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Bookings'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            selected: _selectedStatusFilter == null,
                            label: const Text('All Status'),
                            onSelected: (_) {
                              setState(() => _selectedStatusFilter = null);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedStatusFilter == 'CONFIRMED',
                            label: const Text('Confirmed'),
                            onSelected: (_) {
                              setState(() {
                                _selectedStatusFilter =
                                    _selectedStatusFilter == 'CONFIRMED'
                                        ? null
                                        : 'CONFIRMED';
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedStatusFilter == 'CANCELLED',
                            label: const Text('Cancelled'),
                            onSelected: (_) {
                              setState(() {
                                _selectedStatusFilter =
                                    _selectedStatusFilter == 'CANCELLED'
                                        ? null
                                        : 'CANCELLED';
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedStatusFilter == 'COMPLETED',
                            label: const Text('Completed'),
                            onSelected: (_) {
                              setState(() {
                                _selectedStatusFilter =
                                    _selectedStatusFilter == 'COMPLETED'
                                        ? null
                                        : 'COMPLETED';
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (groupNames.length > 1) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        clipBehavior: Clip.none,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              selected: _selectedGroupFilter == null,
                              label: const Text('All Groups'),
                              onSelected: (_) {
                                setState(() => _selectedGroupFilter = null);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            ...groupNames.entries.map((entry) {
                              final isSelected =
                                    _selectedGroupFilter == entry.key;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text(entry.value),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedGroupFilter = isSelected
                                          ? null
                                          : entry.key;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            bookingsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
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
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.bookmark_border_outlined,
                      title: 'No Bookings Found',
                      description:
                          'You have no bookings matching the criteria.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
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
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Padding(
                                padding: kCardPadding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        borderRadius: BorderRadius.circular(10),
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
                                    if (booking.status.toUpperCase() ==
                                            'CONFIRMED' &&
                                        isUpcoming) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () async {
                                              final res =
                                                  await RescheduleBookingSheet
                                                      .show(
                                                context,
                                                booking: booking,
                                              );
                                              if (res == true) {
                                                ref.invalidate(
                                                  allBookingsProvider((
                                                    groupId:
                                                        _selectedGroupFilter,
                                                    status:
                                                        _selectedStatusFilter,
                                                  )),
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.edit_calendar_outlined,
                                              size: 16,
                                            ),
                                            label: const Text('Reschedule'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
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
                                                    groupId:
                                                        _selectedGroupFilter,
                                                    status:
                                                        _selectedStatusFilter,
                                                  )),
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  colorScheme.error,
                                              side: BorderSide(
                                                color: colorScheme.error
                                                    .withValues(alpha: 0.5),
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
                                        ],
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
