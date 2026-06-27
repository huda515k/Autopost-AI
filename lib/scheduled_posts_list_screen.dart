import 'package:flutter/material.dart';
import 'models/scheduled_post.dart';
import 'services/post_storage_service.dart';
import 'autopost_screen.dart';
import 'config/api_config.dart';
import 'services/user_storage_service.dart';
import 'widgets/full_screen_image_viewer.dart';

class ScheduledPostsListScreen extends StatefulWidget {
  final String? apiKey;
  final String? imageApiKey;

  const ScheduledPostsListScreen({
    super.key,
    this.apiKey,
    this.imageApiKey,
  });

  @override
  State<ScheduledPostsListScreen> createState() => _ScheduledPostsListScreenState();
}

class _ScheduledPostsListScreenState extends State<ScheduledPostsListScreen> {
  List<ScheduledPost> _scheduledPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    final posts = await PostStorageService.getScheduledPosts();
    
    setState(() {
      _scheduledPosts = posts;
      _isLoading = false;
    });
  }

  Future<void> _deletePost(String id) async {
    await PostStorageService.deleteScheduledPost(id);
    _loadPosts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _scheduledPosts.isEmpty
                      ? _buildEmptyState()
                      : _buildPostsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final navigatorContext = context;
          UserStorageService.getCurrentUser().then((user) {
            if (!mounted) return;
            Navigator.push(
              navigatorContext,
              MaterialPageRoute(
                builder: (context) => AutoPostScreen(
                  apiKey: ApiConfig.geminiApiKey,
                  imageApiKey: ApiConfig.imageApiKey,
                  currentUser: user,
                ),
              ),
            ).then((_) {
              if (mounted) _loadPosts();
            });
          });
        },
        backgroundColor: const Color(0xFF572D74),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create New Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scheduled Posts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF1A1A1A)),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: _loadPosts,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF572D74), Color(0xFFE0185F)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_outlined, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 24),
          Text(
            'No Scheduled Posts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule your posts to publish them later',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _scheduledPosts.length,
        itemBuilder: (context, index) {
          final post = _scheduledPosts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(ScheduledPost post) {
    final isPastDue = post.scheduledDate.isBefore(DateTime.now()) && !post.isPublished;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (post.imageFile != null && post.imageFile!.existsSync())
            GestureDetector(
              onTap: () {
                FullScreenImageViewer.show(
                  context,
                  imageFile: post.imageFile,
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.file(
                  post.imageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: post.isPublished
                            ? Colors.green
                            : isPastDue
                                ? Colors.orange
                                : const Color(0xFF572D74),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.isPublished
                            ? 'Published'
                            : isPastDue
                                ? 'Past Due'
                                : 'Scheduled',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Post'),
                            content: Text('Are you sure you want to delete this scheduled post?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deletePost(post.id);
                                },
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Caption
                Text(
                  post.caption,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Tags
                Wrap(
                  spacing: 8,
                  children: post.tags.take(5).map((tag) => Chip(
                    label: Text(tag, style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.grey[100],
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Schedule Info
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled: ${_formatDateTime(post.scheduledDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                if (post.isPublished && post.publishedDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Published: ${_formatDateTime(post.publishedDate!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == -1) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

