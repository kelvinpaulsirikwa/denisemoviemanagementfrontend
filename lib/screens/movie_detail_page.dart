import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import '../models/movie_model.dart';
import '../models/movie_part_model.dart';
import '../models/trailer_model.dart';
import '../services/movie_service.dart';
import '../services/watchlist_service.dart';
import '../config/api_config.dart';
import 'video_streaming_screen.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailPage({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  bool isLoading = false;
  bool isInWatchlist = false;
  bool isCheckingWatchlist = true;
  StreamingInfo? streamingInfo;
  String? errorMessage;
  ChewieController? _chewieController;
  bool _isVideoPlayerInitialized = false;
  String? _hlsPlaylist;
  String? _directVideoUrl;
  bool _useHLS = false;
  
  // Movie parts and trailers
  MoviePartsResponse? moviePartsResponse;
  MovieTrailer? movieTrailer;
  bool isLoadingParts = false;
  bool isLoadingTrailer = false;
  String? partsError;
  String? trailerError;

  @override
  void initState() {
    super.initState();
    _checkWatchlistStatus();
    _loadMovieParts();
    _loadMovieTrailer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _checkWatchlistStatus() async {
    try {
      final response = await WatchlistService.checkWatchlist(widget.movie.id);
      setState(() {
        isInWatchlist = response.inWatchlist;
        isCheckingWatchlist = false;
      });
    } catch (e) {
      setState(() {
        isCheckingWatchlist = false;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (isInWatchlist) {
        await WatchlistService.removeFromWatchlist(widget.movie.id);
        setState(() {
          isInWatchlist = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from watchlist')),
          );
        }
      } else {
        await WatchlistService.addToWatchlist(widget.movie.id);
        setState(() {
          isInWatchlist = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to watchlist')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadStreamingInfo({String quality = '720p', bool useHLS = false}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _useHLS = useHLS;
      });

      if (useHLS) {
        final hlsPlaylist = await MovieService.getHLSStream(widget.movie.id);
        setState(() {
          _hlsPlaylist = hlsPlaylist;
          _directVideoUrl = null;
          isLoading = false;
        });
      } else {
        final videoUrl = await MovieService.getMovieStream(widget.movie.id, quality: quality);
        setState(() {
          _directVideoUrl = videoUrl;
          _hlsPlaylist = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load streaming info: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if ((_useHLS && _hlsPlaylist == null) || (!_useHLS && _directVideoUrl == null) || _isVideoPlayerInitialized) return;

    try {
      VideoPlayerController videoPlayerController;
      
      if (_useHLS) {
        // For HLS streaming, we need to extract the video URL from the playlist
        final lines = _hlsPlaylist!.split('\n');
        String? videoUrl;
        for (final line in lines) {
          if (line.isNotEmpty && !line.startsWith('#')) {
            videoUrl = line.startsWith('http') ? line : '${ApiConfig.baseUrl}/stream/${widget.movie.id}/$line';
            // Ensure HTTPS
            if (videoUrl.startsWith('http://')) {
              final originalUrl = videoUrl;
              videoUrl = videoUrl.replaceFirst('http://', 'https://');
              developer.log('HLS URL Conversion: $originalUrl -> $videoUrl');
            }
            developer.log('Final HLS Video URL: $videoUrl');
            break;
          }
        }
        if (videoUrl == null) {
          throw Exception('No video URL found in HLS playlist');
        }
        videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        // Ensure HTTPS for direct video URL
        String secureVideoUrl = _directVideoUrl!;
        if (secureVideoUrl.startsWith('http://')) {
          final originalUrl = secureVideoUrl;
          secureVideoUrl = secureVideoUrl.replaceFirst('http://', 'https://');
          developer.log('Direct URL Conversion: $originalUrl -> $secureVideoUrl');
        }
        developer.log('Final Direct Video URL: $secureVideoUrl');
        videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(secureVideoUrl),
        );
      }

      await videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isVideoPlayerInitialized = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing video player: ${e.toString()}')),
      );
    }
  }

  void _showVideoPlayer() {
    if (_chewieController != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(widget.movie.title),
            ),
            body: Center(
              child: Chewie(controller: _chewieController!),
            ),
          ),
        ),
      );
    }
  }

  // Load movie parts/episodes
  Future<void> _loadMovieParts() async {
    try {
      setState(() {
        isLoadingParts = true;
        partsError = null;
      });

      final response = await MovieService.getMovieParts(widget.movie.id);
      setState(() {
        moviePartsResponse = response;
        isLoadingParts = false;
      });
    } catch (e) {
      setState(() {
        isLoadingParts = false;
        partsError = e.toString();
      });
    }
  }

  // Load movie trailer
  Future<void> _loadMovieTrailer() async {
    try {
      setState(() {
        isLoadingTrailer = true;
        trailerError = null;
      });

      final response = await MovieService.getMovieTrailer(widget.movie.id);
      setState(() {
        movieTrailer = response;
        isLoadingTrailer = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTrailer = false;
        trailerError = e.toString();
      });
    }
  }

  // Navigate to video streaming screen
  void _navigateToVideoStreaming(MoviePart moviePart) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoStreamingScreen(moviePart: moviePart),
      ),
    );
  }

  // Navigate to trailer streaming
  void _navigateToTrailerStreaming() {
    if (movieTrailer != null && movieTrailer!.hasTrailer) {
      final trailerPart = MoviePart(
        id: -1, // Special ID for trailer
        title: '${widget.movie.title} - Trailer',
        partType: 'trailer',
        partNumber: 0,
        duration: movieTrailer!.duration,
        videoUrl: movieTrailer!.trailerUrl,
        streamUrl: movieTrailer!.streamUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoStreamingScreen(moviePart: trailerPart),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!isCheckingWatchlist)
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    ),
              onPressed: _toggleWatchlist,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMovieHeader(),
            const SizedBox(height: 24),
            _buildMovieInfo(),
            const SizedBox(height: 24),
            _buildTrailerSection(),
            const SizedBox(height: 24),
            _buildMoviePartsSection(),
            const SizedBox(height: 24),
            _buildStreamingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieHeader() {
    return Card(
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.movie.posterUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                widget.movie.posterUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, size: 64, color: Colors.grey),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.movie.rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.schedule,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.movie.duration} min',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.movie.releaseDate,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.movie.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Streaming Options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_directVideoUrl == null && _hlsPlaylist == null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStreamButton(
                          icon: Icons.video_file,
                          label: 'Direct Stream',
                          onPressed: () => _loadStreamingInfo(useHLS: false),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStreamButton(
                          icon: Icons.playlist_play,
                          label: 'HLS Stream',
                          onPressed: () => _loadStreamingInfo(useHLS: true),
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (errorMessage != null)
              _buildErrorState()
            else
              _buildStreamingInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStreamButton(
                icon: Icons.refresh,
                label: 'Retry Direct',
                onPressed: () => _loadStreamingInfo(useHLS: false),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStreamButton(
                icon: Icons.refresh,
                label: 'Retry HLS',
                onPressed: () => _loadStreamingInfo(useHLS: true),
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreamingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (_useHLS ? Colors.blue : Colors.green).shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (_useHLS ? Colors.blue : Colors.green).shade200),
          ),
          child: Row(
            children: [
              Icon(
                _useHLS ? Icons.playlist_play : Icons.video_file,
                color: _useHLS ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _useHLS ? 'HLS Stream Active' : 'Direct Stream Active',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _useHLS ? Colors.blue : Colors.green,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: _useHLS ? Colors.blue : Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Stream URL Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Stream URL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                _useHLS ? '${ApiConfig.baseUrl}/stream/${widget.movie.id}/hls' : (_directVideoUrl ?? 'Loading...'),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.copy, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to copy',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Movie Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.movie, color: Theme.of(context).primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Movie Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Title', widget.movie.title),
              _buildInfoRow('Duration', '${widget.movie.duration} min'),
              _buildInfoRow('Rating', '${widget.movie.rating}'),
              _buildInfoRow('Release Date', widget.movie.releaseDate),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _loadStreamingInfo(useHLS: !_useHLS),
                icon: Icon(_useHLS ? Icons.video_file : Icons.playlist_play),
                label: Text(_useHLS ? 'Switch to Direct' : 'Switch to HLS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _loadStreamingInfo(useHLS: _useHLS),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailerSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.movie_filter,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trailer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingTrailer)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading trailer...'),
                  ],
                ),
              )
            else if (trailerError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load trailer',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadMovieTrailer,
                      icon: const Icon(Icons.refresh),
                      color: Colors.red.shade600,
                    ),
                  ],
                ),
              )
            else if (movieTrailer != null && movieTrailer!.hasTrailer)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Trailer Available',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ),
                        Text(
                          movieTrailer!.duration,
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Format: ${movieTrailer!.resolution} • ${movieTrailer!.formattedFileSize}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToTrailerStreaming,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Watch Trailer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'No trailer available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviePartsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.playlist_play,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Movie Parts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (moviePartsResponse != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${moviePartsResponse!.totalParts} parts',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingParts)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading movie parts...'),
                  ],
                ),
              )
            else if (partsError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load movie parts',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadMovieParts,
                      icon: const Icon(Icons.refresh),
                      color: Colors.red.shade600,
                    ),
                  ],
                ),
              )
            else if (moviePartsResponse != null && moviePartsResponse!.parts.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: moviePartsResponse!.parts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final part = moviePartsResponse!.parts[index];
                  return _buildPartItem(part);
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'No parts available for this movie',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartItem(MoviePart part) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _navigateToVideoStreaming(part),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Part ${part.partNumber}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    part.partType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  part.duration,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              part.displayTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to play',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
