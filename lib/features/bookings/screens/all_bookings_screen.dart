import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_bookings_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../data/bookings_repository.dart';
import 'reschedule_booking_sheet.dart';
import '../../resources/widgets/resource_avatar.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

class AllBookingsScreen extends ConsumerStatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  ConsumerState<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends ConsumerState<AllBookingsScreen> {
  String? _selectedGroupFilter;
  String? _selectedStatusFilter;

  Widget _buildStatusBadge(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color border;
    Color fg;

    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        border = const Color(0xFF10B981).withValues(alpha: 0.4);
        fg = const Color(0xFF10B981);
        break;
      case 'CANCELLED':
        bg = cs.errorContainer;
        border = cs.error.withValues(alpha: 0.4);
        fg = cs.onErrorContainer;
        break;
      case 'COMPLETED':
        bg = cs.secondaryContainer;
        border = cs.secondary.withValues(alpha: 0.4);
        fg = cs.onSecondaryContainer;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        border = cs.outlineVariant.withValues(alpha: 0.5);
        fg = cs.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            const M3CollapsingAppBar(
              title: Text('Bookings'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String?>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: null,
                            label: Text(
                              'All',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: 'CONFIRMED',
                            label: Text(
                              'Confirmed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: 'CANCELLED',
                            label: Text(
                              'Cancelled',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ButtonSegment(
                            value: 'COMPLETED',
                            label: Text(
                              'Completed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        selected: {_selectedStatusFilter},
                        onSelectionChanged: (val) {
                          setState(() => _selectedStatusFilter = val.first);
                        },
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          selectedBackgroundColor: colorScheme.primaryContainer,
                          selectedForegroundColor:
                              colorScheme.onPrimaryContainer,
                          backgroundColor: colorScheme.surfaceContainerLow,
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (groupNames.length > 1) ...[
                      const SizedBox(height: 10),
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
                                      _selectedGroupFilter =
                                          isSelected ? null : entry.key;
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
                        final isConfirmed = booking.isConfirmed;
                        final groupName =
                            groupNames[booking.groupId] ?? 'Group Booking';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Entrance(
                            delay: Duration(milliseconds: index * 50),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ResourceAvatar(
                                        iconKey: booking.resourceIcon,
                                        colorHex: booking.resourceColor,
                                        name: booking.resourceName ??
                                            'Resource',
                                        size: 38,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              booking.resourceName ??
                                                  'Resource Booking',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                                      _buildStatusBadge(
                                        context,
                                        booking.status,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_outlined,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${AppDateUtils.formatDisplayDate(booking.startTime)} · ${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isConfirmed && isUpcoming) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FilledButton.tonalIcon(
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
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                            foregroundColor: colorScheme.error,
                                            side: BorderSide(
                                              color: colorScheme.error
                                                  .withValues(alpha: 0.4),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.close_rounded,
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
