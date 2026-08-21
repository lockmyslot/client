class Booking {
  final String id;
  final String resourceId;
  final String? resourceName;
  final String userId;
  final String? userDisplayName;
  final String groupId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.resourceId,
    this.resourceName,
    required this.userId,
    this.userDisplayName,
    required this.groupId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
  });

  bool get isConfirmed => status.toUpperCase() == 'CONFIRMED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  factory Booking.fromJson(Map<String, dynamic> json) {
    final resourceMap = json['resource'] as Map<String, dynamic>?;
    final userMap = json['user'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      resourceId:
          json['resource_id'] as String? ?? json['resourceId'] as String? ?? '',
      resourceName:
          json['resource_name'] as String? ?? resourceMap?['name'] as String?,
      userId:
          json['user_id'] as String? ??
          json['userId'] as String? ??
          userMap?['id'] as String? ??
          '',
      userDisplayName:
          json['user_display_name'] as String? ??
          userMap?['display_name'] as String? ??
          json['userDisplayName'] as String?,
      groupId: json['group_id'] as String? ?? json['groupId'] as String? ?? '',
      startTime: DateTime.parse(
        json['start_time'] as String? ?? json['startTime'] as String,
      ),
      endTime: DateTime.parse(
        json['end_time'] as String? ?? json['endTime'] as String,
      ),
      status: json['status'] as String? ?? 'CONFIRMED',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resource_id': resourceId,
      if (resourceName != null) 'resource_name': resourceName,
      'user_id': userId,
      if (userDisplayName != null) 'user_display_name': userDisplayName,
      'group_id': groupId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
