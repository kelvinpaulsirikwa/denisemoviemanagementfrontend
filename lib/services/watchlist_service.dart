import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/movie_model.dart';
import '../services/auth_service.dart';
import '../utils/api_logger.dart';

class WatchlistService {
  static const String _watchlistBase = '${ApiConfig.baseUrl}/watchlist';

  static Future<Map<String, String>> _getAuthHeaders() async {
    final user = await AuthService.getCurrentUser();
    final headers = {'Content-Type': 'application/json'};
    
    if (user != null && user.token != null) {
      headers['Authorization'] = 'Bearer ${user.token}';
    }
    
    return headers;
  }

  static Future<WatchlistResponse> addToWatchlist(int movieId) async {
    final headers = await _getAuthHeaders();
    final body = jsonEncode({
      'movie_id': movieId,
    });

    ApiLogger.logRequest('POST', '$_watchlistBase/add', headers: headers, body: body);

    try {
      final response = await http.post(
        Uri.parse('$_watchlistBase/add'),
        headers: headers,
        body: body,
      );

      ApiLogger.logResponse(response);

    if (response.statusCode == 200) {
      return WatchlistResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated');
    } else if (response.statusCode == 404) {
      throw Exception('Movie not found');
    } else if (response.statusCode == 409) {
      throw Exception('Movie already in watchlist');
    } else if (response.statusCode == 422) {
      throw Exception('Validation errors');
    } else {
      throw Exception('Failed to add to watchlist: ${response.statusCode}');
    }
    } catch (e) {
      ApiLogger.logError('POST', '$_watchlistBase/add', e);
      rethrow;
    }
  }

  static Future<WatchlistResponse> removeFromWatchlist(int movieId) async {
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('DELETE', '$_watchlistBase/$movieId', headers: headers);

    try {
      final response = await http.delete(
        Uri.parse('$_watchlistBase/$movieId'),
        headers: headers,
      );

      ApiLogger.logResponse(response);

    if (response.statusCode == 200) {
      return WatchlistResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated');
    } else if (response.statusCode == 404) {
      throw Exception('Movie not found in watchlist');
    } else {
      throw Exception('Failed to remove from watchlist: ${response.statusCode}');
    }
    } catch (e) {
      ApiLogger.logError('DELETE', '$_watchlistBase/$movieId', e);
      rethrow;
    }
  }

  static Future<WatchlistCheckResponse> checkWatchlist(int movieId) async {
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', '$_watchlistBase/check/$movieId', headers: headers);

    try {
      final response = await http.get(
        Uri.parse('$_watchlistBase/check/$movieId'),
        headers: headers,
      );

      ApiLogger.logResponse(response);

    if (response.statusCode == 200) {
      return WatchlistCheckResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated');
    } else {
      throw Exception('Failed to check watchlist: ${response.statusCode}');
    }
    } catch (e) {
      ApiLogger.logError('GET', '$_watchlistBase/check/$movieId', e);
      rethrow;
    }
  }

  static Future<UserWatchlistResponse> getUserWatchlist({
    int page = 1,
    int perPage = 20,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort': sort,
      'order': order,
    };

    final uri = Uri.parse(_watchlistBase)
        .replace(queryParameters: queryParams);

    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);

      ApiLogger.logResponse(response);

    if (response.statusCode == 200) {
      return UserWatchlistResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthenticated');
    } else {
      throw Exception('Failed to load watchlist: ${response.statusCode}');
    }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }
}
