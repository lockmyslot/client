import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bookings_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class BookingsCalendarScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;

  const BookingsCalendarScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
  });

  @override
  ConsumerState<BookingsCalendarScreen> createState() =>
      _BookingsCalendarScreenState();
}

class _BookingsCalendarScreenState
    extends ConsumerState<BookingsCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _selectedDateString => AppDateUtils.formatDate(_selectedDate);

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(
      resourceBookingsProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
        date: _selectedDateString,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
        bottom: AppBarToolbar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_outlined),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
              SlideFadeSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  AppDateUtils.formatDisplayDate(_selectedDate),
                  key: ValueKey('date-$_selectedDateString'),
                ).h4(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_outlined),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ),
      ),
      body: SlideFadeSwitcher(
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
                  groupId: widget.groupId,
                  resourceId: widget.resourceId,
                  date: _selectedDateString,
                )),
              ),
            ),
          ),
          data: (bookings) {
            if (bookings.isEmpty) {
              return KeyedSubtree(
                key: ValueKey('empty-$_selectedDateString'),
                child: EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No Bookings',
                  description:
                      'No bookings scheduled for ${AppDateUtils.formatDisplayDate(_selectedDate)}.',
                ),
              );
            }

            return KeyedSubtree(
              key: ValueKey('data-$_selectedDateString'),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Entrance(
                      delay: Duration(milliseconds: index * 60),
                      child: Card(
                        child: Padding(
                          padding: kCardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      AppDateUtils.formatDisplayDate(
                                        booking.startTime,
                                      ),
                                    ).small().semiBold(),
                                  ),
                                  PrimaryBadge(child: Text(booking.status)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_outlined,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${AppDateUtils.formatTime(booking.startTime)} - ${AppDateUtils.formatTime(booking.endTime)}',
                                  ).mono().small(),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Booked by: ${booking.userDisplayName ?? 'User'}',
                                  ).small().muted(),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}
