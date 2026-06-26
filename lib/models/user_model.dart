class UserModel {
  final String username;
  final String password; // In production, this should be hashed
  final String email;
  final String? bio;
  final DateTime createdAt;

  UserModel({
    required this.username,
    required this.password,
    required this.email,
    this.bio,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password, // In production, store hashed password
      'email': email,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      password: json['password'],
      email: json['email'],
      bio: json['bio'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  UserModel copyWith({
    String? username,
    String? password,
    String? email,
    String? bio,
    DateTime? createdAt,
  }) {
    return UserModel(
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

