import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _displayDateFormat = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _weekdayFormat = DateFormat('EEE');
  static final DateFormat _displayTimeFormat = DateFormat('h:mm a');
  static final DateFormat _displayDateTimeFormat = DateFormat('MMM d, h:mm a');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatTimeString(String? time) {
    if (time == null || time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return time;
    if (hour == 24) return '12:00 AM';
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String formatDisplayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  static String formatWeekday(DateTime date) {
    return _weekdayFormat.format(date);
  }

  static String formatDisplayTime(DateTime date) {
    return _displayTimeFormat.format(date);
  }

  static String formatDisplayDateTime(DateTime date) {
    return _displayDateTimeFormat.format(date);
  }

  static String formatISO(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  static DateTime parseISO(String isoString) {
    return DateTime.parse(isoString).toLocal();
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isInCurrentOrUpcomingWeek(
    DateTime date, [
    DateTime? referenceDate,
  ]) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final mondayStart = today.subtract(Duration(days: now.weekday - 1));
    final sundayStart = today.subtract(Duration(days: now.weekday % 7));
    final earliestWeekStart =
        mondayStart.isBefore(sundayStart) ? mondayStart : sundayStart;

    if (target.isBefore(earliestWeekStart)) return false;

    final mondayUpcomingEnd = mondayStart.add(const Duration(days: 13));
    final sundayUpcomingEnd = sundayStart.add(const Duration(days: 14));
    final latestUpcomingEnd =
        mondayUpcomingEnd.isAfter(sundayUpcomingEnd)
            ? mondayUpcomingEnd
            : sundayUpcomingEnd;

    return !target.isAfter(latestUpcomingEnd);
  }

  static String formatBookingHeader(
    DateTime dateTime, [
    DateTime? referenceDate,
  ]) {
    final timeStr = dateTime.minute == 0
        ? DateFormat('h a').format(dateTime)
        : DateFormat('h:mm a').format(dateTime);

    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayPrefix;
    if (target.isAtSameMomentAs(today)) {
      dayPrefix = 'Today';
    } else if (target.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dayPrefix = 'Tomorrow';
    } else if (isInCurrentOrUpcomingWeek(dateTime, referenceDate)) {
      dayPrefix = DateFormat('EEEE').format(dateTime);
    } else {
      final datePattern = dateTime.year == now.year ? 'MMM d' : 'MMM d, yyyy';
      dayPrefix = DateFormat(datePattern).format(dateTime);
    }

    return '$dayPrefix, $timeStr';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}

