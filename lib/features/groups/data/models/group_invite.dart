class GroupInvite {
  final String id;
  final String groupId;
  final String groupName;
  final String? invitedById;
  final String? invitedByName;
  final String? invitedByUsername;
  final String role;
  final DateTime? expiresAt;
  final String status;
  final DateTime createdAt;

  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.invitedById,
    this.invitedByName,
    this.invitedByUsername,
    this.role = 'GUEST',
    this.expiresAt,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isModerator => role.toUpperCase() == 'MODERATOR';
  bool get isMember => role.toUpperCase() == 'MEMBER';
  bool get isGuest => role.toUpperCase() == 'GUEST';
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    DateTime? parsedExpiresAt;
    final rawExpiresAt = json['expires_at'] ?? json['expiresAt'];
    if (rawExpiresAt != null && rawExpiresAt is String) {
      parsedExpiresAt = DateTime.tryParse(rawExpiresAt);
    }

    return GroupInvite(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? json['groupId'] as String? ?? '',
      groupName: json['group_name'] as String? ??
          json['groupName'] as String? ??
          'Group',
      invitedById: json['invited_by_id'] as String? ??
          json['invitedById'] as String?,
      invitedByName: json['invited_by_name'] as String? ??
          json['invitedByName'] as String?,
      invitedByUsername: json['invited_by_username'] as String? ??
          json['invitedByUsername'] as String?,
      role: json['role'] as String? ?? 'GUEST',
      expiresAt: parsedExpiresAt,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'group_name': groupName,
      if (invitedById != null) 'invited_by_id': invitedById,
      if (invitedByName != null) 'invited_by_name': invitedByName,
      if (invitedByUsername != null) 'invited_by_username': invitedByUsername,
      'role': role,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
