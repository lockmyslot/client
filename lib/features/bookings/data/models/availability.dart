class Availability {
  final String date;
  final String resourceId;
  final int slotDurationMinutes;
  final String? availableFrom;
  final String? availableUntil;
  final UserStats userStats;
  final List<TimeSlot> slots;

  const Availability({
    required this.date,
    required this.resourceId,
    required this.slotDurationMinutes,
    this.availableFrom,
    this.availableUntil,
    required this.userStats,
    required this.slots,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      date: json['date'] as String? ?? '',
      resourceId:
          json['resource_id'] as String? ?? json['resourceId'] as String? ?? '',
      slotDurationMinutes:
          json['slot_duration_minutes'] as int? ??
          json['slotDurationMinutes'] as int? ??
          60,
      availableFrom:
          json['available_from'] as String? ?? json['availableFrom'] as String?,
      availableUntil:
          json['available_until'] as String? ??
          json['availableUntil'] as String?,
      userStats: json['user_stats'] != null
          ? UserStats.fromJson(json['user_stats'] as Map<String, dynamic>)
          : json['userStats'] != null
          ? UserStats.fromJson(json['userStats'] as Map<String, dynamic>)
          : const UserStats(bookingsToday: 0, hoursToday: 0.0),
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final String status; // "available" | "full" | "cooldown" | "unavailable"
  final int booked;
  final int capacity;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.booked,
    required this.capacity,
  });

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isFull => status.toLowerCase() == 'full';
  bool get isCooldown => status.toLowerCase() == 'cooldown';
  bool get isUnavailable => status.toLowerCase() == 'unavailable';

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: DateTime.parse(
        json['start_time'] as String? ?? json['startTime'] as String,
      ),
      endTime: DateTime.parse(
        json['end_time'] as String? ?? json['endTime'] as String,
      ),
      status: json['status'] as String? ?? 'available',
      booked: json['booked'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 1,
    );
  }
}

class UserStats {
  final int bookingsToday;
  final double hoursToday;
  final int? maxBookingsPerDay;
  final int? maxHoursPerDay;
  final int? cooldownMinutes;
  final DateTime? lastBookingEnd;

  const UserStats({
    required this.bookingsToday,
    required this.hoursToday,
    this.maxBookingsPerDay,
    this.maxHoursPerDay,
    this.cooldownMinutes,
    this.lastBookingEnd,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      bookingsToday:
          json['bookings_today'] as int? ?? json['bookingsToday'] as int? ?? 0,
      hoursToday:
          (json['hours_today'] as num?)?.toDouble() ??
          (json['hoursToday'] as num?)?.toDouble() ??
          0.0,
      maxBookingsPerDay:
          json['max_bookings_per_day'] as int? ??
          json['maxBookingsPerDay'] as int?,
      maxHoursPerDay:
          json['max_hours_per_day'] as int? ?? json['maxHoursPerDay'] as int?,
      cooldownMinutes:
          json['cooldown_minutes'] as int? ?? json['cooldownMinutes'] as int?,
      lastBookingEnd: json['last_booking_end'] != null
          ? DateTime.parse(json['last_booking_end'] as String)
          : null,
    );
  }
}
