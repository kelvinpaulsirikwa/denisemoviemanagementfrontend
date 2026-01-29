import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/api_logger.dart';

class AuthService {
  static const String _userKey = 'user_data';

  static Future<User> login(String email) async {
    final now = DateTime.now().toIso8601String();
    
    final requestBody = {
      'useremail': email,
      'username': email.split('@')[0], // Extract username from email
      'userimagedp': 'https://randomuser.me/api/portraits/men/32.jpg',
      'date_timestample': now,
      'createdat': now,
    };

    final url = ApiConfig.loginEndpoint;
    final body = jsonEncode(requestBody);
    final headers = {'Content-Type': 'application/json'};

    ApiLogger.logRequest('POST', url, headers: headers, body: body);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];
        
        // Create user with token from the response
        final user = User(
          userEmail: userData['user']['useremail'],
          userName: userData['user']['username'],
          userImageDp: userData['user']['userimagedp'],
          dateTimeStamp: userData['user']['date_timestample'],
          createdAt: userData['user']['createdat'],
          token: userData['token'], // Save the Bearer token
        );
        
        await _saveUserToPreferences(user);
        return user;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('POST', url, e);
      rethrow;
    }
  }

  static Future<void> _saveUserToPreferences(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
