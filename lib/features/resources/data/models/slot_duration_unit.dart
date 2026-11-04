enum SlotDurationUnit {
  minutes('Minutes'),
  hours('Hours'),
  days('Days');

  final String label;
  const SlotDurationUnit(this.label);

  static ({SlotDurationUnit unit, int value}) parseMinutes(int minutes) {
    if (minutes >= 1440 && minutes % 1440 == 0) {
      return (unit: SlotDurationUnit.days, value: minutes ~/ 1440);
    } else if (minutes > 60 && minutes % 60 == 0) {
      return (unit: SlotDurationUnit.hours, value: minutes ~/ 60);
    } else if (minutes == 60) {
      return (unit: SlotDurationUnit.minutes, value: 60);
    } else {
      return (unit: SlotDurationUnit.minutes, value: minutes);
    }
  }

  static int toMinutes(int value, SlotDurationUnit unit) {
    switch (unit) {
      case SlotDurationUnit.minutes:
        return value;
      case SlotDurationUnit.hours:
        return value * 60;
      case SlotDurationUnit.days:
        return value * 1440;
    }
  }

  static int convertValue(
    int value,
    SlotDurationUnit from,
    SlotDurationUnit to,
  ) {
    if (from == to) return value;
    final totalMinutes = toMinutes(value, from);
    switch (to) {
      case SlotDurationUnit.minutes:
        return totalMinutes;
      case SlotDurationUnit.hours:
        return (totalMinutes / 60).round().clamp(1, 720);
      case SlotDurationUnit.days:
        return (totalMinutes / 1440).round().clamp(1, 30);
    }
  }

  static String? validate(String? text, SlotDurationUnit unit) {
    if (text == null || text.trim().isEmpty) {
      return 'Required';
    }
    final num = int.tryParse(text.trim());
    if (num == null || num <= 0) {
      return 'Must be > 0';
    }
    switch (unit) {
      case SlotDurationUnit.minutes:
        if (num < 15 || num > 43200) {
          return '15 to 43200 mins';
        }
        if (num % 15 != 0) {
          return 'Multiple of 15';
        }
        break;
      case SlotDurationUnit.hours:
        if (num < 1 || num > 720) {
          return '1 to 720 hours';
        }
        break;
      case SlotDurationUnit.days:
        if (num < 1 || num > 30) {
          return '1 to 30 days';
        }
        break;
    }
    return null;
  }
}
