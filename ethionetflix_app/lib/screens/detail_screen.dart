// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> content;

  const DetailScreen({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Overview', 'Casts', 'Related'];
  bool _isInList = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                              widget.content['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColorPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.content['release_year']?.toString() ??
                                      '',
                                  style: const TextStyle(
                                    color: AppTheme.textColorSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                if (widget.content['imdb_rating'] != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.content['imdb_rating'].toString(),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Removed API call and navigation to VideoPlayerScreen
                            print(
                                'Watch button tapped! (No actual playback in UI-only mode)');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Video playback not available in UI-only mode.'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Watch'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: AppTheme.buttonTextColor,
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement Watch List functionality
                            print('Add to Watch List button tapped!');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Add to Watch List not implemented in UI-only mode.'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Watch List'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: AppTheme.buttonTextColor,
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Additional action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconButton(
                        icon: _isInList
                            ? Icons.playlist_add_check
                            : Icons.playlist_add,
                        label: 'Add List',
                        onTap: () {
                          setState(() {
                            _isInList = !_isInList;
                          });
                        },
                      ),
                      _buildIconButton(
                        icon: Icons.videocam,
                        label: 'Trailer',
                        onTap: () {},
                      ),
                      _buildIconButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {},
                      ),
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

                // Tabs
                TabBar(
                  controller: _tabController,
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textColorSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
        // Background image
        Image.network(
          widget.content['poster_url'] ?? 'https://via.placeholder.com/500x300',
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
                Colors.black.withOpacity(0.7),
                Colors.black,
              ],
            ),
          ),
        ),
        // Quality badge
        if (widget.content['quality'] != null)
          Positioned(
            top: 85, // Below the app bar
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.content['quality'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
          if (widget.content['genres'] != null &&
              (widget.content['genres'] as List).isNotEmpty)
            Wrap(
              spacing: 8,
              children: (widget.content['genres'] as List).map((genre) {
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
            widget.content['description'] ?? 'No description available.',
            style: const TextStyle(
              color: AppTheme.textColorSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          // Additional information
          if (widget.content['duration'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Duration', '${widget.content['duration']} min'),
          ],
          if (widget.content['countries'] != null &&
              (widget.content['countries'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
                'Country', (widget.content['countries'] as List).join(', ')),
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
                builder: (context) => DetailScreen(content: item),
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
}
