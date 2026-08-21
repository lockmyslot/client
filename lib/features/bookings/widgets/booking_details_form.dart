import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/availability.dart';
import '../data/bookings_repository.dart';
import '../providers/availability_provider.dart';
import '../providers/bookings_provider.dart';
import '../providers/my_bookings_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/error_display.dart';

class BookingDetailsForm extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;

  const BookingDetailsForm({
    super.key,
    required this.groupId,
    required this.resourceId,
  });

  @override
  ConsumerState<BookingDetailsForm> createState() => _BookingDetailsFormState();
}

class _BookingDetailsFormState extends ConsumerState<BookingDetailsForm> {
  late DateTime _selectedDate;
  TimeSlot? _selectedStartTimeSlot;
  int _selectedDurationSlots = 1; // Number of slotDurationMinutes units
  bool _isBooking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get _selectedDateString => AppDateUtils.formatDate(_selectedDate);

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedStartTimeSlot = null;
      _selectedDurationSlots = 1;
      _errorMessage = null;
    });
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  // Find all slots in the range starting from _selectedStartTimeSlot for _selectedDurationSlots
  List<TimeSlot> _calculateRequestedSlots(List<TimeSlot> allSlots) {
    if (_selectedStartTimeSlot == null) return [];

    final startIndex = allSlots.indexWhere((s) => s.startTime.isAtSameMomentAs(_selectedStartTimeSlot!.startTime));
    if (startIndex == -1) return [];

    final requested = <TimeSlot>[];
    for (int i = 0; i < _selectedDurationSlots; i++) {
      final idx = startIndex + i;
      if (idx < allSlots.length) {
        requested.add(allSlots[idx]);
      }
    }
    return requested;
  }

  bool _isRangeValid(List<TimeSlot> requestedSlots) {
    if (requestedSlots.length < _selectedDurationSlots) return false;
    return requestedSlots.every((s) => s.isAvailable);
  }

  Future<void> _handleConfirmBooking(List<TimeSlot> requestedSlots) async {
    if (requestedSlots.isEmpty || !_isRangeValid(requestedSlots)) return;

    final startTime = requestedSlots.first.startTime;
    final endTime = requestedSlots.last.endTime;

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(bookingsRepositoryProvider);
      await repo.createBooking(
        widget.groupId,
        widget.resourceId,
        startTime: startTime,
        endTime: endTime,
      );

      // Invalidate relevant providers to force auto-refetch of schedule and personal bookings
      ref.invalidate(availabilityProvider((groupId: widget.groupId, resourceId: widget.resourceId, date: _selectedDateString)));
      ref.invalidate(myBookingsProvider((groupId: widget.groupId, status: null)));
      ref.invalidate(resourceBookingsProvider((groupId: widget.groupId, resourceId: widget.resourceId, date: null)));

      if (mounted) {
        context.pop(); // Directly return to the screen the booking was launched from
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildBottomBar({required bool isValid, required List<TimeSlot> requestedSlots}) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark_added, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppDateUtils.formatDisplayDate(_selectedDate)} • ${AppDateUtils.formatTime(requestedSlots.first.startTime)} - ${AppDateUtils.formatTime(requestedSlots.last.endTime)}',
                ).small().muted(),
              ),
              const SizedBox(width: 8),
              PrimaryBadge(
                child: Text(isValid ? 'Available' : 'Unavailable'),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 8),
            const Text(
              'One or more slots in the selected duration are already booked or restricted.',
              style: TextStyle(color: Colors.red),
            ).small(),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            expand: true,
            onPressed: (isValid && !_isBooking)
                ? () => _handleConfirmBooking(requestedSlots)
                : null,
            child: _isBooking
                ? const CircularProgressIndicator()
                : const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(availabilityProvider((groupId: widget.groupId, resourceId: widget.resourceId, date: _selectedDateString)));

    return availabilityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorDisplay(
        error: err.toString(),
        onRetry: () => ref.invalidate(availabilityProvider((groupId: widget.groupId, resourceId: widget.resourceId, date: _selectedDateString))),
      ),
      data: (availability) {
        final userStats = availability.userStats;
        final allSlots = availability.slots;
        final slotMinutes = availability.slotDurationMinutes;
        final requestedSlots = _calculateRequestedSlots(allSlots);
        final isValid = _isRangeValid(requestedSlots);
        final showSummary = _selectedStartTimeSlot != null && requestedSlots.isNotEmpty;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Date Strip & Calendar Picker Launcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppDateUtils.formatDisplayDate(_selectedDate)).h3(),
                        OutlineButton(
                          onPressed: _pickCalendarDate,
                          child: const Row(
                            children: [
                              Icon(Icons.event, size: 16),
                              SizedBox(width: 6),
                              Text('Change Date'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Quick Date Chips (7 days)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          final date = DateTime.now().add(Duration(days: index));
                          final isSelected = AppDateUtils.isSameDay(date, _selectedDate);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _onDateSelected(date),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      index == 0 ? 'Today' : AppDateUtils.formatShortDate(date),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : null,
                                      ),
                                    ).small(),
                                    Text(
                                      AppDateUtils.formatWeekday(date),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : null,
                                      ),
                                    ).mono().small(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. User Allowance Stats Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Bookings').small().muted(),
                                Text('${userStats.bookingsToday}${userStats.maxBookingsPerDay != null ? '/${userStats.maxBookingsPerDay}' : ''}')
                                    .h4(),
                              ],
                            ),
                            Container(height: 20, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                            Column(
                              children: [
                                const Text('Hours Used').small().muted(),
                                Text('${userStats.hoursToday.toStringAsFixed(1)}${userStats.maxHoursPerDay != null ? '/${userStats.maxHoursPerDay}' : ''}h')
                                    .h4(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Time Picker Section
                    const Text('Select Start Time').h3(),
                    if (availability.availableFrom != null || availability.availableUntil != null) ...[
                      const SizedBox(height: 2),
                      Text('Available hours: ${AppDateUtils.formatTimeString(availability.availableFrom ?? '00:00')} - ${AppDateUtils.formatTimeString(availability.availableUntil ?? '24:00')}')
                          .small()
                          .muted(),
                    ],
                    const SizedBox(height: 6),

                    if (allSlots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No bookable slots available for this date.')),
                      )
                    else
                      // Time Selector Grid (Full Viewport Width Spanning)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: allSlots.length,
                        itemBuilder: (context, index) {
                          final slot = allSlots[index];
                          final isSelected = _selectedStartTimeSlot?.startTime.isAtSameMomentAs(slot.startTime) ?? false;
                          final isAvail = slot.isAvailable;

                          Color chipBg;
                          if (isSelected) {
                            chipBg = Theme.of(context).colorScheme.primary;
                          } else if (isAvail) {
                            chipBg = Theme.of(context).colorScheme.surfaceContainerHighest;
                          } else {
                            chipBg = Colors.grey.withValues(alpha: 0.1);
                          }

                          return GestureDetector(
                            onTap: isAvail
                                ? () {
                                    setState(() {
                                      _selectedStartTimeSlot = slot;
                                      _errorMessage = null;
                                    });
                                  }
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : isAvail
                                          ? Colors.green.withValues(alpha: 0.4)
                                          : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAvail ? Icons.access_time : Icons.block,
                                      size: 13,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : isAvail
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      AppDateUtils.formatTime(slot.startTime),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : !isAvail
                                                ? Colors.grey
                                                : null,
                                      ),
                                    ).mono().small(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // 4. Duration Selector
                    if (_selectedStartTimeSlot != null) ...[
                      const Text('Select Duration').h3(),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(4, (index) {
                            final durationUnits = index + 1;
                            final durationMinutes = durationUnits * slotMinutes;
                            final isSelected = _selectedDurationSlots == durationUnits;

                            String durationLabel;
                            if (durationMinutes < 60) {
                              durationLabel = '$durationMinutes mins';
                            } else if (durationMinutes % 60 == 0) {
                              durationLabel = '${durationMinutes ~/ 60} ${durationMinutes == 60 ? 'hour' : 'hours'}';
                            } else {
                              durationLabel = '${(durationMinutes / 60).toStringAsFixed(1)} hours';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDurationSlots = durationUnits;
                                    _errorMessage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    durationLabel,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : null,
                                    ),
                                  ).small().semiBold(),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ).small(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            if (showSummary)
              _buildBottomBar(isValid: isValid, requestedSlots: requestedSlots),
          ],
        );
      },
    );
  }
}