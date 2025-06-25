import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/modern_android_download_service.dart';
import '../widgets/content_card.dart';
import 'detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  final LocalStorageService localStorageService;
  final ApiService apiService;

  const DownloadsScreen({
    Key? key,
    required this.localStorageService,
    required this.apiService,
  }) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final ModernAndroidDownloadService _downloadService = ModernAndroidDownloadService();
  List<Map<String, dynamic>> _downloadedContent = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDownloads();
  }
  Future<void> _initializeDownloads() async {
    try {
      await _downloadService.initialize();
      await _loadDownloadedContent();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize downloads: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDownloadedContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {      // For the modern download service, we get downloaded content from local storage
      final downloads = await widget.localStorageService.getDownloadedVideos();
      setState(() {
        _downloadedContent = downloads.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load downloads: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(Map<String, dynamic> content) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Remove Download Record', style: TextStyle(color: AppTheme.textColorPrimary)),
          content: Text(
            'This will remove the download record from the app. The actual file on your device will remain.',
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
        // Remove from local storage tracking
        setState(() {
          _downloadedContent.removeWhere((item) => item['id'] == content['id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download record removed. File remains on your device.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove download record: $e')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400], size: 60),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[400]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDownloadedContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _downloadedContent.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_done_rounded,
                            size: 80,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Downloads Yet',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your downloaded content will appear here',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDownloadedContent,
                      color: AppTheme.primaryColor,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _downloadedContent.length,
                        itemBuilder: (context, index) {
                          final content = _downloadedContent[index];
                          return Stack(
                            children: [
                              ContentCard(
                                imageUrl: content['thumbNail'] ?? '',
                                title: content['title'] ?? 'Untitled',
                                type: content['type'] ?? '',
                                quality: content['quality'] ?? 'HD',
                                year: content['year']?.toString() ?? '',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        content: content,
                                        apiService: widget.apiService,
                                        localStorageService: widget.localStorageService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Download'),
                                        content: Text('Are you sure you want to delete "${content['title']}"?'),
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
                                      await _deleteDownload(content);
                                    }
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatFileSize(content['size'] ?? 0),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }
} 