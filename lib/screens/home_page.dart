import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/category_model.dart';
import '../models/studio_model.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../config/api_config.dart';
import 'category_detail_page.dart';
import 'studio_detail_page.dart';
import 'movie_detail_page.dart';
import '../widgets/authenticated_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Category> categories = [];
  List<Studio> studios = [];
  List<Movie> movies = [];
  bool isLoading = true;
  bool isLoadingMovies = false;
  String? errorMessage;
  int currentMoviePage = 1;
  bool hasMoreMovies = true;
  final ScrollController _movieScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _movieScrollController.addListener(_onMovieScroll);
  }

  @override
  void dispose() {
    _movieScrollController.dispose();
    super.dispose();
  }

  void _onMovieScroll() {
    if (_movieScrollController.position.pixels == _movieScrollController.position.maxScrollExtent) {
      _loadMoreMovies();
    }
  }

  Future<void> _fetchData() async {
    try {
      developer.log('Starting to fetch homepage data...');
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      developer.log('Fetching categories...');
      final categoryResponse = await MovieService.getCategories();
      developer.log('Fetching studios...');
      final studioResponse = await MovieService.getStudios();
      developer.log('Fetching movies...');
      final moviesResponse = await MovieService.getMovies(page: 1);

      setState(() {
        categories = categoryResponse.categories;
        studios = studioResponse.studios;
        movies = moviesResponse.movies;
        hasMoreMovies = moviesResponse.pagination.currentPage < moviesResponse.pagination.lastPage;
        isLoading = false;
      });
      
      developer.log('Homepage data loaded successfully:');
      developer.log('- Categories: ${categories.length}');
      developer.log('- Studios: ${studios.length}');
      developer.log('- Movies: ${movies.length}');
    } catch (e) {
      developer.log('Error fetching homepage data: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMovies() async {
    if (!hasMoreMovies || isLoadingMovies) return;

    setState(() {
      isLoadingMovies = true;
      currentMoviePage++;
    });

    try {
      final response = await MovieService.getMovies(page: currentMoviePage);
      
      setState(() {
        movies.addAll(response.movies);
        hasMoreMovies = response.pagination.currentPage < response.pagination.lastPage;
        isLoadingMovies = false;
      });
    } catch (e) {
      setState(() {
        currentMoviePage--; // Reset page number on error
        isLoadingMovies = false;
      });
      // Optionally show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more movies: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
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
            onPressed: _fetchData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Categories'),
          const SizedBox(height: 12),
          _buildCategoriesGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('Studios'),
          const SizedBox(height: 12),
          _buildStudiosList(),
          const SizedBox(height: 24),
          _buildSectionTitle('Movies'),
          const SizedBox(height: 12),
          _buildMoviesList(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No categories available'),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailPage(category: category),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudiosList() {
    if (studios.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No studios available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: studios.length,
      itemBuilder: (context, index) {
        final studio = studios[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: studio.logo.isNotEmpty
                  ? ClipOval(
                      child: AuthenticatedImage(
                        imageUrl: '${ApiConfig.storageUrl}/${studio.logo}',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.movie,
                      color: Colors.deepPurple.shade700,
                    ),
            ),
            title: Text(studio.name),
            subtitle: Text(studio.description),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudioDetailPage(studio: studio),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMoviesList() {
    if (movies.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No movies available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      controller: _movieScrollController,
      itemCount: movies.length + (hasMoreMovies ? 1 : 0),
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
