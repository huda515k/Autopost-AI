import 'package:flutter/material.dart';
import 'autopost_screen.dart';
import 'config/api_config.dart';
import 'theme/app_theme.dart';
import 'services/app_events.dart';
import 'services/user_storage_service.dart';
import 'services/post_service.dart';
import 'services/like_service.dart';
import 'services/comment_service.dart';

class PerformanceScreen extends StatefulWidget {
  final String? apiKey;
  final String? imageApiKey;
  
  const PerformanceScreen({super.key, this.apiKey, this.imageApiKey});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen>
    with WidgetsBindingObserver {
  int _totalPosts = 0;
  int _totalLikes = 0;
  int _totalComments = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  bool _initialized = false;

  // Selected metrics category. 'autopost' shows real in-app data; the platform
  // keys map to SocialPlatform values.
  String _category = 'autopost';

  static const List<Map<String, String>> _categories = [
    {'key': 'autopost', 'label': 'AutoPost AI'},
    {'key': 'instagram', 'label': 'Instagram'},
    {'key': 'twitter', 'label': 'X'},
    {'key': 'facebook', 'label': 'Facebook'},
    {'key': 'linkedin', 'label': 'LinkedIn'},
  ];

  @override
  void initState() {
    super.initState();
    // Reload when the app returns to the foreground...
    WidgetsBinding.instance.addObserver(this);
    // ...and instantly whenever likes/comments/posts change anywhere.
    AppEvents.instance.revision.addListener(_onDataChanged);
    _loadAnalytics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppEvents.instance.revision.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAnalytics();
    }
  }

  void _onDataChanged() {
    if (mounted) _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    // Only show the full-screen spinner on the very first load so live
    // refreshes update the numbers in place without flicker.
    if (!_initialized) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = await UserStorageService.getCurrentUser();
      if (user != null) {
        // Get all posts by current user
        final userPosts = await PostService.getPostsByUser(user.username);

        // Calculate total likes and comments
        int totalLikes = 0;
        int totalComments = 0;
        List<Map<String, dynamic>> activities = [];

        for (var post in userPosts) {
          final likeCount = await LikeService.getLikeCount(post.id);
          final commentCount = await CommentService.getCommentCount(post.id);

          totalLikes += likeCount;
          totalComments += commentCount;

          // Post published event
          activities.add({
            'type': 'post',
            'title': 'New post published',
            'subtitle': _getPostPreview(post),
            'icon': Icons.send,
            'color': AppColors.success,
            'date': post.publishedDate,
          });
        }

        // Likes received on the user's posts
        final recentLikes =
            await LikeService.getRecentLikesForOwner(user.username, limit: 30);
        for (final like in recentLikes) {
          activities.add({
            'type': 'like',
            'title': '${like['actor']} liked your post',
            'subtitle': _previewText(like['caption'] as String?),
            'icon': Icons.favorite,
            'color': AppColors.accent,
            'date': DateTime.tryParse(like['created_at'] as String? ?? '') ??
                DateTime.now(),
          });
        }

        // Comments received on the user's posts
        final recentComments = await CommentService.getRecentCommentsForOwner(
            user.username,
            limit: 30);
        for (final comment in recentComments) {
          activities.add({
            'type': 'comment',
            'title': '${comment['actor']} commented on your post',
            'subtitle': _previewText(comment['comment_text'] as String?),
            'icon': Icons.mode_comment,
            'color': AppColors.primary,
            'date': DateTime.tryParse(comment['created_at'] as String? ?? '') ??
                DateTime.now(),
          });
        }

        // Sort all activities by date (most recent first)
        activities.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        // Attach a human-readable relative time after sorting.
        for (final activity in activities) {
          activity['time'] = _formatTimeAgo(activity['date'] as DateTime);
        }

        if (mounted) {
          setState(() {
            _totalPosts = userPosts.length;
            _totalLikes = totalLikes;
            _totalComments = totalComments;
            _recentActivity = activities.take(15).toList();
            _isLoading = false;
            _initialized = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _initialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialized = true;
        });
      }
    }
  }

  String _previewText(String? text) {
    final value = (text ?? '').trim();
    if (value.length > 50) {
      return '${value.substring(0, 50)}...';
    }
    return value;
  }

