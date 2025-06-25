// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/modern_android_download_service.dart';
import '../models/content_item.dart';
import 'vlc_video_player_screen.dart' show VLCVideoPlayer;

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
  final ModernAndroidDownloadService _downloadService = ModernAndroidDownloadService();
  late ContentItem _contentItem;
  bool _isInList = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();
  final List<String> _tabs = ['Overview', 'Casts', 'Related'];
  
  // Series episodes data
  List<ContentItem> _seriesEpisodes = [];
  bool _isLoadingEpisodes = false;
  bool _isSeries = false;
  @override
  void initState() {
    super.initState();
    _convertToContentItem();
    _checkIfDownloaded();
    
    // Initialize TabController after content item is created
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Check if this is a series and fetch episodes
    _checkIfSeriesAndFetchEpisodes();
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
            ? 'https://ethionetflix1.hopto.org${widget.content['thumbNail']}'
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
          print('Error parsing IMDB rating: $e');
        }
      }
      
      // Safely convert duration
      int? duration;
      if (widget.content['duration'] != null) {
        try {
          if (widget.content['duration'] is String) {
            duration = int.tryParse(widget.content['duration']);
          } else if (widget.content['duration'] is num) {
            duration = (widget.content['duration'] as num).toInt();
          }
        } catch (e) {
          print('Error parsing duration: $e');
        }
      }
      
      // Handle genres
      List<String>? genres;
      if (widget.content['genres'] != null) {
        if (widget.content['genres'] is List) {
          genres = (widget.content['genres'] as List).map((e) => e.toString()).toList();
        } else if (widget.content['genres'] is String) {
          genres = [widget.content['genres'] as String];
        }
      }
      
      // Handle countries
      List<String>? countries;
      if (widget.content['countries'] != null) {
        if (widget.content['countries'] is List) {
          countries = (widget.content['countries'] as List).map((e) => e.toString()).toList();
        } else if (widget.content['countries'] is String) {
          countries = [widget.content['countries'] as String];
        }
      }
        _contentItem = ContentItem(
        id: contentId.toString(),
        title: title,
        description: widget.content['description'] ?? widget.content['synopsis'] ?? 'No description available.',
        posterUrl: posterUrl,
        type: widget.content['type'] ?? 'movie',
        quality: widget.content['quality'] ?? 'HD',
        genres: genres,
        countries: countries,
        releaseYear: releaseYear,
        imdbRating: imdbRating,
        duration: duration,
        collectionId: collectionId,
        trailerUrl: widget.content['trailer_url'] ?? widget.content['trailerUrl'],
        // Series-specific fields
        seriesId: widget.content['series_id'] ?? widget.content['seriesId'],
        seriesName: widget.content['series_name'] ?? widget.content['seriesName'] ?? widget.content['name'],
        episodeNumber: widget.content['episode_number'] ?? widget.content['episodeNumber'],
        seasonNumber: widget.content['season_number'] ?? widget.content['seasonNumber'],
        episode: widget.content['episode'],
      );
      
    } catch (e) {
      print('Error converting to ContentItem: $e');
      // Fallback content item
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
      // For the modern download service, we'll track downloads differently
      // Since files are saved by user choice via SAF, we'll use local storage to track
      final contentId = _contentItem.id ?? 'unknown';
      final isDownloaded = await widget.localStorageService.isContentDownloaded(contentId);
      setState(() {
        _isDownloaded = isDownloaded;
      });
    } catch (e) {
      print('Error checking download status: $e');
      setState(() {
        _isDownloaded = false;
      });
    }
  }

  Future<void> _toggleDownload() async {
    if (_isDownloaded) {
      // Show confirmation dialog for deletion
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Remove Download Record', style: TextStyle(color: AppTheme.textColorPrimary)),
          content: Text(
            'This will remove the download record. The actual file saved to your device will remain.',
            style: TextStyle(color: AppTheme.textColorSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          setState(() {
            _isDownloaded = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Download record removed. File remains in your chosen location.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to remove download record: $e')),
            );
          }
        }
      }
    } else if (_isDownloading) {
      // Cancel ongoing download
      final contentId = _contentItem.id ?? 'unknown';
      await _downloadService.cancelDownload(contentId);
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download cancelled')),
        );
      }
    } else {
      await _startDownload();
    }
  }

  Future<void> _startDownload() async {
    try {      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      print('🚀 Starting download for: ${widget.content['name'] ?? 'Unknown'}');
      
      // Initialize the modern download service
      await _downloadService.initialize();
      
      // Simple, direct download approach
      bool success = false;
      try {
        // Try to download the actual EthioNetflix content
        success = await _downloadService.downloadEthioNetflixContent(
          widget.content,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
            });
          },
        );
        
        if (success) {
          print('✅ Content download successful!');
        }
        
      } catch (e) {
        print('❌ Download failed: $e');
        success = false;
        
        // Show simple error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${e.toString().contains('404') ? 'Content not available on server' : 'Network error'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      setState(() {
        _isDownloading = false;
      });

      if (success) {
        setState(() {
          _isDownloaded = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Download saved to your chosen location!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Download was cancelled or failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      
      print('💥 Download error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkIfSeriesAndFetchEpisodes() async {
    // Check if the content is a series
    _isSeries = _contentItem.type?.toLowerCase() == 'series' || 
                widget.content['type']?.toString().toLowerCase() == 'series' ||
                widget.content['is_series'] == true ||
                _contentItem.seriesId != null ||
                _contentItem.seriesName != null;
    
    if (_isSeries) {
      await _fetchSeriesEpisodes();
    }
  }
  
  Future<void> _fetchSeriesEpisodes() async {
    if (!_isSeries) return;
    
    setState(() {
      _isLoadingEpisodes = true;
    });
    
    try {
      List<ContentItem> episodes = [];
      
      // Try to fetch episodes using series_id first
      if (_contentItem.seriesId != null && _contentItem.seriesId!.isNotEmpty) {
        episodes = await widget.apiService.getSeriesEpisodes(_contentItem.seriesId!, useSeriesId: true);
      }
      
      // If no episodes found and we have a series name, try that
      if (episodes.isEmpty && _contentItem.seriesName != null && _contentItem.seriesName!.isNotEmpty) {
        episodes = await widget.apiService.getSeriesEpisodes(_contentItem.seriesName!, useSeriesId: false);
      }
      
      // If still no episodes, try using the main title
      if (episodes.isEmpty && _contentItem.title != null && _contentItem.title!.isNotEmpty) {
        episodes = await widget.apiService.getSeriesEpisodes(_contentItem.title!, useSeriesId: false);
      }
      
      setState(() {
        _seriesEpisodes = episodes;
        _isLoadingEpisodes = false;
      });
      
      print('Loaded ${episodes.length} episodes for series: ${_contentItem.title}');
    } catch (e) {
      print('Error fetching series episodes: $e');
      setState(() {
        _isLoadingEpisodes = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _playVideo() {
    print('Playing video for content: ${_contentItem.title}');
    
    // Check if content is downloaded first
    if (_isDownloaded) {
      // Try to get offline path first
      widget.localStorageService
        .getDownloadedContentPath(_contentItem.id ?? 'unknown')
        .then((offlinePath) {
          if (offlinePath != null) {
            print('Playing from offline path: $offlinePath');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VLCVideoPlayer(
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
        builder: (context) => VLCVideoPlayer(
          content: _contentItem,
          apiService: widget.apiService,
          localStorageService: widget.localStorageService,
          isOffline: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildContentDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              _contentItem.posterUrl ?? 'https://via.placeholder.com/800x450',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(
                    Icons.movie,
                    size: 80,
                    color: AppTheme.textColorSecondary,
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Play button overlay
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _playVideo,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _toggleDownload,
                    icon: Icon(
                      _isDownloading 
                        ? Icons.stop 
                        : _isDownloaded 
                          ? Icons.download_done 
                          : Icons.download,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            // Download progress indicator
            if (_isDownloading)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Downloading ${(_downloadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and basic info
          Text(
            _contentItem.title ?? 'Unknown Title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Metadata row
          Row(
            children: [
              if (_contentItem.releaseYear != null) ...[
                Text(
                  _contentItem.releaseYear.toString(),
                  style: const TextStyle(color: AppTheme.textColorSecondary),
                ),
                const SizedBox(width: 16),
              ],
              if (_contentItem.duration != null) ...[
                Text(
                  '${_contentItem.duration} min',
                  style: const TextStyle(color: AppTheme.textColorSecondary),
                ),
                const SizedBox(width: 16),
              ],
              if (_contentItem.quality != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textColorSecondary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _contentItem.quality!,
                    style: const TextStyle(
                      color: AppTheme.textColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            _contentItem.description ?? 'No description available.',
            style: const TextStyle(
              color: AppTheme.textColorSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Genres
          if (_contentItem.genres != null && _contentItem.genres!.isNotEmpty) ...[
            const Text(
              'Genres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _contentItem.genres!.map((genre) => Chip(
                label: Text(genre),
                backgroundColor: AppTheme.surfaceColor,
                labelStyle: const TextStyle(color: AppTheme.textColorPrimary),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // IMDB Rating
          if (_contentItem.imdbRating != null) ...[
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  'IMDB ${_contentItem.imdbRating}/10',
                  style: const TextStyle(
                    color: AppTheme.textColorPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Add to list functionality
                  },
                  icon: Icon(_isInList ? Icons.check : Icons.add),
                  label: Text(_isInList ? 'In My List' : 'Add to List'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textColorPrimary,
                    side: const BorderSide(color: AppTheme.textColorPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Share functionality
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textColorPrimary,
                    side: const BorderSide(color: AppTheme.textColorPrimary),
                  ),
                ),
              ),
            ],
          ),
            const SizedBox(height: 32),
          
          // Episodes section for series
          if (_isSeries) ...[
            _buildEpisodesSection(),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEpisodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Episodes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary,
              ),
            ),
            const Spacer(),
            if (_isLoadingEpisodes)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingEpisodes && _seriesEpisodes.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Loading episodes...',
                style: TextStyle(color: AppTheme.textColorSecondary),
              ),
            ),
          )
        else if (_seriesEpisodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No episodes found for this series',
                style: TextStyle(color: AppTheme.textColorSecondary),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _seriesEpisodes.length,
            itemBuilder: (context, index) {
              final episode = _seriesEpisodes[index];
              return _buildEpisodeCard(episode, index + 1);
            },
          ),
      ],
    );
  }
  
  Widget _buildEpisodeCard(ContentItem episode, int displayNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _playEpisode(episode),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode thumbnail
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppTheme.backgroundColor,
                ),                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    _getEpisodePosterUrl(episode),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.backgroundColor,
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Episode info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Episode title
                    Text(
                      episode.title ?? 'Episode ${episode.episodeNumber ?? displayNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColorPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Episode metadata
                    Row(
                      children: [
                        if (episode.seasonNumber != null) ...[
                          Text(
                            'S${episode.seasonNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (episode.episodeNumber != null) ...[
                          Text(
                            'E${episode.episodeNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (episode.duration != null) ...[
                          Text(
                            '${episode.duration}min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Episode description
                    if (episode.description != null && episode.description!.isNotEmpty)
                      Text(
                        episode.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textColorSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Play button
              IconButton(
                onPressed: () => _playEpisode(episode),
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _playEpisode(ContentItem episode) {
    print('Playing episode: ${episode.title}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VLCVideoPlayer(
          content: episode,
          apiService: widget.apiService,
          localStorageService: widget.localStorageService,
          isOffline: false,
        ),
      ),
    );
  }
    String _getEpisodePosterUrl(ContentItem episode) {
    // First try the episode's own poster URL
    if (episode.posterUrl != null && episode.posterUrl!.isNotEmpty) {
      if (episode.posterUrl!.startsWith('http')) {
        return episode.posterUrl!;
      } else if (episode.posterUrl!.startsWith('/thumbnails')) {
        return 'https://ethionetflix1.hopto.org${episode.posterUrl}';
      }
    }
    
    // Fallback to the main series poster
    if (_contentItem.posterUrl != null && _contentItem.posterUrl!.isNotEmpty) {
      return _contentItem.posterUrl!;
    }
    
    // Final fallback to default poster
    return 'https://via.placeholder.com/300x200/333333/ffffff?text=Episode';
  }
}
