class User {
  final int id;
  final String userEmail;
  final String userName;
  final String? userImageDp;
  final String dateTimeStamp;
  final String createdAt;
  final String updatedAt;
  final String? token;

  User({
    required this.id,
    required this.userEmail,
    required this.userName,
    this.userImageDp,
    required this.dateTimeStamp,
    required this.createdAt,
    required this.updatedAt,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      userEmail: json['useremail'] ?? '',
      userName: json['username'] ?? '',
      userImageDp: json['userimagedp'],
      dateTimeStamp: json['date_timestample'] ?? '',
      createdAt: json['createdat'] ?? json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'useremail': userEmail,
      'username': userName,
      'userimagedp': userImageDp,
      'date_timestample': dateTimeStamp,
      'createdat': createdAt,
      'updated_at': updatedAt,
      'token': token,
    };
  }
}

class UserProfileResponse {
  final bool success;
  final User user;

  UserProfileResponse({
    required this.success,
    required this.user,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: true, // API returns 200 so it's successful
      user: User.fromJson(json), // User data is directly in the response
    );
  }
}

class UserUpdateResponse {
  final bool success;
  final String message;
  final User? user;

  UserUpdateResponse({
    required this.success,
    required this.message,
    this.user,
  });

  factory UserUpdateResponse.fromJson(Map<String, dynamic> json) {
    return UserUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['data'] != null ? User.fromJson(json['data']) : null,
    );
  }
}

class UserDeleteResponse {
  final bool success;
  final String message;

  UserDeleteResponse({
    required this.success,
    required this.message,
  });

  factory UserDeleteResponse.fromJson(Map<String, dynamic> json) {
    return UserDeleteResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
