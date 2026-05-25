// User & Profile Models
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? phone;
  final bool? isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.phone,
    this.isAdmin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      isAdmin: json['isAdmin'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'isAdmin': isAdmin,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// Auth Response Model
class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  AuthResponseModel({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['session']['access_token'] as String,
      refreshToken: json['session']['refresh_token'] as String?,
      expiresIn: json['session']['expires_in'] as int?,
    );
  }
}
