class Resource {
  final String id;
  final String groupId;
  final String name;
  final String? description;
  final int capacity;
  final int slotDurationMinutes;
  final bool isActive;
  final bool rulesConfigured;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Resource({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.capacity,
    required this.slotDurationMinutes,
    required this.isActive,
    this.rulesConfigured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? json['groupId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      capacity: json['capacity'] as int? ?? 1,
      slotDurationMinutes:
          json['slot_duration_minutes'] as int? ??
          json['slotDurationMinutes'] as int? ??
          60,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      rulesConfigured:
          json['rules_configured'] as bool? ??
          json['rulesConfigured'] as bool? ??
          false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      if (description != null) 'description': description,
      'capacity': capacity,
      'slot_duration_minutes': slotDurationMinutes,
      'is_active': isActive,
      'rules_configured': rulesConfigured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
