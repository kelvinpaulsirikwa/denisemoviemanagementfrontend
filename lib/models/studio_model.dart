import 'category_model.dart';
import 'movie_model.dart';

class Studio {
  final int id;
  final String name;
  final String description;
  final String email;
  final String phoneNumber;
  final String logo;
  final int ownerId;
  final String createdAt;
  final String updatedAt;

  Studio({
    required this.id,
    required this.name,
    required this.description,
    required this.email,
    required this.phoneNumber,
    required this.logo,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      logo: json['logo'] ?? '',
      ownerId: json['owner_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class StudioResponse {
  final bool success;
  final List<Studio> studios;
  final Pagination pagination;

  StudioResponse({
    required this.success,
    required this.studios,
    required this.pagination,
  });

  factory StudioResponse.fromJson(Map<String, dynamic> json) {
    return StudioResponse(
      success: json['success'] ?? false,
      studios: (json['data']['studios'] as List?)
          ?.map((studio) => Studio.fromJson(studio))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
    );
  }
}

class StudioSingleResponse {
  final bool success;
  final Studio studio;

  StudioSingleResponse({
    required this.success,
    required this.studio,
  });

  factory StudioSingleResponse.fromJson(Map<String, dynamic> json) {
    return StudioSingleResponse(
      success: json['success'] ?? false,
      studio: Studio.fromJson(json['data']['studio'] ?? {}),
    );
  }
}

class StudioDetailResponse {
  final bool success;
  final Studio studio;
  final List<Movie> movies;
  final Pagination pagination;

  StudioDetailResponse({
    required this.success,
    required this.studio,
    required this.movies,
    required this.pagination,
  });

  factory StudioDetailResponse.fromJson(Map<String, dynamic> json) {
    return StudioDetailResponse(
      success: json['success'] ?? false,
      studio: Studio.fromJson(json['data']['studio'] ?? {}),
      movies: (json['data']['movies'] as List?)
          ?.map((movie) => Movie.fromJson(movie))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
    );
  }
}
