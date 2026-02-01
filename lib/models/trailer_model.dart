import '../config/api_config.dart';

class MovieTrailer {
  final int movieId;
  final String movieTitle;
  final String trailerUrl;
  final String streamUrl;
  final String duration;
  final int fileSize;
  final String format;
  final String resolution;
  final bool hasTrailer;

  MovieTrailer({
    required this.movieId,
    required this.movieTitle,
    required this.trailerUrl,
    required this.streamUrl,
    required this.duration,
    required this.fileSize,
    required this.format,
    required this.resolution,
    required this.hasTrailer,
  });

  factory MovieTrailer.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return MovieTrailer(
      movieId: data['movie_id'],
      movieTitle: data['movie_title'],
      trailerUrl: data['trailer_url'] ?? '',
      streamUrl: data['stream_url'] ?? '',
      duration: data['duration'] ?? '0:00',
      fileSize: data['file_size'] ?? 0,
      format: data['format'] ?? 'mp4',
      resolution: data['resolution'] ?? '720p',
      hasTrailer: data['has_trailer'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movie_id': movieId,
      'movie_title': movieTitle,
      'trailer_url': trailerUrl,
      'stream_url': streamUrl,
      'duration': duration,
      'file_size': fileSize,
      'format': format,
      'resolution': resolution,
      'has_trailer': hasTrailer,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get direct trailer URL with HTTPS
  String get secureTrailerUrl {
    var directUrl = '${ApiConfig.storageUrl}/${trailerUrl}';
    if (directUrl.startsWith('http://')) {
      directUrl = directUrl.replaceFirst('http://', 'https://');
    }
    return directUrl;
  }
}
