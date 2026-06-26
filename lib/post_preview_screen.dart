import 'dart:io';

import 'package:flutter/material.dart';

import 'instagram_service.dart';
import 'schedule_screen.dart';
import 'widgets/full_screen_image_viewer.dart';

class PostPreviewScreen extends StatefulWidget {
  final File? imageFile;
  final String caption;
  final List<String> tags;
  final String? apiKey;
  final String? imageApiKey;
  final String contentType;

  const PostPreviewScreen({
    super.key,
    this.imageFile,
    required this.caption,
    required this.tags,
    this.apiKey,
    this.imageApiKey,
    this.contentType = 'Social Media Post',
  });

  @override
  State<PostPreviewScreen> createState() => _PostPreviewScreenState();
}

class _PostPreviewScreenState extends State<PostPreviewScreen> {
  bool _isPostingToInstagram = false;
  SocialPlatform? _activePlatform;

  String _buildShareCaption() {
    final tagText = widget.tags.isEmpty ? '' : ' ${widget.tags.join(' ')}';
    return '${widget.caption}$tagText'.trim();
  }

  Future<void> _postToInstagram() async {
    if (_isPostingToInstagram) return;

    final imageFile = widget.imageFile;
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate or add an image first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPostingToInstagram = true;
    });

    try {
      await InstagramService.shareImageToInstagram(
        imageFile: imageFile,
        caption: _buildShareCaption(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caption copied. Paste it in Instagram.'),
          backgroundColor: Colors.green,
        ),
      );
    } on InstagramNotInstalledException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on InstagramShareException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open Instagram: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostingToInstagram = false;
        });
      }
    }
  }

  Future<void> _shareToPlatform(SocialPlatform platform) async {
    if (_isPostingToInstagram) return;

    final imageFile = widget.imageFile;
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate or add an image first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPostingToInstagram = true;
      _activePlatform = platform;
    });

    try {
      await InstagramService.shareImageToPlatform(
        platform: platform,
        imageFile: imageFile,
        caption: _buildShareCaption(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caption copied. Paste it in ${platform.displayName}.'),
          backgroundColor: Colors.green,
        ),
      );
    } on InstagramNotInstalledException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } on InstagramShareException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open ${platform.displayName}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostingToInstagram = false;
          _activePlatform = null;
        });
      }
    }
  }

  Widget _buildPlatformButton({
    required String label,
    required Color color,
    required IconData icon,
    required SocialPlatform platform,
  }) {
    final isBusy = _isPostingToInstagram && _activePlatform == platform;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isPostingToInstagram
            ? null
            : () => _shareToPlatform(platform),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: isBusy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = widget.imageFile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Post Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  if (displayImage != null) {
                    FullScreenImageViewer.show(
                      context,
                      imageFile: displayImage,
                    );
                  } else {
                    FullScreenImageViewer.show(
                      context,
                      assetPath: 'assets/splash.png',
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    children: [
                      if (displayImage != null)
                        Image.file(
                          displayImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Error loading image')),
                        )
                      else
                        Image.asset(
                          'assets/splash.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Error loading image')),
                        ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.caption,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3.0,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                children: widget.tags
                                    .map((tag) => _TagChip(tag: tag))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPostingToInstagram ? null : _postToInstagram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDD2A7B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isPostingToInstagram
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Post to Instagram',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPlatformButton(
                  label: 'Post to Facebook',
                  color: const Color(0xFF1877F2),
                  icon: Icons.facebook,
                  platform: SocialPlatform.facebook,
                ),
                const SizedBox(height: 12),
                _buildPlatformButton(
                  label: 'Post to X / Twitter',
                  color: const Color(0xFF1DA1F2),
                  icon: Icons.alternate_email,
                  platform: SocialPlatform.twitter,
                ),
                const SizedBox(height: 12),
                _buildPlatformButton(
                  label: 'Post to LinkedIn',
                  color: const Color(0xFF0A66C2),
                  icon: Icons.work,
                  platform: SocialPlatform.linkedin,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleScreen(
                            imageFile: widget.imageFile,
                            caption: widget.caption,
                            tags: widget.tags,
                            apiKey: widget.apiKey,
                            imageApiKey: widget.imageApiKey,
                            contentType: widget.contentType,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Publish Now',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Regenerate',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        tag,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
