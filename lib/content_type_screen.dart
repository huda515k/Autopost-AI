import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ai_chat_screen.dart';

enum ContentType {
  socialMediaPost,
  blogArticle,
  instagramPost,
  twitterPost,
  linkedinPost,
  facebookPost,
}

class ContentTypeScreen extends StatelessWidget {
  final String apiKey;
  final String? imageApiKey;

  const ContentTypeScreen({super.key, required this.apiKey, this.imageApiKey});

  String _getContentTypeDescription(ContentType type) {
    switch (type) {
      case ContentType.socialMediaPost:
        return 'Create engaging social media content';
      case ContentType.blogArticle:
        return 'Generate blog article ideas and outlines';
      case ContentType.instagramPost:
        return 'Instagram-optimized posts with hashtags';
      case ContentType.twitterPost:
        return 'Twitter/X posts with character limits';
      case ContentType.linkedinPost:
        return 'Professional LinkedIn content';
      case ContentType.facebookPost:
        return 'Facebook posts for engagement';
    }
  }

  String _getContentTypeName(ContentType type) {
    switch (type) {
      case ContentType.socialMediaPost:
        return 'Social Media Post';
      case ContentType.blogArticle:
        return 'Blog Article';
      case ContentType.instagramPost:
        return 'Instagram Post';
      case ContentType.twitterPost:
        return 'Twitter/X Post';
      case ContentType.linkedinPost:
        return 'LinkedIn Post';
      case ContentType.facebookPost:
        return 'Facebook Post';
    }
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.socialMediaPost:
        return Icons.share;
      case ContentType.blogArticle:
        return Icons.article;
      case ContentType.instagramPost:
        return Icons.camera_alt;
      case ContentType.twitterPost:
        return Icons.chat_bubble_outline;
      case ContentType.linkedinPost:
        return Icons.business;
      case ContentType.facebookPost:
        return Icons.thumb_up;
    }
  }

  Gradient _getContentTypeGradient(ContentType type) {
    switch (type) {
      case ContentType.socialMediaPost:
        return const LinearGradient(
          colors: [Color(0xFF572D74), Color(0xFFE0185F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ContentType.blogArticle:
        return LinearGradient(
          colors: [Colors.green[400]!, Colors.teal[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ContentType.instagramPost:
        return LinearGradient(
          colors: [Colors.pink[400]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ContentType.twitterPost:
        return LinearGradient(
          colors: [AppColors.accentLight, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ContentType.linkedinPost:
        return LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ContentType.facebookPost:
        return LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  void _navigateToChat(BuildContext context, ContentType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          apiKey: apiKey,
          imageApiKey: imageApiKey,
          contentType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(context),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    _buildTitleSection(context),
                    
                    const SizedBox(height: 30),
                    
                    // Content Type Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: ContentType.values.map((type) {
                        return _buildContentTypeCard(context, type);
                      }).toList(),
                    ),
                  ],
                ),
              ),
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
        color: Colors.white,
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
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
          
          const SizedBox(width: 12),
          
          // Logo
          const AppLogo(size: 40, radius: 10),
          
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Text(
              'Select Content Type',
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

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Text(
                  'What would you like to create?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a content type to get started',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeCard(BuildContext context, ContentType type) {
    return GestureDetector(
      onTap: () => _navigateToChat(context, type),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with Gradient Background
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: _getContentTypeGradient(type),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getContentTypeIcon(type),
                size: 36,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _getContentTypeName(type),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _getContentTypeDescription(type),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: _getContentTypeGradient(type),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
