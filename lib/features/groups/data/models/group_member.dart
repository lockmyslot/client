class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String displayName;
  final String? username;
  final String role;
  final DateTime? expiresAt;
  final DateTime joinedAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.displayName,
    this.username,
    required this.role,
    this.expiresAt,
    required this.joinedAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isGuest => role.toUpperCase() == 'GUEST';
  bool get isMod =>
      role.toUpperCase() == 'MOD' || role.toUpperCase() == 'MODERATOR';
  bool get isModerator => isMod;
  bool get isMember => role.toUpperCase() == 'MEMBER';
  bool get isExpired =>
      isGuest && expiresAt != null && DateTime.now().isAfter(expiresAt!);

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? displayName,
    String? username,
    String? role,
    DateTime? expiresAt,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      role: role ?? this.role,
      expiresAt: expiresAt ?? this.expiresAt,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final resolvedUserId = json['user_id'] as String? ??
        json['userId'] as String? ??
        userMap?['id'] as String? ??
        userMap?['user_id'] as String? ??
        userMap?['userId'] as String? ??
        json['id'] as String? ??
        '';
    return GroupMember(
      id: json['id'] as String? ?? resolvedUserId,
      groupId: json['group_id'] as String? ?? json['groupId'] as String? ?? '',
      userId: resolvedUserId,
      displayName: json['display_name'] as String? ??
          userMap?['display_name'] as String? ??
          json['displayName'] as String? ??
          userMap?['displayName'] as String? ??
          'User',
      username:
          json['username'] as String? ??
          userMap?['username'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'] as String)
              : null,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : (json['joinedAt'] != null
              ? DateTime.parse(json['joinedAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'display_name': displayName,
      if (username != null) 'username': username,
      'role': role,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
