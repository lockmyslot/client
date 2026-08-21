import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _displayDateFormat = DateFormat('EEE, MMM d, yyyy');
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
}
