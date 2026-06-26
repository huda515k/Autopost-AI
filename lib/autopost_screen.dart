import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:autopost_ai/content_type_screen.dart';
import 'performance_screen.dart';
import 'trending_screen.dart';
import 'profile_screen.dart';
import 'scheduled_posts_list_screen.dart';
import 'feed_screen.dart';
import 'models/user_model.dart';
import 'screens/notifications_screen.dart';
import 'services/notification_service.dart';
import 'services/user_storage_service.dart';
import 'services/post_service.dart';
import 'services/like_service.dart';
import 'services/comment_service.dart';
import 'models/post.dart';

class AutoPostScreen extends StatefulWidget {
  final String apiKey;
  final String? imageApiKey;
  final UserModel? currentUser;
  
  const AutoPostScreen({
    super.key, 
    required this.apiKey, 
    this.imageApiKey,
    this.currentUser,
  });

  @override
  State<AutoPostScreen> createState() => _AutoPostScreenState();
}

class _AutoPostScreenState extends State<AutoPostScreen> {
  int _unreadNotificationCount = 0;
  
  List<Post> _recentPosts = [];
  bool _isLoadingPosts = true;
  int _totalPosts = 0;
  int _totalLikes = 0;
  int _totalComments = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _loadRecentPosts();
    _loadStats();
    // Refresh notification count periodically
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadNotificationCount();
        _loadStats();
      }
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final user = await UserStorageService.getCurrentUser();
      if (user != null) {
        // Get all posts by current user
        final userPosts = await PostService.getPostsByUser(user.username);
        _totalPosts = userPosts.length;

        // Calculate total likes and comments
        int totalLikes = 0;
        int totalComments = 0;

        for (var post in userPosts) {
          final likeCount = await LikeService.getLikeCount(post.id);
          final commentCount = await CommentService.getCommentCount(post.id);
          
          totalLikes += likeCount;
          totalComments += commentCount;
        }

        if (mounted) {
          setState(() {
            _totalLikes = totalLikes;
            _totalComments = totalComments;
            _isLoadingStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Future<void> _loadRecentPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final posts = await PostService.getAllPosts();
      // Get the 5 most recent posts
      final recentPosts = posts.take(5).toList();
      
      if (mounted) {
        setState(() {
          _recentPosts = recentPosts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    final user = await UserStorageService.getCurrentUser();
    if (user != null) {
      final count = await NotificationService.getUnreadCount(user.username);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(context),
            
            // Stats Section
            _buildStatsSection(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _buildQuickActions(context),
                    
                    const SizedBox(height: 30),
                    
                    // Recent Posts Section
                    _buildRecentPostsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(context),
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
          // Logo
          const AppLogo(size: 50, radius: 12),
          
          const SizedBox(width: 12),
          
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AutoPost AI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                Text(
                  'AI-Powered Social Media',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Profile/Notification Icons
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        apiKey: widget.apiKey,
                        imageApiKey: widget.imageApiKey,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                  // Refresh count after returning from notifications
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    apiKey: widget.apiKey,
                    imageApiKey: widget.imageApiKey,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/splash.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF572D74), Color(0xFFE0185F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0185F).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoadingStats
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_formatNumber(_totalPosts), 'Posts', Icons.article_outlined),
                _buildStatItem(_formatNumber(_totalLikes), 'Likes', Icons.favorite_outline),
                _buildStatItem(_formatNumber(_totalComments), 'Comments', Icons.comment_outlined),
              ],
            ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.add_circle,
                title: 'Create Post',
                subtitle: 'New content',
                gradient: const LinearGradient(
                  colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContentTypeScreen(
                        apiKey: widget.apiKey,
                        imageApiKey: widget.imageApiKey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:               _buildActionCard(
                context,
                icon: Icons.schedule,
                title: 'Schedule',
                subtitle: 'Plan ahead',
                gradient: LinearGradient(
                  colors: [Colors.orange[400]!, Colors.deepOrange[400]!],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScheduledPostsListScreen(
                        apiKey: widget.apiKey,
                        imageApiKey: widget.imageApiKey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View stats',
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.teal[400]!],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PerformanceScreen(
                        apiKey: widget.apiKey,
                        imageApiKey: widget.imageApiKey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:               _buildActionCard(
                context,
                icon: Icons.trending_up,
                title: 'Trending',
                subtitle: 'Hot topics',
                gradient: LinearGradient(
                  colors: [Colors.pink[400]!, Colors.purple[400]!],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrendingScreen(
                        apiKey: widget.apiKey,
                        imageApiKey: widget.imageApiKey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPostsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedScreen(
                      apiKey: widget.apiKey,
                      imageApiKey: widget.imageApiKey,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingPosts)
          const Center(child: CircularProgressIndicator())
        else if (_recentPosts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No posts yet. Create your first post!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._recentPosts.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRealPostCard(context, post),
              )),
      ],
    );
  }

  Widget _buildRealPostCard(BuildContext context, Post post) {
    final isBlog = post.contentType.toLowerCase().contains('blog');
    final contentTypeText = isBlog ? 'a blog' : 'on social media';
    final captionPreview = post.caption.length > 80 
        ? '${post.caption.substring(0, 80)}...' 
        : post.caption;
    
    // Extract topic from caption (first few words or tags)
    String topic = '';
    if (post.tags.isNotEmpty) {
      topic = post.tags.first;
    } else if (post.caption.isNotEmpty) {
      final words = post.caption.split(' ');
      topic = words.length > 3 ? words.take(3).join(' ') : post.caption;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      ),
                    ),
                    Text(
                      'posted $contentTypeText${topic.isNotEmpty ? ' about: $topic' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimeAgo(post.publishedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Caption preview
          Text(
            captionPreview,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Stats
          Row(
            children: [
              Icon(Icons.favorite_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBlog 
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.contentType,
                  style: TextStyle(
                    fontSize: 11,
                    color: isBlog ? AppColors.primary : Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }


  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.search, 'Explore', false, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrendingScreen(
                      apiKey: widget.apiKey,
                      imageApiKey: widget.imageApiKey,
                    ),
                  ),
                );
              }),
              _buildNavItem(Icons.add_circle_outline, 'Create', false, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContentTypeScreen(
                      apiKey: widget.apiKey,
                      imageApiKey: widget.imageApiKey,
                    ),
                  ),
                );
              }),
              _buildNavItem(Icons.feed, 'Feed', false, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedScreen(
                      apiKey: widget.apiKey,
                      imageApiKey: widget.imageApiKey,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              }),
              _buildNavItem(Icons.person_outline, 'Profile', false, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      apiKey: widget.apiKey,
                      imageApiKey: widget.imageApiKey,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF572D74) : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF572D74) : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
