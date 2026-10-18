class MaintenanceTask {
  final String id;
  final String resourceId;
  final String? resourceName;
  final String groupId;
  final String title;
  final String? description;
  final String status; // SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
  final String recurrenceType; // NONE, DAILY, WEEKLY
  final int? dayOfWeek; // 0=Sun, 1=Mon, ..., 6=Sat
  final String? startTimeOfDay;
  final String? endTimeOfDay;
  final DateTime startTime;
  final DateTime endTime;
  final String createdById;
  final String? createdByName;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? cancelledBookingsCount;

  const MaintenanceTask({
    required this.id,
    required this.resourceId,
    this.resourceName,
    required this.groupId,
    required this.title,
    this.description,
    required this.status,
    required this.recurrenceType,
    this.dayOfWeek,
    this.startTimeOfDay,
    this.endTimeOfDay,
    required this.startTime,
    required this.endTime,
    required this.createdById,
    this.createdByName,
    this.assignedToId,
    this.assignedToName,
    required this.createdAt,
    this.updatedAt,
    this.cancelledBookingsCount,
  });

  bool get isScheduled => status.toUpperCase() == 'SCHEDULED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  bool get isRecurring => recurrenceType.toUpperCase() != 'NONE';
  bool get isWeekly => recurrenceType.toUpperCase() == 'WEEKLY';
  bool get isDaily => recurrenceType.toUpperCase() == 'DAILY';

  String get dayOfWeekName {
    switch (dayOfWeek) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return '';
    }
  }

  String get recurrenceSummary {
    if (isWeekly) {
      final timeStr =
          (startTimeOfDay != null && endTimeOfDay != null)
              ? ' ($startTimeOfDay - $endTimeOfDay UTC)'
              : '';
      return 'Every $dayOfWeekName$timeStr';
    } else if (isDaily) {
      final timeStr =
          (startTimeOfDay != null && endTimeOfDay != null)
              ? ' ($startTimeOfDay - $endTimeOfDay UTC)'
              : '';
      return 'Every day$timeStr';
    }
    return 'One-off schedule';
  }

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] as String? ?? '',
      resourceId:
          json['resource_id'] as String? ?? json['resourceId'] as String? ?? '',
      resourceName:
          json['resource_name'] as String? ??
          json['resourceName'] as String?,
      groupId:
          json['group_id'] as String? ?? json['groupId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'SCHEDULED',
      recurrenceType:
          json['recurrence_type'] as String? ??
          json['recurrenceType'] as String? ??
          'NONE',
      dayOfWeek:
          json['day_of_week'] as int? ?? json['dayOfWeek'] as int?,
      startTimeOfDay:
          json['start_time_of_day'] as String? ??
          json['startTimeOfDay'] as String?,
      endTimeOfDay:
          json['end_time_of_day'] as String? ??
          json['endTimeOfDay'] as String?,
      startTime:
          json['start_time'] != null
              ? DateTime.parse(json['start_time'] as String)
              : (json['startTime'] != null
                  ? DateTime.parse(json['startTime'] as String)
                  : DateTime.now()),
      endTime:
          json['end_time'] != null
              ? DateTime.parse(json['end_time'] as String)
              : (json['endTime'] != null
                  ? DateTime.parse(json['endTime'] as String)
                  : DateTime.now()),
      createdById:
          json['created_by'] as String? ??
          json['created_by_id'] as String? ??
          json['createdById'] as String? ??
          '',
      createdByName:
          json['created_by_name'] as String? ??
          json['createdByName'] as String?,
      assignedToId:
          json['assigned_to_id'] as String? ??
          json['assignedToId'] as String? ??
          (json['assigned_to'] is Map
              ? (json['assigned_to'] as Map<String, dynamic>)['id'] as String?
              : null),
      assignedToName:
          json['assigned_to_name'] as String? ??
          json['assignedToName'] as String? ??
          (json['assigned_to'] is Map
              ? (json['assigned_to'] as Map<String, dynamic>)['display_name'] as String?
              : null),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'] as String)
                  : DateTime.now()),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : (json['updatedAt'] != null
                  ? DateTime.parse(json['updatedAt'] as String)
                  : null),
      cancelledBookingsCount:
          json['cancelled_bookings_count'] as int? ??
          json['cancelledBookingsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      if (resourceName != null) 'resource_name': resourceName,
      'group_id': groupId,
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      'recurrence_type': recurrenceType,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTimeOfDay != null) 'start_time_of_day': startTimeOfDay,
      if (endTimeOfDay != null) 'end_time_of_day': endTimeOfDay,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_by': createdById,
      if (createdByName != null) 'created_by_name': createdByName,
      if (assignedToId != null) 'assigned_to_id': assignedToId,
      if (assignedToName != null) 'assigned_to_name': assignedToName,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
