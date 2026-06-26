import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About AutoPost AI'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Section
              _buildAppInfoSection(context),
              
              const SizedBox(height: 30),
              
              // How to Use Section
              _buildHowToUseSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 60, radius: 16),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AutoPost AI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AutoPost AI is an intelligent social media content creation platform powered by advanced AI technology. '
            'It helps you create engaging posts, captions, hashtags, and images for various social media platforms.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('AI-Powered Content Generation', Icons.auto_awesome),
          _buildFeatureItem('Multiple Content Types', Icons.category),
          _buildFeatureItem('Image Generation & Upload', Icons.image),
          _buildFeatureItem('Post Scheduling', Icons.schedule),
          _buildFeatureItem('Social Feed with Likes & Comments', Icons.feed),
          _buildFeatureItem('Trending Topics Discovery', Icons.trending_up),
          _buildFeatureItem('Analytics & Performance Tracking', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF572D74)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How to Use AutoPost AI',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildManualStep(
          step: '1',
          title: 'Create an Account',
          description: 'Sign up with a username, email, and password to get started.',
          context: context,
        ),
        _buildManualStep(
          step: '2',
          title: 'Choose Content Type',
          description: 'Navigate to Create and select your content type (Social Media Post, Blog Article, Instagram, etc.).',
          context: context,
        ),
        _buildManualStep(
          step: '3',
          title: 'Generate Content',
          description: 'Describe what you want to create. AI will generate captions, hashtags, and you can generate or upload images.',
          context: context,
        ),
        _buildManualStep(
          step: '4',
          title: 'Edit & Customize',
          description: 'Review and edit the generated content, add or remove hashtags, and customize the image.',
          context: context,
        ),
        _buildManualStep(
          step: '5',
          title: 'Preview & Publish',
          description: 'Preview your post and choose to publish immediately or schedule it for later.',
          context: context,
        ),
        _buildManualStep(
          step: '6',
          title: 'Engage with Feed',
          description: 'View posts from all users in the Feed, like and comment on posts, and discover trending topics.',
          context: context,
        ),
        _buildManualStep(
          step: '7',
          title: 'Manage Your Profile',
          description: 'Update your profile, link social media accounts, adjust privacy settings, and view your analytics.',
          context: context,
        ),
      ],
    );
  }

  Widget _buildManualStep({
    required String step,
    required String title,
    required String description,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF572D74), Color(0xFFE0185F)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
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

