class Group {
  final String id;
  final String name;
  final String? inviteCode;
  final String role; // "ADMIN" | "MEMBER"
  final int memberCount;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    this.inviteCode,
    required this.role,
    required this.memberCount,
    required this.createdAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

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
    };
  }
}
