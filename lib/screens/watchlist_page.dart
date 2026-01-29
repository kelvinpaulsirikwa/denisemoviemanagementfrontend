import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/watchlist_service.dart';
import 'movie_detail_page.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final ScrollController _scrollController = ScrollController();
  
  List<WatchlistItem> watchlistItems = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  
  int currentPage = 1;
  bool hasMore = true;
  String selectedSort = 'created_at';
  String selectedOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _fetchWatchlist();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreWatchlist();
    }
  }

  Future<void> _fetchWatchlist({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      hasMore = true;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await WatchlistService.getUserWatchlist(
        page: currentPage,
        sort: selectedSort,
        order: selectedOrder,
      );

      setState(() {
        if (isRefresh) {
          watchlistItems = response.watchlist;
        } else {
          watchlistItems.addAll(response.watchlist);
        }
        
        hasMore = response.pagination.currentPage < response.pagination.lastPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load watchlist: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreWatchlist() async {
    if (!hasMore || isLoadingMore || isLoading) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    try {
      final response = await WatchlistService.getUserWatchlist(
        page: currentPage,
        sort: selectedSort,
        order: selectedOrder,
      );

      setState(() {
        watchlistItems.addAll(response.watchlist);
        hasMore = response.pagination.currentPage < response.pagination.lastPage;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        currentPage--; // Reset page on error
        isLoadingMore = false;
      });
      // Optionally show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeFromWatchlist(int movieId, String movieTitle) async {
    try {
      await WatchlistService.removeFromWatchlist(movieId);
      
      setState(() {
        watchlistItems.removeWhere((item) => item.movieId == movieId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$movieTitle removed from watchlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: ${e.toString()}')),
        );
      }
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Watchlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedSort,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'created_at', child: Text('Date Added')),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchWatchlist(isRefresh: true);
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
      appBar: AppBar(
        title: const Text('My Watchlist'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchWatchlist(isRefresh: true),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null && watchlistItems.isEmpty
                ? _buildErrorWidget()
                : watchlistItems.isEmpty
                    ? _buildEmptyWidget()
                    : _buildWatchlistList(),
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
            onPressed: () => _fetchWatchlist(isRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Your watchlist is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add movies to your watchlist to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistList() {
    return Column(
      children: [
        if (watchlistItems.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '${watchlistItems.length} movies in your watchlist',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: watchlistItems.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == watchlistItems.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final watchlistItem = watchlistItems[index];
              final movie = watchlistItem.movie;
              
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
                      const SizedBox(height: 4),
                      Text(
                        'Added ${_formatDate(watchlistItem.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        _showRemoveConfirmation(movie.id, movie.title);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${(difference.inDays / 30).floor()} months ago';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showRemoveConfirmation(int movieId, String movieTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Watchlist'),
        content: Text('Are you sure you want to remove "$movieTitle" from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromWatchlist(movieId, movieTitle);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
