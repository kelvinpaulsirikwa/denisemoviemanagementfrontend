import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/api_logger.dart';
import '../services/auth_service.dart';

class UserService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final user = await AuthService.getCurrentUser();
    final headers = {'Content-Type': 'application/json'};
    
    if (user != null && user.token != null) {
      headers['Authorization'] = 'Bearer ${user.token}';
    }
    
    return headers;
  }
  static Future<UserProfileResponse> getUserProfile(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return UserProfileResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthenticated');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<UserUpdateResponse> updateUserProfile(
    int userId, {
    required String username,
    required String useremail,
    String? userimagedp,
    String? dateTimestample,
    String? createdAt,
  }) async {
    final requestBody = {
      'username': username,
      'useremail': useremail,
      'userimagedp': userimagedp,
      'date_timestample': dateTimestample ?? DateTime.now().toIso8601String(),
      'createdat': createdAt ?? DateTime.now().toIso8601String(),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
    final body = jsonEncode(requestBody);
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('PUT', uri.toString(), headers: headers, body: body);

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: body,
      );
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return UserUpdateResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthenticated');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else if (response.statusCode == 422) {
        throw Exception('Validation errors');
      } else {
        throw Exception('Failed to update user profile: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('PUT', uri.toString(), e);
      rethrow;
    }
  }

  static Future<UserDeleteResponse> deleteUserAccount(int userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('DELETE', uri.toString(), headers: headers);

    try {
      final response = await http.delete(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return UserDeleteResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Unauthenticated');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to delete user account: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('DELETE', uri.toString(), e);
      rethrow;
    }
  }
}
