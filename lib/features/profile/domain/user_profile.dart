class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? role;
  final String? folderId;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final int credits;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.role,
    this.folderId,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.credits = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      folderId: json['folderId'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      credits: json['credits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'folderId': folderId,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    }
    return username;
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? folderId,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    int? credits,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      folderId: folderId ?? this.folderId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      credits: credits ?? this.credits,
    );
  }
}
