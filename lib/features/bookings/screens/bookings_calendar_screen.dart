import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookings_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/connected_list.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  Widget _buildDateHeader() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SlideFadeSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            AppDateUtils.formatDisplayDate(_selectedDate),
            key: ValueKey('date-header-$_selectedDateString'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: _pickCalendarDate,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: cs.surfaceContainerHigh,
            foregroundColor: cs.onSurface,
          ),
          icon: const Icon(Icons.calendar_month_outlined, size: 16),
          label: const Text('Change Date'),
        ),
      ],
    );
  }

  Widget _buildDateChips() {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      clipBehavior: Clip.none,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = AppDateUtils.isSameDay(date, _selectedDate);
          final isToday = index == 0;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onDateSelected(date),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedScale(
                  scale: isSelected ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.formatWeekday(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary.withValues(alpha: 0.2)
                                : (isToday
                                    ? cs.primary.withValues(alpha: 0.12)
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isToday ? 'Today' : AppDateUtils.formatShortDate(date),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? cs.onPrimaryContainer
                                  : (isToday ? cs.primary : cs.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final resourceAsync = ref.watch(
      resourceDetailProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
      )),
    );

    final bookingsAsync = ref.watch(
      resourceBookingsProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
        date: _selectedDateString,
      )),
    );

    final titleText = resourceAsync.maybeWhen(
      data: (r) => '${r.name} Bookings',
      orElse: () => 'Resource Bookings',
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          M3CollapsingAppBar(
            title: Text(titleText),
            pinned: true,
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              resourceBookingsProvider((
                groupId: widget.groupId,
                resourceId: widget.resourceId,
                date: _selectedDateString,
              )),
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Date Header & Change Date CTA
              _buildDateHeader(),
              const SizedBox(height: 12),

              // 7-Day Date Carousel
              _buildDateChips(),
              const SizedBox(height: 24),

              // Bookings Content
              SlideFadeSwitcher(
                child: bookingsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => ErrorDisplay(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(
                      resourceBookingsProvider((
                        groupId: widget.groupId,
                        resourceId: widget.resourceId,
                        date: _selectedDateString,
                      )),
                    ),
                  ),
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'No Bookings',
                          description:
                              'No bookings scheduled for ${AppDateUtils.formatDisplayDate(_selectedDate)}.',
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled Bookings (${bookings.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConnectedListSection(
                          itemCount: bookings.length,
                          itemBuilder: (context, index, borderRadius) {
                            final booking = bookings[index];
                            final duration =
                                booking.endTime.difference(booking.startTime);
                            final durationText =
                                AppDateUtils.formatDuration(duration);
                            final userName = (booking.userDisplayName != null &&
                                    booking.userDisplayName!.trim().isNotEmpty)
                                ? booking.userDisplayName!
                                : 'User';

                            final timeDisplay =
                                '${AppDateUtils.formatTime(booking.startTime)} – ${AppDateUtils.formatTime(booking.endTime)}';

                            return ConnectedCard(
                              borderRadius: borderRadius,
                              color: cs.surfaceContainer,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                            timeDisplay,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'Confirmed',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: cs.primaryContainer,
                                          child: Text(
                                            userName.isNotEmpty
                                                ? userName[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: cs.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            userName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: cs.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHigh,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            durationText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
