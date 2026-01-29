import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category_model.dart';
import '../models/studio_model.dart';
import '../models/movie_model.dart';
import '../models/movie_part_model.dart';
import '../models/trailer_model.dart';
import '../utils/api_logger.dart';
import '../services/auth_service.dart';

class MovieService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final user = await AuthService.getCurrentUser();
    final headers = {'Content-Type': 'application/json'};
    
    if (user != null && user.token != null) {
      headers['Authorization'] = 'Bearer ${user.token}';
      developer.log('=== AUTH DEBUG ===');
      developer.log('User found: ${user.userName}');
      developer.log('Token: ${user.token}');
      developer.log('Full Headers: $headers');
      developer.log('==================');
    } else {
      developer.log('=== AUTH DEBUG ===');
      developer.log('NO USER OR TOKEN FOUND');
      developer.log('User: $user');
      developer.log('==================');
    }
    
    return headers;
  }

  static Future<CategoryResponse> getCategories({
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    final uri = Uri.parse(ApiConfig.categoriesEndpoint).replace(queryParameters: queryParams);
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return CategoryResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<StudioResponse> getStudios({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse(ApiConfig.studiosEndpoint).replace(queryParameters: queryParams);
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return StudioResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load studios: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<CategorySingleResponse> getCategoryById(int id) async {
    final uri = Uri.parse('${ApiConfig.categoriesEndpoint}/$id');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return CategorySingleResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('Failed to load category: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<CategoryDetailResponse> getMoviesByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 20,
    String sort = 'title',
    String order = 'asc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort': sort,
      'order': order,
    };

    final uri = Uri.parse('${ApiConfig.categoriesEndpoint}/$categoryId/movies')
        .replace(queryParameters: queryParams);

    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return CategoryDetailResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<StudioSingleResponse> getStudioById(int id) async {
    final uri = Uri.parse('${ApiConfig.studiosEndpoint}/$id');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return StudioSingleResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Studio not found');
      } else {
        throw Exception('Failed to load studio: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<StudioDetailResponse> getMoviesByStudio(
    int studioId, {
    int page = 1,
    int perPage = 20,
    String sort = 'title',
    String order = 'asc',
    int? categoryId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort': sort,
      'order': order,
    };

    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }

    final uri = Uri.parse('${ApiConfig.studiosEndpoint}/$studioId/movies')
        .replace(queryParameters: queryParams);

    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return StudioDetailResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Studio not found');
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<MoviesResponse> getMovies({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    int? studioId,
    String sort = 'title',
    String order = 'asc',
    double? minRating,
    double? maxRating,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort': sort,
      'order': order,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (studioId != null) {
      queryParams['studio_id'] = studioId.toString();
    }
    if (minRating != null) {
      queryParams['min_rating'] = minRating.toString();
    }
    if (maxRating != null) {
      queryParams['max_rating'] = maxRating.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/movies')
        .replace(queryParameters: queryParams);
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return MoviesResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<MovieSingleResponse> getMovieById(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/movies/$id');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return MovieSingleResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Movie not found');
      } else {
        throw Exception('Failed to load movie: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<String> getMovieStream(int id, {String quality = '720p'}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stream/$id/video');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      // Just return the direct video URL with auth headers
      final videoUrl = '${ApiConfig.baseUrl}/stream/$id/video';
      
      // Test if the video exists
      final response = await http.head(uri, headers: headers);
      ApiLogger.logResponse(response);
      
      if (response.statusCode == 200 || response.statusCode == 206) {
        return videoUrl;
      } else if (response.statusCode == 404) {
        throw Exception('Video file not found');
      } else {
        throw Exception('Failed to access video: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<String> getHLSStream(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stream/$id/hls');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return response.body; // Return HLS playlist content
      } else if (response.statusCode == 404) {
        throw Exception('HLS playlist not found');
      } else {
        throw Exception('Failed to load HLS playlist: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  static Future<MovieSearchResponse> searchMovies(
    String query, {
    int page = 1,
    int perPage = 20,
    int? categoryId,
    int? studioId,
    String sort = 'relevance',
    String order = 'desc',
    double? minRating,
    double? maxRating,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort': sort,
      'order': order,
    };

    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (studioId != null) {
      queryParams['studio_id'] = studioId.toString();
    }
    if (minRating != null) {
      queryParams['min_rating'] = minRating.toString();
    }
    if (maxRating != null) {
      queryParams['max_rating'] = maxRating.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/movies/search')
        .replace(queryParameters: queryParams);

    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return MovieSearchResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 422) {
        throw Exception('Validation error - search query is required');
      } else {
        throw Exception('Failed to search movies: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  // Get movie parts/episodes
  static Future<MoviePartsResponse> getMovieParts(
    int movieId, {
    String? partType,
    String sortBy = 'part_number',
    String orderBy = 'asc',
  }) async {
    final queryParams = {
      'sort': sortBy,
      'order': orderBy,
    };
    
    if (partType != null && partType.isNotEmpty) {
      queryParams['part_type'] = partType;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/movies/$movieId/parts')
        .replace(queryParameters: queryParams);
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return MoviePartsResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Movie not found');
      } else if (response.statusCode == 422) {
        throw Exception('Validation error');
      } else {
        throw Exception('Failed to load movie parts: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  // Get movie trailer
  static Future<MovieTrailer> getMovieTrailer(int movieId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/movies/$movieId/trailer');
    final headers = await _getAuthHeaders();

    ApiLogger.logRequest('GET', uri.toString(), headers: headers);

    try {
      final response = await http.get(uri, headers: headers);
      ApiLogger.logResponse(response);

      if (response.statusCode == 200) {
        return MovieTrailer.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Movie not found or no trailer available');
      } else {
        throw Exception('Failed to load movie trailer: ${response.statusCode}');
      }
    } catch (e) {
      ApiLogger.logError('GET', uri.toString(), e);
      rethrow;
    }
  }
}
