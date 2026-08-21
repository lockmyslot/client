class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String displayName;
  final String role;
  final DateTime joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return GroupMember(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? json['groupId'] as String? ?? '',
      userId: json['user_id'] as String? ?? userMap?['id'] as String? ?? '',
      displayName:
          json['display_name'] as String? ??
          userMap?['display_name'] as String? ??
          json['displayName'] as String? ??
          'User',
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'display_name': displayName,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
