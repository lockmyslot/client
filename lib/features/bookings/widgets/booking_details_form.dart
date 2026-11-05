import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/availability.dart';
import '../data/models/booking.dart';
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
  final void Function(Booking booking)? onBookingSuccess;
  final Booking? reschedulingBooking;

  const BookingDetailsForm({
    super.key,
    required this.groupId,
    required this.resourceId,
    this.onBookingSuccess,
    this.reschedulingBooking,
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
    if (widget.reschedulingBooking != null) {
      _selectedDate = widget.reschedulingBooking!.startTime.toLocal();
    } else {
      _selectedDate = DateTime.now();
    }
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
  List<TimeSlot> _calculateRequestedSlots(
    List<TimeSlot> allSlots, {
    TimeSlot? selectedSlot,
    int? slotDurationMinutes,
  }) {
    final startSlot = selectedSlot ?? _selectedStartTimeSlot;
    if (startSlot == null) return [];

    final durationMinutes = slotDurationMinutes ?? 60;
    final isDaySlot = durationMinutes >= 1440 && durationMinutes % 1440 == 0;

    if (isDaySlot) {
      final startIndex = allSlots.indexWhere(
        (s) => s.startTime.isAtSameMomentAs(startSlot.startTime),
      );
      final actualStartSlot =
          startIndex != -1 ? allSlots[startIndex] : startSlot;
      final endTime = actualStartSlot.startTime.add(
        Duration(minutes: _selectedDurationSlots * durationMinutes),
      );
      return [
        TimeSlot(
          startTime: actualStartSlot.startTime,
          endTime: endTime,
          status: actualStartSlot.status,
          booked: actualStartSlot.booked,
          capacity: actualStartSlot.capacity,
        ),
      ];
    }

    final startIndex = allSlots.indexWhere(
      (s) => s.startTime.isAtSameMomentAs(startSlot.startTime),
    );
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

  bool _isRangeValid(List<TimeSlot> requestedSlots, {bool isDaySlot = false}) {
    if (requestedSlots.isEmpty) return false;
    if (isDaySlot) {
      return requestedSlots.every((s) => s.isAvailable);
    }
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
      final Booking booking;
      if (widget.reschedulingBooking != null) {
        booking = await repo.rescheduleBooking(
          widget.groupId,
          widget.reschedulingBooking!.id,
          startTime: startTime,
          endTime: endTime,
        );
      } else {
        booking = await repo.createBooking(
          widget.groupId,
          widget.resourceId,
          startTime: startTime,
          endTime: endTime,
        );
      }

      // Invalidate relevant providers to force auto-refetch of schedule and personal bookings
      ref.invalidate(
        availabilityProvider(
          AvailabilityParams(
            groupId: widget.groupId,
            resourceId: widget.resourceId,
            date: _selectedDateString,
            excludeBookingId: widget.reschedulingBooking?.id,
          ),
        ),
      );
      ref.invalidate(
        myBookingsProvider((groupId: widget.groupId, status: null)),
      );
      ref.invalidate(allBookingsProvider);
      ref.invalidate(
        resourceBookingsProvider((
          groupId: widget.groupId,
          resourceId: widget.resourceId,
          date: null,
        )),
      );

      if (mounted) {
        setState(() {
          _isBooking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reschedulingBooking != null
                  ? 'Booking rescheduled successfully!'
                  : 'Slot booked successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        if (widget.onBookingSuccess != null) {
          widget.onBookingSuccess!(booking);
        } else if (context.canPop()) {
          context.pop(booking);
        } else {
          context.go('/groups/${widget.groupId}/resources/${widget.resourceId}');
        }
      }
    } catch (e) {
      if (mounted) {
        final formattedError = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          _isBooking = false;
          _errorMessage = formattedError;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formattedError),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildOperatingHoursBanner(Availability availability) {
    final from = availability.availableFrom ?? '00:00';
    final until = availability.availableUntil ?? '24:00';
    final is24Hours = (from == '00:00' && until == '24:00');
    final cs = Theme.of(context).colorScheme;

    if (is24Hours) {
      return Row(
        children: [
          Icon(Icons.schedule_outlined, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            'Operating hours: Open 24 hours (All day)',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

    final formattedFrom = AppDateUtils.formatTimeString(from);
    final formattedUntil = AppDateUtils.formatTimeString(until);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 14,
            color: cs.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Operating hours: $formattedFrom – $formattedUntil',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required bool isValid,
    required List<TimeSlot> requestedSlots,
    bool isDaySlot = false,
  }) {
    final String timeRangeText;
    if (isDaySlot) {
      timeRangeText =
          '${AppDateUtils.formatDisplayDate(_selectedDate)} • $_selectedDurationSlots ${_selectedDurationSlots == 1 ? 'day' : 'days'}';
    } else {
      timeRangeText =
          '${AppDateUtils.formatDisplayDate(_selectedDate)} • ${AppDateUtils.formatTime(requestedSlots.first.startTime)} - ${AppDateUtils.formatTime(requestedSlots.last.endTime)}';
    }

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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
            children: [
              const Icon(Icons.bookmark_added_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timeRangeText,
                ).small().muted(),
              ),
              const SizedBox(width: 8),
              PrimaryBadge(child: Text(isValid ? 'Available' : 'Unavailable')),
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
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.reschedulingBooking != null
                        ? 'Confirm Reschedule'
                        : 'Confirm Booking',
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildReschedulingBanner() {
    final reschedulingBooking = widget.reschedulingBooking;
    if (reschedulingBooking == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescheduling ${reschedulingBooking.resourceName ?? "Booking"}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ).small(),
                const SizedBox(height: 2),
                Text(
                  'Current: ${AppDateUtils.formatDisplayDate(reschedulingBooking.startTime)} · ${AppDateUtils.formatTime(reschedulingBooking.startTime)} – ${AppDateUtils.formatTime(reschedulingBooking.endTime)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ).small(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SlideFadeSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            AppDateUtils.formatDisplayDate(_selectedDate),
            key: ValueKey('date-header-$_selectedDateString'),
          ).h3(),
        ),
        OutlineButton(
          onPressed: _pickCalendarDate,
          child: const Row(
            children: [
              Icon(Icons.event_outlined, size: 16),
              SizedBox(width: 6),
              Text('Change Date'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateChips() {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final date = DateTime.now().add(
            Duration(days: index),
          );
          final isSelected = AppDateUtils.isSameDay(
            date,
            _selectedDate,
          );
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onDateSelected(date),
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary
                        : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index == 0
                            ? 'Today'
                            : AppDateUtils.formatShortDate(
                                date,
                              ),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary
                              : null,
                        ),
                      ).small(),
                      Text(
                        AppDateUtils.formatWeekday(date),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary
                              : null,
                        ),
                      ).mono().small(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserStatsCard(UserStats userStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Bookings').small().muted(),
                  SlideFadeSwitcher(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    child: Text(
                      '${userStats.bookingsToday}${userStats.maxBookingsPerDay != null ? '/${userStats.maxBookingsPerDay}' : ''}',
                      key: ValueKey(
                        '${userStats.bookingsToday}/${userStats.maxBookingsPerDay}',
                      ),
                    ).h4(),
                  ),
                ],
              ),
            ),
            Container(
              height: 20,
              width: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Hours Used').small().muted(),
                  SlideFadeSwitcher(
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    child: Text(
                      '${userStats.hoursToday.toStringAsFixed(1)}${userStats.maxHoursPerDay != null ? '/${userStats.maxHoursPerDay}' : ''}h',
                      key: ValueKey(
                        '${userStats.hoursToday.toStringAsFixed(1)}/${userStats.maxHoursPerDay}h',
                      ),
                    ).h4(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSlotsMessage(Availability availability) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No bookable slots available for this date.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (availability.availableFrom != null &&
                      availability.availableUntil != null &&
                      (availability.availableFrom != '00:00' ||
                          availability.availableUntil != '24:00'))
                  ? 'Slots are only generated within operating hours (${AppDateUtils.formatTimeString(availability.availableFrom)} – ${AppDateUtils.formatTimeString(availability.availableUntil)}).'
                  : 'The resource may be fully booked or currently unavailable.',
            ).small().muted(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid(Availability availability) {
    final allSlots = availability.slots;
    if (allSlots.isEmpty) {
      return _buildNoSlotsMessage(availability);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
      itemCount: allSlots.length,
      itemBuilder: (context, index) {
        final slot = allSlots[index];
        final isSelected =
            _selectedStartTimeSlot?.startTime
                .isAtSameMomentAs(slot.startTime) ??
            false;
        final isAvail = slot.isAvailable;

        final cs = Theme.of(context).colorScheme;
        Color chipBg;
        Color chipBorder;
        double borderWidth;
        IconData icon;
        Color? iconColor;
        Color? textColor;
        if (isSelected) {
          chipBg = cs.primaryContainer;
          chipBorder = cs.primary;
          borderWidth = 1.5;
          icon = Icons.check_outlined;
          iconColor = cs.onPrimaryContainer;
          textColor = cs.onPrimaryContainer;
        } else if (slot.isMaintenance) {
          final isDark =
              Theme.of(context).brightness ==
              Brightness.dark;
          chipBg = isDark
              ? Colors.orange.withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.10);
          chipBorder = isDark
              ? Colors.orange.shade700
              : Colors.orange.shade300;
          borderWidth = 1;
          icon = Icons.build_circle_outlined;
          iconColor = isDark
              ? Colors.orange.shade300
              : Colors.orange.shade800;
          textColor = isDark
              ? Colors.orange.shade200
              : Colors.orange.shade900;
        } else if (isAvail) {
          chipBg = cs.surfaceContainer;
          chipBorder = cs.outlineVariant;
          borderWidth = 1;
          icon = Icons.access_time_outlined;
          iconColor = cs.onSurfaceVariant;
          textColor = cs.onSurface;
        } else {
          chipBg = cs.surfaceContainerLow
              .withValues(alpha: 0.5);
          chipBorder = cs.outlineVariant
              .withValues(alpha: 0.4);
          borderWidth = 1;
          icon = Icons.block_outlined;
          iconColor = cs.outline.withValues(alpha: 0.6);
          textColor = cs.outline;
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
          child: AnimatedScale(
            scale: isSelected ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: chipBorder,
                  width: borderWidth,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: iconColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppDateUtils.formatTime(
                        slot.startTime,
                      ),
                      style: TextStyle(color: textColor),
                    ).mono().small(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurationSelector(int slotMinutes) {
    return SlideFadeSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(
        key: const ValueKey('duration'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Duration').h3(),
            const SizedBox(height: 12),
            SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (index) {
                  final durationUnits = index + 1;
                  final durationMinutes =
                      durationUnits * slotMinutes;
                  final isSelected =
                      _selectedDurationSlots ==
                      durationUnits;

                  String durationLabel;
                  if (durationMinutes < 60) {
                    durationLabel =
                        '$durationMinutes mins';
                  } else if (durationMinutes % 1440 == 0) {
                    final days = durationMinutes ~/ 1440;
                    durationLabel =
                        '$days ${days == 1 ? 'day' : 'days'}';
                  } else if (durationMinutes % 60 == 0) {
                    durationLabel =
                        '${durationMinutes ~/ 60} ${durationMinutes == 60 ? 'hour' : 'hours'}';
                  } else {
                    durationLabel =
                        '${(durationMinutes / 60).toStringAsFixed(1)} hours';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDurationSlots =
                              durationUnits;
                          _errorMessage = null;
                        });
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.06 : 1.0,
                        duration: const Duration(
                          milliseconds: 280,
                        ),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 240,
                          ),
                          curve: Curves.easeOutCubic,
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            durationLabel,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context)
                                        .colorScheme
                                        .onPrimary
                                  : null,
                            ),
                          ).small().semiBold(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return SlideFadeSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: const ValueKey('error-msg'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ).small(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(
      availabilityProvider(
        AvailabilityParams(
          groupId: widget.groupId,
          resourceId: widget.resourceId,
          date: _selectedDateString,
          excludeBookingId: widget.reschedulingBooking?.id,
        ),
      ),
    );

    final availability = availabilityAsync.valueOrNull;
    final slotDuration = availability?.slotDurationMinutes ?? 60;
    final isDaySlot = slotDuration >= 1440 && slotDuration % 1440 == 0;
    final allSlots = availability?.slots ?? [];
    final effectiveSelectedSlot = isDaySlot
        ? (allSlots.isNotEmpty ? allSlots.first : null)
        : _selectedStartTimeSlot;
    final requestedSlots = _calculateRequestedSlots(
      allSlots,
      selectedSlot: effectiveSelectedSlot,
      slotDurationMinutes: slotDuration,
    );
    final isValid = _isRangeValid(requestedSlots, isDaySlot: isDaySlot);
    final showSummary =
        effectiveSelectedSlot != null && requestedSlots.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.reschedulingBooking != null) ...[
                  _buildReschedulingBanner(),
                  const SizedBox(height: 16),
                ],

                // 1. Date Strip & Calendar Picker Launcher
                _buildDateHeader(),
                const SizedBox(height: 12),

                // Horizontal Quick Date Chips (7 days)
                _buildDateChips(),
                const SizedBox(height: 20),

                // 2. Availability Content (User Stats, Operating Hours, Slots, Duration, Error)
                SlideFadeSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: availabilityAsync.when(
                    loading: () => const KeyedSubtree(
                      key: ValueKey('availability-loading'),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (err, _) => KeyedSubtree(
                      key: const ValueKey('availability-error'),
                      child: ErrorDisplay(
                        error: err.toString(),
                        onRetry: () => ref.invalidate(
                          availabilityProvider(
                            AvailabilityParams(
                              groupId: widget.groupId,
                              resourceId: widget.resourceId,
                              date: _selectedDateString,
                              excludeBookingId: widget.reschedulingBooking?.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                    data: (availability) {
                      final daySlotDuration = availability.slotDurationMinutes;
                      final isResourceDaySlot =
                          daySlotDuration >= 1440 && daySlotDuration % 1440 == 0;
                      final from = availability.availableFrom ?? '00:00';
                      final until = availability.availableUntil ?? '24:00';
                      final hasWorkingHours =
                          (from != '00:00' || until != '24:00');
                      final daySlots = availability.slots;
                      final selectedSlot = isResourceDaySlot
                          ? (daySlots.isNotEmpty ? daySlots.first : null)
                          : _selectedStartTimeSlot;

                      return KeyedSubtree(
                        key: ValueKey('availability-data-$_selectedDateString'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserStatsCard(availability.userStats),
                            const SizedBox(height: 14),
                            if (!isResourceDaySlot) ...[
                              const Text('Select Start Time').h3(),
                              const SizedBox(height: 4),
                              _buildOperatingHoursBanner(availability),
                              const SizedBox(height: 8),
                              _buildTimeSlotGrid(availability),
                              const SizedBox(height: 24),
                            ] else ...[
                              if (hasWorkingHours) ...[
                                _buildOperatingHoursBanner(availability),
                                const SizedBox(height: 16),
                              ],
                              if (daySlots.isEmpty)
                                _buildNoSlotsMessage(availability)
                              else if (!daySlots.first.isAvailable) ...[
                                if (daySlots.first.isMaintenance)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.orange.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.orange.shade700
                                            : Colors.orange.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.build_circle_outlined,
                                          size: 16,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.orange.shade300
                                              : Colors.orange.shade800,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Resource is under scheduled maintenance on this date.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.orange.shade200
                                                  : Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (daySlots.first.isFull)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.block_outlined,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This date is fully booked.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                              ],
                            ],
                            if (selectedSlot != null)
                              _buildDurationSelector(
                                availability.slotDurationMinutes,
                              ),
                            if (_errorMessage != null) _buildErrorMessage(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SlideFadeSwitcher(
          duration: const Duration(milliseconds: 350),
          child: showSummary
              ? KeyedSubtree(
                  key: const ValueKey('summary'),
                  child: _buildBottomBar(
                    isValid: isValid,
                    requestedSlots: requestedSlots,
                    isDaySlot: isDaySlot,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-summary')),
        ),
      ],
    );
  }
}
