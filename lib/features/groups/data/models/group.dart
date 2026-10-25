class Group {
  final String id;
  final String name;
  final String? inviteCode;
  final String role; // "ADMIN" | "MEMBER"
  final int memberCount;
  final DateTime createdAt;
  final bool isPinned;

  const Group({
    required this.id,
    required this.name,
    this.inviteCode,
    required this.role,
    required this.memberCount,
    required this.createdAt,
    this.isPinned = false,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  Group copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? role,
    int? memberCount,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      role: role ?? this.role,
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
      role: json['role'] as String? ?? 'MEMBER',
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
      'role': role,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'is_pinned': isPinned,
    };
  }
}
