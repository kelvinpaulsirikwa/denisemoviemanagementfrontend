import 'category_model.dart';

class Movie {
  final int id;
  final String title;
  final String description;
  final String releaseDate;
  final int duration;
  final double rating;
  final String posterUrl;
  final int studioId;
  final int categoryId;
  final String createdAt;
  final String updatedAt;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.releaseDate,
    required this.duration,
    required this.rating,
    required this.posterUrl,
    required this.studioId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      releaseDate: json['release_date'] ?? '',
      duration: json['duration'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      posterUrl: json['poster_url'] ?? '',
      studioId: json['studio_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class MoviesResponse {
  final bool success;
  final List<Movie> movies;
  final Pagination pagination;

  MoviesResponse({
    required this.success,
    required this.movies,
    required this.pagination,
  });

  factory MoviesResponse.fromJson(Map<String, dynamic> json) {
    return MoviesResponse(
      success: json['success'] ?? false,
      movies: (json['data']['movies'] as List?)
          ?.map((movie) => Movie.fromJson(movie))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
    );
  }
}

class MovieSingleResponse {
  final bool success;
  final Movie movie;

  MovieSingleResponse({
    required this.success,
    required this.movie,
  });

  factory MovieSingleResponse.fromJson(Map<String, dynamic> json) {
    return MovieSingleResponse(
      success: json['success'] ?? false,
      movie: Movie.fromJson(json['data']['movie'] ?? {}),
    );
  }
}

class CategoryDetailResponse {
  final bool success;
  final Category category;
  final List<Movie> movies;
  final Pagination pagination;

  CategoryDetailResponse({
    required this.success,
    required this.category,
    required this.movies,
    required this.pagination,
  });

  factory CategoryDetailResponse.fromJson(Map<String, dynamic> json) {
    return CategoryDetailResponse(
      success: json['success'] ?? false,
      category: Category.fromJson(json['data']['category'] ?? {}),
      movies: (json['data']['movies'] as List?)
          ?.map((movie) => Movie.fromJson(movie))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
    );
  }
}

class CategorySingleResponse {
  final bool success;
  final Category category;

  CategorySingleResponse({
    required this.success,
    required this.category,
  });

  factory CategorySingleResponse.fromJson(Map<String, dynamic> json) {
    return CategorySingleResponse(
      success: json['success'] ?? false,
      category: Category.fromJson(json['data']['category'] ?? {}),
    );
  }
}

class StreamingInfo {
  final int movieId;
  final String title;
  final String streamUrl;
  final String quality;
  final String format;
  final int duration;
  final int fileSize;
  final List<String> availableQualities;
  final List<String> subtitles;

  StreamingInfo({
    required this.movieId,
    required this.title,
    required this.streamUrl,
    required this.quality,
    required this.format,
    required this.duration,
    required this.fileSize,
    required this.availableQualities,
    required this.subtitles,
  });

  factory StreamingInfo.fromJson(Map<String, dynamic> json) {
    return StreamingInfo(
      movieId: json['movie_id'] ?? 0,
      title: json['title'] ?? '',
      streamUrl: json['stream_url'] ?? '',
      quality: json['quality'] ?? '',
      format: json['format'] ?? '',
      duration: json['duration'] ?? 0,
      fileSize: json['file_size'] ?? 0,
      availableQualities: (json['available_qualities'] as List?)
          ?.map((quality) => quality.toString())
          .toList() ?? [],
      subtitles: (json['subtitles'] as List?)
          ?.map((subtitle) => subtitle.toString())
          .toList() ?? [],
    );
  }
}

class StreamingResponse {
  final bool success;
  final StreamingInfo data;

  StreamingResponse({
    required this.success,
    required this.data,
  });

  factory StreamingResponse.fromJson(Map<String, dynamic> json) {
    return StreamingResponse(
      success: json['success'] ?? false,
      data: StreamingInfo.fromJson(json['data'] ?? {}),
    );
  }
}

class WatchlistResponse {
  final bool success;
  final String message;
  final dynamic data;

  WatchlistResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

class WatchlistCheckResponse {
  final bool success;
  final bool inWatchlist;

  WatchlistCheckResponse({
    required this.success,
    required this.inWatchlist,
  });

  factory WatchlistCheckResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistCheckResponse(
      success: json['success'] ?? false,
      inWatchlist: json['data']['in_watchlist'] ?? false,
    );
  }
}

class SearchInfo {
  final String query;
  final int totalResults;
  final double searchTime;

  SearchInfo({
    required this.query,
    required this.totalResults,
    required this.searchTime,
  });

  factory SearchInfo.fromJson(Map<String, dynamic> json) {
    return SearchInfo(
      query: json['query'] ?? '',
      totalResults: json['total_results'] ?? 0,
      searchTime: (json['search_time'] ?? 0).toDouble(),
    );
  }
}

class MovieSearchResponse {
  final bool success;
  final List<Movie> movies;
  final Pagination pagination;
  final SearchInfo searchInfo;

  MovieSearchResponse({
    required this.success,
    required this.movies,
    required this.pagination,
    required this.searchInfo,
  });

  factory MovieSearchResponse.fromJson(Map<String, dynamic> json) {
    return MovieSearchResponse(
      success: json['success'] ?? false,
      movies: (json['data']['movies'] as List?)
          ?.map((movie) => Movie.fromJson(movie))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
      searchInfo: SearchInfo.fromJson(json['data']['search_info'] ?? {}),
    );
  }
}

class WatchlistItem {
  final int id;
  final int userId;
  final int movieId;
  final String createdAt;
  final String updatedAt;
  final Movie movie;

  WatchlistItem({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.createdAt,
    required this.updatedAt,
    required this.movie,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      movieId: json['movie_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      movie: Movie.fromJson(json['movie'] ?? {}),
    );
  }
}

class UserWatchlistResponse {
  final bool success;
  final List<WatchlistItem> watchlist;
  final Pagination pagination;

  UserWatchlistResponse({
    required this.success,
    required this.watchlist,
    required this.pagination,
  });

  factory UserWatchlistResponse.fromJson(Map<String, dynamic> json) {
    return UserWatchlistResponse(
      success: json['success'] ?? false,
      watchlist: (json['data']['watchlist'] as List?)
          ?.map((item) => WatchlistItem.fromJson(item))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
    );
  }
}