  String _getPostPreview(dynamic post) {
    final caption = post.caption ?? '';
    if (caption.length > 50) {
      return '${caption.substring(0, 50)}...';
    }
    return caption;
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadAnalytics,
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector (AutoPost AI + linked platforms)
                    _buildCategorySelector(context),

                    const SizedBox(height: 24),

                    if (_category == 'autopost') ...[
                      // Overview Stats
                      _buildOverviewStats(context),

                      const SizedBox(height: 30),

                      // Chart Section
                      _buildChartSection(context, screenWidth),

                      const SizedBox(height: 30),

                      // Key Metrics
                      _buildKeyMetrics(),

                      const SizedBox(height: 30),

                      // Recent Activity
                      _buildRecentActivity(context),
                    ] else
                      // Real platform analytics require a paid plan — shown honestly.
                      _buildPlatformMetrics(context, _category),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((c) {
          final selected = _category == c['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c['label']!),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _category = c['key']!),
              selectedColor: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Honest state for social platforms: real engagement metrics require a paid
  /// analytics plan, so we never show fabricated counts here.
  Widget _buildPlatformMetrics(BuildContext context, String platformKey) {
    final label = _categories.firstWhere((c) => c['key'] == platformKey)['label']!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.insights, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            '$label metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Live likes, comments and shares from $label come from the platform\'s '
            'analytics API, which is not available on the free plan. Your posts '
            'still publish to $label — only reading the metrics back is locked.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Real-time metrics — not available on free plan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
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
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF572D74)),
            tooltip: 'Home',
            onPressed: () async {
              final user = await UserStorageService.getCurrentUser();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => AutoPostScreen(
                    apiKey: ApiConfig.geminiApiKey,
                    imageApiKey: ApiConfig.imageApiKey,
                    currentUser: user,
                  ),
                ),
                (route) => false,
              );
            },
          ),
          if (widget.apiKey != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF572D74)),
              onPressed: () async {
                final user = await UserStorageService.getCurrentUser();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AutoPostScreen(
                      apiKey: ApiConfig.geminiApiKey,
                      imageApiKey: ApiConfig.imageApiKey,
                      currentUser: user,
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, _formatNumber(_totalPosts), 'Total Posts', Icons.article_outlined),
                    _buildStatItem(context, _formatNumber(_totalLikes), 'Total Likes', Icons.favorite_outline),
                    _buildStatItem(context, _formatNumber(_totalComments), 'Comments', Icons.comment_outlined),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildChartSection(BuildContext context, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Engagement Over Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: screenWidth > 600 ? 2.5 : 1.4,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: _ChartPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _MetricCard(
              value: _formatNumber(_totalLikes),
              label: 'Likes',
              color: const Color(0xFF2C2C2C),
              indicatorColor: Colors.transparent,
              icon: Icons.favorite,
            ),
            _MetricCard(
              value: _formatNumber(_totalComments),
              label: 'Comments',
              color: const Color(0xFF2C2C2C),
              indicatorColor: Colors.transparent,
              icon: Icons.comment,
            ),
            _MetricCard(
              value: _formatNumber(_totalPosts),
              label: 'Posts',
              color: const Color(0xFFF7931E),
              indicatorColor: const Color(0xFFF7931E),
              icon: Icons.article,
            ),
            _MetricCard(
              value: _totalPosts > 0 ? (_totalLikes / _totalPosts).toStringAsFixed(1) : '0',
              label: 'Avg Likes/Post',
              color: const Color(0xFF572D74),
              indicatorColor: const Color(0xFF572D74),
              icon: Icons.trending_up,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_recentActivity.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No recent activity yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._recentActivity.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActivityItem(
                  context,
                  activity['title'] as String,
                  activity['time'] as String,
                  activity['icon'] as IconData,
                  activity['color'] as Color,
                  subtitle: activity['subtitle'] as String?,
                ),
              )),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon, Color color, {String? subtitle}) {
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
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

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color indicatorColor;
  
  final IconData? icon;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
    this.indicatorColor = Colors.transparent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: color.withValues(alpha: 0.7),
                  size: 24,
                )
              else
                const SizedBox(width: 24),
              if (indicatorColor != Colors.transparent)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 20),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              // No suffix
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E8E),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color purpleLineColor = const Color(0xFF572D74);
  final Color orangeLineColor = const Color(0xFFFF857D);
  final Color axisColor = const Color(0xFFB0B0B0);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final List<Offset> purplePoints = [
      const Offset(0.0, 0.45),
      const Offset(0.2, 0.65),
      const Offset(0.4, 0.55),
      const Offset(0.6, 0.75),
      const Offset(0.8, 0.95),
    ];

    final List<Offset> bluePoints = [
      const Offset(0.0, 0.4),
      const Offset(0.2, 0.52),
      const Offset(0.4, 0.4),
      const Offset(0.6, 0.38),
      const Offset(0.8, 0.58),
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw purple line
    paint.color = purpleLineColor;
    final purplePath = Path();
    purplePath.moveTo(purplePoints[0].dx * width, purplePoints[0].dy * height);
    for (int i = 1; i < purplePoints.length; i++) {
      purplePath.lineTo(purplePoints[i].dx * width, purplePoints[i].dy * height);
    }
    canvas.drawPath(purplePath, paint);

    // Draw orange line
    paint.color = orangeLineColor;
    final orangePath = Path();
    orangePath.moveTo(bluePoints[0].dx * width, bluePoints[0].dy * height);
    for (int i = 1; i < bluePoints.length; i++) {
      orangePath.lineTo(bluePoints[i].dx * width, bluePoints[i].dy * height);
    }
    canvas.drawPath(orangePath, paint);

    // Draw points
    paint.style = PaintingStyle.fill;
    for (var point in purplePoints) {
      canvas.drawCircle(
        Offset(point.dx * width, point.dy * height),
        5,
        paint..color = purpleLineColor,
      );
    }
    for (var point in bluePoints) {
      canvas.drawCircle(
        Offset(point.dx * width, point.dy * height),
        5,
        paint..color = orangeLineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
