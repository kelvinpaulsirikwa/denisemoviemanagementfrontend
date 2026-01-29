class User {
  final String userEmail;
  final String userName;
  final String? userImageDp;
  final String dateTimeStamp;
  final String createdAt;
  final String? token;

  User({
    required this.userEmail,
    required this.userName,
    this.userImageDp,
    required this.dateTimeStamp,
    required this.createdAt,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userEmail: json['useremail'] ?? '',
      userName: json['username'] ?? '',
      userImageDp: json['userimagedp'],
      dateTimeStamp: json['date_timestample'] ?? '',
      createdAt: json['createdat'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useremail': userEmail,
      'username': userName,
      'userimagedp': userImageDp,
      'date_timestample': dateTimeStamp,
      'createdat': createdAt,
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
      success: json['success'] ?? false,
      user: User.fromJson(json['data'] ?? {}),
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
