class BookingRule {
  final String? id;
  final String dayScope;
  final int? maxBookingsPerDay;
  final int? maxHoursPerDay;
  final int? cooldownMinutes;
  final int? minDurationMinutes;
  final int? maxDurationMinutes;
  final int? maxAdvanceBookingDays;
  final String? availableFrom;
  final String? availableUntil;

  const BookingRule({
    this.id,
    required this.dayScope,
    this.maxBookingsPerDay,
    this.maxHoursPerDay,
    this.cooldownMinutes,
    this.minDurationMinutes,
    this.maxDurationMinutes,
    this.maxAdvanceBookingDays,
    this.availableFrom,
    this.availableUntil,
  });

  factory BookingRule.fromJson(Map<String, dynamic> json) {
    return BookingRule(
      id: json['id'] as String?,
      dayScope: json['day_scope'] as String? ?? json['dayScope'] as String? ?? 'WEEKDAY',
      maxBookingsPerDay: json['max_bookings_per_day'] as int? ?? json['maxBookingsPerDay'] as int?,
      maxHoursPerDay: json['max_hours_per_day'] as int? ?? json['maxHoursPerDay'] as int?,
      cooldownMinutes: json['cooldown_minutes'] as int? ?? json['cooldownMinutes'] as int?,
      minDurationMinutes: json['min_duration_minutes'] as int? ?? json['minDurationMinutes'] as int?,
      maxDurationMinutes: json['max_duration_minutes'] as int? ?? json['maxDurationMinutes'] as int?,
      maxAdvanceBookingDays: json['max_advance_booking_days'] as int? ?? json['maxAdvanceBookingDays'] as int?,
      availableFrom: json['available_from'] as String? ?? json['availableFrom'] as String?,
      availableUntil: json['available_until'] as String? ?? json['availableUntil'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'day_scope': dayScope,
    };
    if (id != null) map['id'] = id;
    if (maxBookingsPerDay != null) map['max_bookings_per_day'] = maxBookingsPerDay;
    if (maxHoursPerDay != null) map['max_hours_per_day'] = maxHoursPerDay;
    if (cooldownMinutes != null) map['cooldown_minutes'] = cooldownMinutes;
    if (minDurationMinutes != null) map['min_duration_minutes'] = minDurationMinutes;
    if (maxDurationMinutes != null) map['max_duration_minutes'] = maxDurationMinutes;
    if (maxAdvanceBookingDays != null) map['max_advance_booking_days'] = maxAdvanceBookingDays;
    if (availableFrom != null) map['available_from'] = availableFrom;
    if (availableUntil != null) map['available_until'] = availableUntil;
    return map;
  }
}
