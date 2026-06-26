import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'topic_detail_screen.dart';
import 'widgets/full_screen_image_viewer.dart';

class TrendingScreen extends StatefulWidget {
  final String? apiKey;
  final String? imageApiKey;

  const TrendingScreen({
    super.key,
    this.apiKey,
    this.imageApiKey,
  });

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TrendingTopic> _allTopics = [];
  List<TrendingTopic> _filteredTopics = [];

  @override
  void initState() {
    super.initState();
    _loadTrendingTopics();
    _searchController.addListener(_filterTopics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTrendingTopics() {
    _allTopics = [
      TrendingTopic(
        title: 'AI Technology',
        description: 'Latest trends in artificial intelligence',
        imageUrl: 'https://vidyaenews.most.gov.lk/wp-content/uploads/2025/01/5-AI-Advancements-to-Expect-in-the-Next-10-Years-scaled-1-780x470.jpeg',
        hashtags: ['#AI', '#Technology', '#Innovation'],
        trendScore: 9.8,
      ),
      TrendingTopic(
        title: 'Sustainable Fashion',
        description: 'Eco-friendly fashion and sustainable brands',
        imageUrl: 'https://images.ft.com/v3/image/raw/ftcms%3A3dc5a87a-53d4-4f00-a166-6c668fc12909?source=next-article&fit=scale-down&quality=highest&width=1440&dpr=1',
        hashtags: ['#SustainableFashion', '#EcoFriendly', '#Green'],
        trendScore: 9.5,
      ),
      TrendingTopic(
        title: 'Remote Work',
        description: 'Tips and trends for working from home',
        imageUrl: 'https://gigster.com/wp-content/uploads/2023/09/benefits-of-remote-working.jpg',
        hashtags: ['#RemoteWork', '#WorkFromHome', '#Productivity'],
        trendScore: 9.2,
      ),
      TrendingTopic(
        title: 'Mental Health',
        description: 'Wellness and mental health awareness',
        imageUrl: 'https://www.planstreet.com/img/blog/what-is-mental-health.webp',
        hashtags: ['#MentalHealth', '#Wellness', '#Mindfulness'],
        trendScore: 9.0,
      ),
      TrendingTopic(
        title: 'Cryptocurrency',
        description: 'Latest news and trends in crypto',
        imageUrl: 'https://content.kaspersky-labs.com/fm/press-releases/e0/e0c122e63ca4199bb2f758617abad50b/source/cryptocurrencyimage11130490519670x377px300dpi.jpg',
        hashtags: ['#Crypto', '#Bitcoin', '#Blockchain'],
        trendScore: 8.8,
      ),
      TrendingTopic(
        title: 'Fitness & Health',
        description: 'Workout routines and health tips',
        imageUrl: 'https://img.freepik.com/free-photo/athlete-playing-sport-with-hand-drawn-doodles_23-2150036348.jpg?semt=ais_hybrid&w=740&q=80',
        hashtags: ['#Fitness', '#Health', '#Workout'],
        trendScore: 8.5,
      ),
      TrendingTopic(
        title: 'Travel Destinations',
        description: 'Top travel spots and vacation ideas',
        imageUrl: 'https://i.dawn.com/primary/2019/06/5d02a993e2dfa.png',
        hashtags: ['#Travel', '#Vacation', '#Adventure'],
        trendScore: 8.3,
      ),
      TrendingTopic(
        title: 'Food & Recipes',
        description: 'Trending recipes and food culture',
        imageUrl: 'https://www.indiafoodnetwork.in/h-upload/2021/09/28/562120-untitled-design-10.webp',
        hashtags: ['#Food', '#Recipe', '#Cooking'],
        trendScore: 8.0,
      ),
    ];
    _filteredTopics = List.from(_allTopics);
  }

  void _filterTopics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTopics = List.from(_allTopics);
      } else {
        _filteredTopics = _allTopics.where((topic) {
          return topic.title.toLowerCase().contains(query) ||
                 topic.description.toLowerCase().contains(query) ||
                 topic.hashtags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Search Bar
            _buildSearchBar(),
            
            // Content
            Expanded(
              child: _filteredTopics.isEmpty
                  ? _buildEmptyState()
                  : _buildTrendingList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink[400]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Trending Topics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search trending topics...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF572D74)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No topics found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredTopics.length,
      itemBuilder: (context, index) {
        return _buildTopicCard(_filteredTopics[index]);
      },
    );
  }

  Widget _buildTopicCard(TrendingTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () {
              FullScreenImageViewer.show(
                context,
                imageUrl: topic.imageUrl,
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: CachedNetworkImage(
                      imageUrl: topic.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      placeholder: (context, url) => Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Trend Score Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink[400]!, Colors.purple[400]!],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${topic.trendScore}',
                            style: TextStyle(
                              color: Theme.of(context).cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  topic.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  topic.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Hashtags
                Wrap(
                  spacing: 8,
                  children: topic.hashtags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Explore Topic Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicDetailScreen(
                            topic: topic,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF572D74),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Explore & Create Post',
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrendingTopic {
  final String title;
  final String description;
  final String imageUrl;
  final List<String> hashtags;
  final double trendScore;

  TrendingTopic({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.hashtags,
    required this.trendScore,
  });
}

