import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _displayDateFormat = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _displayTimeFormat = DateFormat('h:mm a');
  static final DateFormat _displayDateTimeFormat = DateFormat('MMM d, h:mm a');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
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
