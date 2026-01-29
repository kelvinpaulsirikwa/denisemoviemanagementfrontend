import 'package:flutter/material.dart';
import '../models/studio_model.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../config/api_config.dart';
import '../screens/movie_detail_page.dart';
import '../widgets/authenticated_image.dart';

class StudioDetailPage extends StatefulWidget {
  final Studio studio;

  const StudioDetailPage({
    super.key,
    required this.studio,
  });

  @override
  State<StudioDetailPage> createState() => _StudioDetailPageState();
}

class _StudioDetailPageState extends State<StudioDetailPage> {
  List<Movie> movies = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreMovies();
    }
  }

  Future<void> _fetchMovies({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      setState(() {
        if (isRefresh) {
          isLoading = true;
          errorMessage = null;
        }
      });

      final response = await MovieService.getMoviesByStudio(
        widget.studio.id,
        page: currentPage,
      );

      setState(() {
        if (isRefresh) {
          movies = response.movies;
        } else {
          movies.addAll(response.movies);
        }
        
        hasMore = response.pagination.currentPage < response.pagination.lastPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load movies: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMovies() async {
    if (!hasMore || isLoading) return;

    setState(() {
      currentPage++;
    });

    await _fetchMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studio.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchMovies(isRefresh: true),
        child: isLoading && movies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null && movies.isEmpty
                ? _buildErrorWidget()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchMovies(isRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildStudioHeader(),
        Expanded(
          child: movies.isEmpty
              ? _buildEmptyState()
              : _buildMoviesList(),
        ),
      ],
    );
  }

  Widget _buildStudioHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: widget.studio.logo.isNotEmpty
                    ? ClipOval(
                        child: AuthenticatedImage(
                          imageUrl: '${ApiConfig.storageUrl}/${widget.studio.logo}',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.business, size: 30, color: Colors.deepPurple),
                        ),
                      )
                    : const Icon(Icons.business, size: 30, color: Colors.deepPurple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.studio.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.studio.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactInfo(),
          const SizedBox(height: 8),
          Text(
            '${movies.length} movies',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.studio.email.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.email,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                widget.studio.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        if (widget.studio.phoneNumber.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                widget.studio.phoneNumber,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No movies found from this studio',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: movies.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == movies.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final movie = movies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.posterUrl.isNotEmpty
                  ? AuthenticatedImage(
                      imageUrl: movie.posterUrl,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
            ),
            title: Text(
              movie.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  movie.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text('${movie.duration} min'),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailPage(movie: movie),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
