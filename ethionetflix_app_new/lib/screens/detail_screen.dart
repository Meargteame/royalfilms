// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/download_service.dart';
import '../services/payment_service.dart';
import '../models/content_item.dart';
import 'video_player_screen.dart';
import 'payment_screen.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> content;
  final ApiService apiService;
  final LocalStorageService localStorageService;

  const DetailScreen({
    Key? key,
    required this.content,
    required this.apiService,
    required this.localStorageService,
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with TickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
  final PaymentService _paymentService = PaymentService();
  late ContentItem _contentItem;
  bool _isInList = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  bool _isPaid = false;
  double _downloadProgress = 0;
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();
  final List<String> _tabs = ['Overview', 'Casts', 'Related'];

  @override
  void initState() {
    super.initState();
    _convertToContentItem();
    _checkIfDownloaded();
    
    // Initialize TabController after content item is created
    _tabController = TabController(length: _tabs.length, vsync: this);
  }
  
  void _convertToContentItem() {
  try {
    // Handle all possible ID field names (id, movieId)
    final contentId = widget.content['id'] ?? widget.content['movieId'] ?? widget.content['_id'] ?? 'unknown_id';
    
    // Print debug info to help identify the structure
    print('Content data: ${widget.content}');
    print('Extracted ID: $contentId');
    
    // Handle possible title field names
    final title = widget.content['title'] ?? 
                widget.content['name'] ?? 
                widget.content['seriesName'] ?? 
                'No Title';
    
    // Handle possible collection ID field names
    final collectionId = widget.content['collection_id'] ?? 
                        widget.content['collectionId'] ?? 
                        'all';
    
    // Handle poster URL with same logic as in the ContentCard
    final posterUrl = widget.content['thumbNail'] != null && widget.content['thumbNail'].toString().isNotEmpty
      ? widget.content['thumbNail'].toString().startsWith('http')
        ? widget.content['thumbNail'].toString()
        : widget.content['thumbNail'].toString().startsWith('/thumbnails')
          ? 'https://ethionetflix.hopto.org${widget.content['thumbNail']}'
          : widget.content['thumbNail'].toString()
      : widget.content['poster_url'] ?? 'https://via.placeholder.com/800x450';
    
    // Safely convert release year to the correct type
    dynamic releaseYear;
    if (widget.content['release_year'] != null) {
      releaseYear = widget.content['release_year'];
    } else if (widget.content['year'] != null) {
      releaseYear = widget.content['year'];
    }
    
    // Safely convert imdb rating
    double? imdbRating;
    if (widget.content['imdb_rating'] != null) {
      try {
        if (widget.content['imdb_rating'] is String) {
          imdbRating = double.tryParse(widget.content['imdb_rating']);
        } else if (widget.content['imdb_rating'] is num) {
          imdbRating = (widget.content['imdb_rating'] as num).toDouble();
        }
      } catch (e) {
        print('Error converting IMDB rating: $e');
      }
    } else if (widget.content['rating'] != null) {
      try {
        // Some content has rating in format '5.9/10'
        String ratingStr = widget.content['rating'].toString();
        if (ratingStr.contains('/')) {
          ratingStr = ratingStr.split('/')[0];
        }
        imdbRating = double.tryParse(ratingStr);
      } catch (e) {
        print('Error converting rating: $e');
      }
    }
    
    // Safely convert duration
    int? duration;
    if (widget.content['duration'] != null) {
      try {
        if (widget.content['duration'] is int) {
          duration = widget.content['duration'];
        } else if (widget.content['duration'] is String) {
          duration = int.tryParse(widget.content['duration']);
        }
      } catch (e) {
        print('Error converting duration: $e');
      }
    }
    
    // Get trailer URL from various possible sources
    String? trailerUrl;
    final trailerField = widget.content['trailer_url'] ?? 
                     widget.content['trailerUrl'] ?? 
                     widget.content['trailer'];
    
    if (trailerField != null) {
      if (trailerField is List) {
        // If trailer is a list, take the first item if available
        trailerUrl = trailerField.isNotEmpty ? trailerField[0].toString() : null;
      } else {
        trailerUrl = trailerField.toString();
      }
    }
    
    // Handle description which might be a List or a String
    String? description;
    if (widget.content['description'] != null) {
      if (widget.content['description'] is List) {
        // Join list elements into a single string
        description = (widget.content['description'] as List).join(', ');
      } else {
        description = widget.content['description'].toString();
      }
    }
    
    // Handle genre which might be a List or a String
    List<String>? genres;
    if (widget.content['genres'] != null) {
      if (widget.content['genres'] is List) {
        genres = (widget.content['genres'] as List).map((e) => e.toString()).toList().cast<String>();
      }
    } else if (widget.content['genre'] != null) {
      if (widget.content['genre'] is List) {
        genres = (widget.content['genre'] as List).map((e) => e.toString()).toList().cast<String>();
      } else if (widget.content['genre'] is String) {
        // Split comma-separated genres
        genres = widget.content['genre'].toString().split(',').map((e) => e.trim()).toList();
      }
    }
    
    // Handle countries which might be a List or a String
    List<String>? countries;
    if (widget.content['countries'] != null) {
      if (widget.content['countries'] is List) {
        countries = (widget.content['countries'] as List).map((e) => e.toString()).toList().cast<String>();
      }
    } else if (widget.content['country'] != null) {
      if (widget.content['country'] is List) {
        countries = (widget.content['country'] as List).map((e) => e.toString()).toList().cast<String>();
      } else if (widget.content['country'] is String) {
        // Split comma-separated countries
        countries = widget.content['country'].toString().split(',').map((e) => e.trim()).toList();
      }
    }
    
    _contentItem = ContentItem(
      id: contentId?.toString(),
      title: title,
      description: description,
      posterUrl: posterUrl,
      type: widget.content['type']?.toString(),
      quality: widget.content['quality']?.toString(),
      genres: genres,
      countries: countries,
      releaseYear: releaseYear,
      imdbRating: imdbRating,
      duration: duration,
      collectionId: collectionId,
      trailerUrl: trailerUrl,
    );
    
    print('Converted ContentItem: ${_contentItem.toJson()}');
  } catch (e) {
    print('Error in _convertToContentItem: $e');
    // Create a fallback content item to avoid crashes
    _contentItem = ContentItem(
      id: 'fallback_id',
      title: 'Error Loading Content',
      description: 'There was an error loading this content. Please try again.',
      posterUrl: 'https://via.placeholder.com/800x450',
      type: 'unknown',
      quality: 'unknown',
      collectionId: 'all',
    );
  }
}
  
  Future<void> _checkIfDownloaded() async {
    try {
      final downloads = await _downloadService.getDownloadedContent();
      setState(() {
        _isDownloaded = downloads.any((download) => 
          download['title'] == _contentItem.title ||
          download['id'] == _contentItem.id
        );
      });
    } catch (e) {
      print('Error checking download status: $e');
    }
  }

  Future<void> _toggleDownload() async {
    if (_isDownloaded) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Download'),
          content: Text('Are you sure you want to delete "${_contentItem.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final downloads = await _downloadService.getDownloadedContent();
          final download = downloads.firstWhere(
            (d) => d['title'] == _contentItem.title || d['id'] == _contentItem.id,
            orElse: () => {},
          );
          
          if (download['localPath'] != null) {
            await _downloadService.deleteDownload(download['localPath']);
            setState(() {
              _isDownloaded = false;
            });
            
      if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download deleted')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete download: $e')),
            );
          }
        }
      }
    } else {
      try {
        setState(() {
          _isDownloading = true;
          _downloadProgress = 0;
        });

        // Print content data for debugging
        print('Content data for download: ${widget.content}');

        // Try to get the download URL from various possible fields
        final downloadUrl = widget.content['downloadUrl'] ?? 
                          widget.content['streamUrl'] ?? 
                          widget.content['url'] ??
                          widget.content['contentUrl'] ??
                          widget.content['content_url'] ??
                          widget.content['stream_url'] ??
                          widget.content['download_url'];

        print('Found download URL: $downloadUrl');

        if (downloadUrl == null || downloadUrl.toString().isEmpty) {
          // If no direct URL found, try to construct it from the content ID
          final contentId = widget.content['id'] ?? 
                          widget.content['movieId'] ?? 
                          widget.content['_id'];
          
          if (contentId != null) {
            // Construct the URL using the content ID
            final constructedUrl = 'https://ethionetflix.hopto.org/api/stream/$contentId';
            print('Constructed URL from ID: $constructedUrl');
            
            final downloadedContent = await _downloadService.downloadContent({
              ...widget.content,
              'downloadUrl': constructedUrl,
            });

            setState(() {
              _isDownloading = false;
              _isDownloaded = true;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download complete')),
              );
            }
          } else {
            throw Exception('No content ID available to construct download URL');
          }
        } else {
          final downloadedContent = await _downloadService.downloadContent({
            ...widget.content,
            'downloadUrl': downloadUrl,
          });

          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download complete')),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isDownloading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Error screen displayed when content fails to load
  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Error handling - display error UI if content is not valid
    if (widget.content.isEmpty) {
      return _buildErrorScreen('Invalid content data');
    }
    
    // Check if content ID is missing
    if (_contentItem.id == null || _contentItem.id!.isEmpty) {
      return _buildErrorScreen('Invalid content ID');
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with movie poster and details
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.cast),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and release year
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _contentItem.title ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (_contentItem.releaseYear != null)
                                  Text(
                                    _contentItem.releaseYear.toString(),
                                    style: const TextStyle(
                                      color: AppTheme.textColorSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                if (_contentItem.imdbRating != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _contentItem.imdbRating.toString(),
                                    style: const TextStyle(
                                      color: AppTheme.textColorSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Ensure content item ID is valid before attempting to play
                            print('Play button pressed - Current content item: ${_contentItem.toJson()}');
                            
                            if (_contentItem.id == null || _contentItem.id!.isEmpty) {
                              print('Invalid content ID detected in play button handler');
                              print('Current content: ${_contentItem.toJson()}');
                              print('Original content data: ${widget.content}');
                              
                              // Try to recover by re-converting content item
                              _convertToContentItem();
                              
                              if (_contentItem.id == null || _contentItem.id!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cannot play: Missing content ID. Title: ${_contentItem.title}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }
                            }

                            await _handlePlayButton();
                          },
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: Text(
                            _isPaid || _isDownloaded ? 'Play' : 'Pay & Play (150 ETB)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Trailer button
                      _buildIconButton(
                        icon: Icons.movie_outlined,
                        label: 'Trailer',
                        onTap: () {
                          // Debug prints to understand the data structure
                          print('Attempting to play trailer');
                          print('Content data structure: ${widget.content}');
                          
                          // First try to get the trailer URL from various possible field names
                          final trailerUrl = widget.content['trailer_url'] ?? 
                                            widget.content['trailerUrl'] ?? 
                                            widget.content['trailer'];
                          
                          print('Found trailer URL: $trailerUrl');
                          
                          if (trailerUrl == null || trailerUrl.toString().isEmpty) {
                            // If no trailer URL is available, use a placeholder or fallback URL for testing
                            final fallbackUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
                            print('No trailer URL found, using fallback: $fallbackUrl');
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No official trailer available - playing sample video'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            
                            // Create a temporary ContentItem for the sample trailer
                            final trailerContent = ContentItem(
                              id: _contentItem.id ?? 'sample_trailer',
                              title: "${_contentItem.title} - Sample Trailer",
                              description: _contentItem.description,
                              posterUrl: _contentItem.posterUrl,
                              type: "trailer",
                              quality: _contentItem.quality,
                              trailerUrl: fallbackUrl,
                              collectionId: _contentItem.collectionId ?? 'all',
                            );
                            
                            print('Created trailer content: ${trailerContent.toJson()}');
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  content: trailerContent,
                                  apiService: widget.apiService,
                                  localStorageService: widget.localStorageService,
                                  isTrailer: true,
                                ),
                              ),
                            );
                            return;
                          }
                          
                          // Create a temporary ContentItem for the real trailer
                          final trailerContent = ContentItem(
                            id: _contentItem.id ?? 'unknown_id',
                            title: "${_contentItem.title} - Trailer",
                            description: _contentItem.description,
                            posterUrl: _contentItem.posterUrl,
                            type: "trailer",
                            quality: _contentItem.quality,
                            trailerUrl: trailerUrl.toString(),
                            collectionId: _contentItem.collectionId ?? 'all',
                          );
                          
                          print('Created trailer content: ${trailerContent.toJson()}');
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                content: trailerContent,
                                apiService: widget.apiService,
                                localStorageService: widget.localStorageService,
                                isTrailer: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Download button
                      _buildIconButton(
                        icon: _isDownloaded 
                            ? Icons.delete 
                            : (_isDownloading ? Icons.downloading : Icons.download),
                        label: _isDownloaded 
                            ? 'Delete' 
                            : (_isDownloading ? 'Downloading...' : 'Download'),
                        onTap: _toggleDownload,
                      ),
                      const SizedBox(width: 8),
                      // Add to watchlist button
                      _buildIconButton(
                        icon: _isInList ? Icons.check : Icons.add,
                        label: _isInList ? 'In List' : 'My List',
                        onTap: () {
                          setState(() {
                            _isInList = !_isInList;
                          });
                          // Save to local storage in a real implementation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isInList ? 'Added to My List' : 'Removed from My List',
                              ),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      _buildIconButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature not implemented'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Report button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildIconButton(
                        icon: Icons.flag,
                        label: 'Report',
                        onTap: () {
                          _showReportDialog(context);
                        },
                      ),
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border(bottom: BorderSide(color: AppTheme.surfaceColor, width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textColorSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                    tabs: _tabs
                        .map((label) => Tab(
                              text: label,
                              height: 44,
                            ))
                        .toList(),
                  ),
                ),

                // Tab content
                SizedBox(
                  height: 800, // Make it tall enough to show all content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Overview tab
                      _buildOverviewTab(),
                      // Casts tab
                      _buildCastsTab(),
                      // Related tab
                      _buildRelatedTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image using processed content item
        Image.network(
          _contentItem.posterUrl ?? 'https://via.placeholder.com/800x450',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.surfaceColor,
            child: const Icon(
              Icons.broken_image,
              color: AppTheme.textColorSecondary,
              size: 50,
            ),
          ),
        ),
        // Gradient overlay for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.7),
                Colors.black,
              ],
              stops: const [0.1, 0.5, 0.8, 1.0],
            ),
          ),
        ),
        // Quality badge
        if (_contentItem.quality != null)
          Positioned(
            top: 85, // Below the app bar
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _contentItem.quality!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Duration info if available
        if (_contentItem.duration != null)
          Positioned(
            top: 85, // Below the app bar
            left: _contentItem.quality != null ? 80 : 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_contentItem.duration} min',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.textColorPrimary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textColorSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre
          if (_contentItem.genres != null && _contentItem.genres!.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _contentItem.genres!.map((genre) {
                return Chip(
                  label: Text(
                    genre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textColorPrimary,
                    ),
                  ),
                  backgroundColor: AppTheme.surfaceColor,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          // Description
          const Text(
            'Synopsis',
            style: TextStyle(
              color: AppTheme.textColorPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _contentItem.description ?? 'No description available.',
            style: const TextStyle(
              color: AppTheme.textColorSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          // Additional information
          if (_contentItem.duration != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Duration', '${_contentItem.duration} min'),
          ],
          if (_contentItem.releaseYear != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Release Year', '${_contentItem.releaseYear}'),
          ],
          if (_contentItem.imdbRating != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Rating', '${_contentItem.imdbRating}/10'),
          ],
          if (_contentItem.countries != null && _contentItem.countries!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Country', _contentItem.countries!.join(', ')),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textColorPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColorSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCastsTab() {
    // Mock cast data - in a real app, this would come from the API
    final List<Map<String, dynamic>> castList = [
      {
        'name': 'Idris Elba',
        'character': 'Knuckles',
        'profile_image': 'https://via.placeholder.com/150',
        'movies_count': 46,
      },
      {
        'name': 'James Marsden',
        'character': 'Tom Wachowski',
        'profile_image': 'https://via.placeholder.com/150',
        'movies_count': 48,
      },
      {
        'name': 'Jim Carrey',
        'character': 'Dr. Robotnik',
        'profile_image': 'https://via.placeholder.com/150',
        'movies_count': 52,
      },
      {
        'name': 'Ben Schwartz',
        'character': 'Sonic (voice)',
        'profile_image': 'https://via.placeholder.com/150',
        'movies_count': 38,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: castList.length,
      itemBuilder: (context, index) {
        final cast = castList[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(cast['profile_image']),
            backgroundColor: AppTheme.surfaceColor,
            onBackgroundImageError: (_, __) {},
            child: const Icon(Icons.person, color: AppTheme.textColorSecondary),
          ),
          title: Text(
            cast['name'],
            style: const TextStyle(
              color: AppTheme.textColorPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            cast['character'],
            style: const TextStyle(color: AppTheme.textColorSecondary),
          ),
          trailing: Text(
            '${cast['movies_count']} movies',
            style: const TextStyle(
              color: AppTheme.textColorTertiary,
              fontSize: 12,
            ),
          ),
          onTap: () {
            // Navigate to actor details or filmography
          },
        );
      },
    );
  }

  Widget _buildRelatedTab() {
    // Mock related content - in a real app, this would come from the API
    final List<Map<String, dynamic>> relatedContent = [
      {
        'id': '1',
        'title': '22 vs. Earth',
        'poster_url': 'https://via.placeholder.com/300x450?text=22+vs+Earth',
        'type': 'Movie',
        'release_year': 2021,
        'genres': ['Comedy', 'Adventure', 'Animation', 'Family'],
        'country': 'United States of America',
      },
      {
        'id': '2',
        'title': 'The Mitchells vs. The Machines',
        'poster_url': 'https://via.placeholder.com/300x450?text=Mitchells',
        'type': 'Movie',
        'release_year': 2021,
        'genres': [
          'Animation',
          'Science Fiction',
          'Adventure',
          'Family',
          'Comedy'
        ],
        'country': 'United States of America',
      },
      {
        'id': '3',
        'title': 'Jungle Cruise',
        'poster_url': 'https://via.placeholder.com/300x450?text=Jungle+Cruise',
        'type': 'Movie',
        'release_year': 2021,
        'genres': ['Adventure', 'Family', 'Fantasy', 'Comedy'],
        'country': 'United States of America',
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: relatedContent.length,
      itemBuilder: (context, index) {
        final item = relatedContent[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              item['poster_url'],
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 90,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.broken_image,
                    color: AppTheme.textColorTertiary),
              ),
            ),
          ),
          title: Text(
            item['title'],
            style: const TextStyle(
              color: AppTheme.textColorPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['type']} • ${item['release_year']} • ${item['country']}',
                style: const TextStyle(
                    color: AppTheme.textColorSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                (item['genres'] as List).join(', '),
                style: const TextStyle(
                    color: AppTheme.textColorTertiary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onTap: () {
            // Navigate to content details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  content: item,
                  apiService: widget.apiService,
                  localStorageService: widget.localStorageService,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'REPORT',
                  style: TextStyle(
                    color: AppTheme.textColorPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.content['title'] ?? 'No Title',
                  style: TextStyle(
                    color: AppTheme.textColorPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildReportOption('Video'),
              _buildReportOption('Audio'),
              _buildReportOption('Subtitle'),
              _buildReportOption('Others'),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Describe the issue here (Optional)',
                    hintStyle: TextStyle(color: AppTheme.textColorTertiary),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: AppTheme.textColorPrimary),
                  maxLines: 3,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Report submitted for ${widget.content['title']}'),
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.8),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(String option) {
    return CheckboxListTile(
      title: Text(
        option,
        style: const TextStyle(color: AppTheme.textColorPrimary),
      ),
      value: false,
      onChanged: (value) {
        // Handle checkbox change
      },
      activeColor: AppTheme.primaryColor,
      checkColor: AppTheme.buttonTextColor,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Future<void> _handlePlayButton() async {
    if (_isPaid || _isDownloaded) {
      _playContent();
    } else {
      // Show payment screen
      final bool? paymentResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            amount: 150.0, // Fixed amount for each movie
            movieTitle: _contentItem.title ?? 'Unknown Title',
            onPaymentComplete: (success) {
              if (success) {
                setState(() => _isPaid = true);
              }
              Navigator.pop(context, success);
            },
          ),
        ),
      );

      if (paymentResult == true) {
        _playContent();
      }
    }
  }

  void _playContent() {
    if (_isDownloaded) {
      print('Content is downloaded, getting local path');
      widget.localStorageService
          .getDownloadedContentPath(_contentItem.id!)
          .then((offlinePath) {
        if (offlinePath != null) {
          print('Playing from offline path: $offlinePath');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                content: _contentItem,
                apiService: widget.apiService,
                localStorageService: widget.localStorageService,
                isOffline: true,
                offlinePath: offlinePath,
              ),
            ),
          );
        } else {
          _playOnlineContent();
        }
      });
    } else {
      _playOnlineContent();
    }
  }

  void _playOnlineContent() {
    print('Content not downloaded, playing online');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          content: _contentItem,
          apiService: widget.apiService,
          localStorageService: widget.localStorageService,
        ),
      ),
    );
  }
}
