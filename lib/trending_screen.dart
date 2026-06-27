import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'config/api_config.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingTopics();
    _searchController.addListener(_filterTopics);
  }

  /// Builds a free, relevant cover image for a topic via Pollinations.
  String _imageForTopic(String title, int seed) {
    final q = Uri.encodeComponent('$title, social media, vibrant, modern');
    return 'https://image.pollinations.ai/prompt/$q?width=780&height=470&nologo=true&seed=$seed';
  }

  List<TrendingTopic> _fallbackTopics() {
    final seed = <Map<String, dynamic>>[
      {'t': 'AI Technology', 'd': 'Latest trends in artificial intelligence', 'h': ['#AI', '#Technology', '#Innovation'], 's': 9.8},
      {'t': 'Sustainable Fashion', 'd': 'Eco-friendly fashion and sustainable brands', 'h': ['#SustainableFashion', '#EcoFriendly', '#Green'], 's': 9.5},
      {'t': 'Mental Health', 'd': 'Wellness and mental health awareness', 'h': ['#MentalHealth', '#Wellness', '#Mindfulness'], 's': 9.0},
      {'t': 'Travel Destinations', 'd': 'Top travel spots and vacation ideas', 'h': ['#Travel', '#Vacation', '#Adventure'], 's': 8.4},
    ];
    return [
      for (var i = 0; i < seed.length; i++)
        TrendingTopic(
          title: seed[i]['t'] as String,
          description: seed[i]['d'] as String,
          imageUrl: _imageForTopic(seed[i]['t'] as String, i),
          hashtags: (seed[i]['h'] as List).cast<String>(),
          trendScore: seed[i]['s'] as double,
        ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingTopics() async {
    setState(() => _isLoading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: widget.apiKey ?? ApiConfig.geminiApiKey,
      );
      const prompt =
          'List 8 currently trending social media content topics across diverse '
          'niches (technology, fashion, wellness, food, travel, business, '
          'entertainment, fitness). For each, give: "title" (2-4 words), '
          '"description" (one short sentence), "hashtags" (array of exactly 3, '
          'each starting with #), and "trendScore" (number between 8.0 and 9.9). '
          'Return ONLY a JSON array of objects, no markdown, no commentary.';

      final resp = await model.generateContent([Content.text(prompt)]);
      var text = (resp.text ?? '').trim();
      // Strip code fences and any leading/trailing prose around the JSON array.
      text = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        text = text.substring(start, end + 1);
      }

      final List<dynamic> data = jsonDecode(text);
      final topics = <TrendingTopic>[];
      for (var i = 0; i < data.length; i++) {
        final t = data[i] as Map<String, dynamic>;
        final title = (t['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        final tags = (t['hashtags'] as List?)
                ?.map((e) => e.toString().startsWith('#') ? e.toString() : '#${e.toString()}')
                .toList() ??
            <String>[];
        final score = (t['trendScore'] is num)
            ? (t['trendScore'] as num).toDouble()
            : 8.5;
        topics.add(TrendingTopic(
          title: title,
          description: (t['description'] ?? '').toString().trim(),
          imageUrl: _imageForTopic(title, i),
          hashtags: tags,
          trendScore: score,
        ));
      }
      _allTopics = topics.isNotEmpty ? topics : _fallbackTopics();
    } catch (e) {
      debugPrint('Trending generation failed, using fallback: $e');
      _allTopics = _fallbackTopics();
    }

    if (mounted) {
      setState(() {
        _filteredTopics = List.from(_allTopics);
        _isLoading = false;
      });
    }
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
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF572D74)),
                          SizedBox(height: 16),
                          Text('Finding trending topics...'),
                        ],
                      ),
                    )
                  : _filteredTopics.isEmpty
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF572D74)),
            tooltip: 'Refresh topics',
            onPressed: _isLoading ? null : _loadTrendingTopics,
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

