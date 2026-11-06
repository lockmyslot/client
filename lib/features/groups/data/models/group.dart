class Group {
  final String id;
  final String name;
  final String? inviteCode;
  final String? color;
  final String? icon;
  final String role; // "ADMIN" | "MODERATOR" | "MEMBER" | "GUEST"
  final DateTime? expiresAt;
  final int memberCount;
  final DateTime createdAt;
  final bool isPinned;

  const Group({
    required this.id,
    required this.name,
    this.inviteCode,
    this.color,
    this.icon,
    required this.role,
    this.expiresAt,
    required this.memberCount,
    required this.createdAt,
    this.isPinned = false,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isGuest => role.toUpperCase() == 'GUEST';
  bool get isMod =>
      role.toUpperCase() == 'MOD' || role.toUpperCase() == 'MODERATOR';
  bool get isModerator => isMod;
  bool get isMember => role.toUpperCase() == 'MEMBER';
  bool get isExpired =>
      isGuest && expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Group copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? color,
    String? icon,
    String? role,
    DateTime? expiresAt,
    int? memberCount,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      role: role ?? this.role,
      expiresAt: expiresAt ?? this.expiresAt,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      inviteCode:
          json['invite_code'] as String? ?? json['inviteCode'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'] as String)
              : null,
      memberCount:
          json['member_count'] as int? ?? json['memberCount'] as int? ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isPinned:
          json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      'role': role,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'is_pinned': isPinned,
    };
  }
}
