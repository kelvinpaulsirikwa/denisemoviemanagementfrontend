import '../config/api_config.dart';

class MoviePart {
  final int id;
  final String? title;
  final String partType;
  final int partNumber;
  final String duration;
  final String videoUrl;
  final String streamUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoviePart({
    required this.id,
    this.title,
    required this.partType,
    required this.partNumber,
    required this.duration,
    required this.videoUrl,
    required this.streamUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoviePart.fromJson(Map<String, dynamic> json) {
    return MoviePart(
      id: json['id'],
      title: json['title'], // Allow null values
      partType: json['part_type'],
      partNumber: json['part_number'],
      duration: json['duration'],
      videoUrl: json['video_url'],
      streamUrl: json['stream_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'part_type': partType,
      'part_number': partNumber,
      'duration': duration,
      'video_url': videoUrl,
      'stream_url': streamUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get display title with fallback
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    return 'Part $partNumber';
  }

  // Ensure stream URL always uses HTTPS
  String get secureStreamUrl {
    if (streamUrl.startsWith('http://')) {
      return streamUrl.replaceFirst('http://', 'https://');
    }
    return streamUrl;
  }

  // Get direct video URL with HTTPS
  String get secureVideoUrl {
    var directUrl = '${ApiConfig.storageUrl}/${videoUrl}';
    if (directUrl.startsWith('http://')) {
      directUrl = directUrl.replaceFirst('http://', 'https://');
    }
    return directUrl;
  }
}

class MoviePartsResponse {
  final int movieId;
  final String movieTitle;
  final int totalParts;
  final List<MoviePart> parts;

  MoviePartsResponse({
    required this.movieId,
    required this.movieTitle,
    required this.totalParts,
    required this.parts,
  });

  factory MoviePartsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return MoviePartsResponse(
      movieId: data['movie_id'],
      movieTitle: data['movie_title'],
      totalParts: data['total_parts'],
      parts: (data['parts'] as List)
          .map((partJson) => MoviePart.fromJson(partJson))
          .toList(),
    );
  }
}
