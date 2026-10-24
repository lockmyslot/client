import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils - formatBookingHeader & schedule helpers', () {
    // Reference date: Saturday, Oct 24, 2026 at 10:00 AM
    final refDate = DateTime(2026, 10, 24, 10, 0);

    test('isInCurrentOrUpcomingWeek returns true for days in current or upcoming week', () {
      // Current week: Sat Oct 24 (today)
      expect(AppDateUtils.isInCurrentOrUpcomingWeek(DateTime(2026, 10, 24, 15, 0), refDate), isTrue);

      // Current week: Sun Oct 25 (tomorrow)
      expect(AppDateUtils.isInCurrentOrUpcomingWeek(DateTime(2026, 10, 25, 15, 0), refDate), isTrue);

      // Upcoming week: Mon Oct 26
      expect(AppDateUtils.isInCurrentOrUpcomingWeek(DateTime(2026, 10, 26, 9, 0), refDate), isTrue);

      // Upcoming week: Sun Nov 1
      expect(AppDateUtils.isInCurrentOrUpcomingWeek(DateTime(2026, 11, 1, 18, 0), refDate), isTrue);

      // Beyond upcoming week: Mon Nov 2
      expect(AppDateUtils.isInCurrentOrUpcomingWeek(DateTime(2026, 11, 2, 10, 0), refDate), isFalse);

      // Beyond upcoming week: Nov 15
      expect(AppDateUtils.isInCurrentOrUpcomingWeek(DateTime(2026, 11, 15, 15, 0), refDate), isFalse);
    });

    test('formatBookingHeader shows Today, Tomorrow, day name, and time for current/upcoming week', () {
      // Sat Oct 24 at 3:00 PM (today) -> "Today, 3 PM"
      final today3pm = DateTime(2026, 10, 24, 15, 0);
      expect(
        AppDateUtils.formatBookingHeader(today3pm, refDate),
        'Today, 3 PM',
      );

      // Sun Oct 25 at 3:00 PM (tomorrow) -> "Tomorrow, 3 PM"
      final tomorrow3pm = DateTime(2026, 10, 25, 15, 0);
      expect(
        AppDateUtils.formatBookingHeader(tomorrow3pm, refDate),
        'Tomorrow, 3 PM',
      );

      // Wednesday at 10:30 AM in upcoming week -> "Wednesday, 10:30 AM"
      final wed1030am = DateTime(2026, 10, 28, 10, 30);
      expect(
        AppDateUtils.formatBookingHeader(wed1030am, refDate),
        'Wednesday, 10:30 AM',
      );
    });

    test('formatBookingHeader shows date and time when outside current/upcoming week', () {
      // Nov 15 at 3:00 PM (same year) -> "Nov 15, 3 PM"
      final nov153pm = DateTime(2026, 11, 15, 15, 0);
      expect(
        AppDateUtils.formatBookingHeader(nov153pm, refDate),
        'Nov 15, 3 PM',
      );

      // Jan 10, 2027 at 3:00 PM (different year) -> "Jan 10, 2027, 3 PM"
      final jan10NextYear = DateTime(2027, 1, 10, 15, 0);
      expect(
        AppDateUtils.formatBookingHeader(jan10NextYear, refDate),
        'Jan 10, 2027, 3 PM',
      );
    });

    test('formatDuration formats hours and minutes properly', () {
      expect(AppDateUtils.formatDuration(const Duration(hours: 1)), '1h');
      expect(AppDateUtils.formatDuration(const Duration(hours: 2)), '2h');
      expect(AppDateUtils.formatDuration(const Duration(minutes: 30)), '30m');
      expect(AppDateUtils.formatDuration(const Duration(hours: 1, minutes: 30)), '1h 30m');
      expect(AppDateUtils.formatDuration(const Duration(minutes: 45)), '45m');
    });
  });
}
