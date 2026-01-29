import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../models/category_model.dart';
import '../models/studio_model.dart';
import '../services/movie_service.dart';
import 'movie_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Movie> movies = [];
  List<Category> categories = [];
  List<Studio> studios = [];
  
  bool isLoading = false;
  bool isLoadingFilters = true;
  bool isLoadingMore = false;
  String? errorMessage;
  String currentQuery = '';
  
  int currentPage = 1;
  bool hasMore = true;
  
  // Filter values
  int? selectedCategoryId;
  int? selectedStudioId;
  String selectedSort = 'relevance';
  String selectedOrder = 'desc';
  double? minRating;
  double? maxRating;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreResults();
    }
  }

  Future<void> _loadFilters() async {
    try {
      final categoryResponse = await MovieService.getCategories();
      final studioResponse = await MovieService.getStudios();
      
      setState(() {
        categories = categoryResponse.categories;
        studios = studioResponse.studios;
        isLoadingFilters = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFilters = false;
      });
    }
  }

  Future<void> _searchMovies({bool isRefresh = false}) async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a search query';
      });
      return;
    }

    if (isRefresh) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        currentQuery = query;
      });

      final response = await MovieService.searchMovies(
        query,
        page: currentPage,
        categoryId: selectedCategoryId,
        studioId: selectedStudioId,
        sort: selectedSort,
        order: selectedOrder,
        minRating: minRating,
        maxRating: maxRating,
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
        errorMessage = 'Search failed: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (!hasMore || isLoadingMore || isLoading) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    try {
      final response = await MovieService.searchMovies(
        currentQuery,
        page: currentPage,
        categoryId: selectedCategoryId,
        studioId: selectedStudioId,
        sort: selectedSort,
        order: selectedOrder,
        minRating: minRating,
        maxRating: maxRating,
      );

      setState(() {
        movies.addAll(response.movies);
        hasMore = response.pagination.currentPage < response.pagination.lastPage;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        currentPage--; // Reset page on error
        isLoadingMore = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Filters'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All Categories',
                ),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('All Categories')),
                  ...categories.map((category) => DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(category.name),
                  )),
                ],
                onChanged: (value) {
                  selectedCategoryId = value;
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Studio', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedStudioId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All Studios',
                ),
                items: [
                  const DropdownMenuItem<int>(value: null, child: Text('All Studios')),
                  ...studios.map((studio) => DropdownMenuItem<int>(
                    value: studio.id,
                    child: Text(studio.name),
                  )),
                ],
                onChanged: (value) {
                  selectedStudioId = value;
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedSort,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
                  DropdownMenuItem(value: 'title', child: Text('Title')),
                  DropdownMenuItem(value: 'rating', child: Text('Rating')),
                  DropdownMenuItem(value: 'release_date', child: Text('Release Date')),
                ],
                onChanged: (value) {
                  selectedSort = value!;
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Order', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedOrder,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                ],
                onChanged: (value) {
                  selectedOrder = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchMovies(isRefresh: true);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: isLoadingFilters
                ? const Center(child: CircularProgressIndicator())
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search movies...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                movies.clear();
                                currentQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _searchMovies(isRefresh: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Filters',
              ),
            ],
          ),
          if (currentQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Results for "$currentQuery"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (movies.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    '${movies.length} movies',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isLoading && movies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchMovies(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (movies.isEmpty && currentQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Search for movies',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _searchMovies(isRefresh: true),
      child: ListView.builder(
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
                    ? Image.network(
                        movie.posterUrl,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie, color: Colors.grey),
                          );
                        },
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
      ),
    );
  }
}
