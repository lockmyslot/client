import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/my_bookings_provider.dart';
import '../data/bookings_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

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
            const SliverAppBar.large(
              title: Text('My Bookings'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmed', 'CONFIRMED'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cancelled', 'CANCELLED'),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final booking = bookings[index];
                        final isUpcoming = booking.startTime.isAfter(
                          DateTime.now(),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Entrance(
                            delay: Duration(milliseconds: index * 60),
                            child: Card(
                              elevation: 0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
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
                                      children: [
                                        Expanded(
                                          child: Text(
                                            booking.resourceName ??
                                                'Resource Booking',
                                          ).h3(),
                                        ),
                                        PrimaryBadge(
                                          child: Text(booking.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_outlined,
                                          size: 18,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${AppDateUtils.formatDisplayDate(booking.startTime)} · ${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                          ).small(),
                                        ),
                                      ],
                                    ),
                                    if (booking.isConfirmed &&
                                        isUpcoming) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
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
                                                  status: _selectedStatusFilter,
                                                )),
                                              );
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.close_outlined,
                                            size: 18,
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
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
}
