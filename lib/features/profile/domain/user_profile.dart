class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final int credits;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    required this.credits,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      credits: json['credits'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'credits': credits,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    int? credits,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
