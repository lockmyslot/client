import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_bookings_provider.dart';
import '../data/bookings_repository.dart';
import 'reschedule_booking_sheet.dart';
import '../../resources/widgets/resource_avatar.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MyBookingsScreen({super.key, required this.groupId});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bookingsAsync = ref.watch(
      myBookingsProvider((
        groupId: widget.groupId,
        status: _selectedStatusFilter,
      )),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(
          myBookingsProvider((
            groupId: widget.groupId,
            status: _selectedStatusFilter,
          )),
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const M3CollapsingAppBar(
              title: Text('My Bookings'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(
                        value: null,
                        label: Text(
                          'All',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ButtonSegment(
                        value: 'CONFIRMED',
                        label: Text(
                          'Confirmed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ButtonSegment(
                        value: 'CANCELLED',
                        label: Text(
                          'Cancelled',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    selected: {_selectedStatusFilter},
                    onSelectionChanged: (val) {
                      setState(() => _selectedStatusFilter = val.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: cs.primaryContainer,
                      selectedForegroundColor: cs.onPrimaryContainer,
                      backgroundColor: cs.surfaceContainerLow,
                      foregroundColor: cs.onSurface,
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
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
                    myBookingsProvider((
                      groupId: widget.groupId,
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
                      icon: Icons.bookmark_border,
                      title: 'No Personal Bookings',
                      description:
                          'You have no active or past bookings in this group.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = bookings[index];
                        final isUpcoming = booking.startTime.isAfter(
                          DateTime.now(),
                        );
                        final isConfirmed = booking.isConfirmed;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Entrance(
                            delay: Duration(milliseconds: index * 60),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                        child: Text(
                                          booking.resourceName ??
                                              'Resource Booking',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isConfirmed
                                              ? const Color(0xFF10B981)
                                                  .withValues(alpha: 0.15)
                                              : cs.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isConfirmed
                                                ? const Color(0xFF10B981)
                                                    .withValues(alpha: 0.4)
                                                : cs.error
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          booking.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isConfirmed
                                                ? const Color(0xFF10B981)
                                                : cs.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 16,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${AppDateUtils.formatDisplayDate(booking.startTime)} · ${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                                myBookingsProvider((
                                                  groupId: widget.groupId,
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
                                                    widget.groupId,
                                                    booking.id,
                                                  );
                                              ref.invalidate(
                                                myBookingsProvider((
                                                  groupId: widget.groupId,
                                                  status:
                                                      _selectedStatusFilter,
                                                )),
                                              );
                                            }
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: cs.error,
                                            side: BorderSide(
                                              color: cs.error
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
