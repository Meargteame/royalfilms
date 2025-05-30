import 'package:flutter/material.dart';

class WatchListScreen extends StatefulWidget {
  const WatchListScreen({Key? key}) : super(key: key);

  @override
  _WatchListScreenState createState() => _WatchListScreenState();
}

class _WatchListScreenState extends State<WatchListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _tabs = ['Movie', 'TV Series', 'Trakt'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality for Watch List
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
          indicatorColor:
              Theme.of(context).tabBarTheme.indicatorColor, // Use theme colors
          labelColor: Theme.of(context).tabBarTheme.labelColor,
          unselectedLabelColor:
              Theme.of(context).tabBarTheme.unselectedLabelColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            _tabs.map((String tab) {
              // Placeholder content for each tab
              return Center(
                child: Text(
                  '${tab} Watch List Content Placeholder',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ), // Use theme colors
                ),
              );
            }).toList(),
      ),
    );
  }
}
