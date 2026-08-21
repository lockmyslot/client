import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/my_bookings_provider.dart';
import '../data/bookings_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MyBookingsScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider((groupId: widget.groupId, status: _selectedStatusFilter)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(12),
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

          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorDisplay(
                error: err.toString(),
                onRetry: () => ref.invalidate(myBookingsProvider((groupId: widget.groupId, status: _selectedStatusFilter))),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const EmptyState(
                    icon: Icons.bookmark_border,
                    title: 'No Personal Bookings',
                    description: 'You have no active or past bookings in this group.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myBookingsProvider((groupId: widget.groupId, status: _selectedStatusFilter))),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final isUpcoming = booking.startTime.isAfter(DateTime.now());

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        booking.resourceName ?? 'Resource Booking',
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
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${AppDateUtils.formatDisplayDate(booking.startTime)} · ${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}',
                                      ).small(),
                                    ),
                                  ],
                                ),
                                if (booking.isConfirmed && isUpcoming) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        final confirmed = await ConfirmDialog.show(
                                          context,
                                          title: 'Cancel Booking',
                                          message: 'Are you sure you want to cancel this booking?',
                                          confirmText: 'Cancel Booking',
                                          isDestructive: true,
                                        );
                                        if (confirmed == true) {
                                          await ref
                                              .read(bookingsRepositoryProvider)
                                              .cancelBooking(widget.groupId, booking.id);
                                          ref.invalidate(myBookingsProvider((groupId: widget.groupId, status: _selectedStatusFilter)));
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.close_outlined, size: 18),
                                      label: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedStatusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : null,
          ),
        ).small(),
      ),
    );
  }
}
