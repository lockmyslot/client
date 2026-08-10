class User {
  final String id;
  final String displayName;
  final String? authToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.displayName,
    this.authToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? '',
      authToken: json['auth_token'] as String? ?? json['authToken'] as String?,
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
      'display_name': displayName,
      if (authToken != null) 'auth_token': authToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
