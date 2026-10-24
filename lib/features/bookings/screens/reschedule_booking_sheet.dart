import 'package:flutter/material.dart';
import '../data/models/booking.dart';
import '../widgets/booking_details_form.dart';
import '../../../core/ui/ui.dart';

class RescheduleBookingSheet extends StatelessWidget {
  final Booking booking;

  const RescheduleBookingSheet({super.key, required this.booking});

  static Future<bool?> show(
    BuildContext context, {
    required Booking booking,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RescheduleBookingSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reschedule Booking').h3(),
                      if (booking.resourceName != null) ...[
                        const SizedBox(height: 2),
                        Text(booking.resourceName!).small().muted(),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form content
          Flexible(
            child: BookingDetailsForm(
              groupId: booking.groupId,
              resourceId: booking.resourceId,
              reschedulingBooking: booking,
              onBookingSuccess: (updated) {
                Navigator.of(context).pop(true);
              },
            ),
          ),
        ],
      ),
    );
  }
}
