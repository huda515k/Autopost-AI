import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/user_storage_service.dart';
import '../services/social_media_service.dart';
import '../models/social_media_links.dart';

class UserProfileCard extends StatefulWidget {
  final String username;

  const UserProfileCard({
    super.key,
    required this.username,
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  UserModel? _user;
  SocialMediaLinks? _publicLinks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Get user info
    final allUsers = await UserStorageService.getAllUsers();
    final user = allUsers.firstWhere(
      (u) => u.username == widget.username,
      orElse: () => UserModel(
        username: widget.username,
        password: '',
        email: '',
        createdAt: DateTime.now(),
      ),
    );

    // Get public social media links
    final links = await SocialMediaService.getPublicSocialMediaLinks(widget.username);

    if (mounted) {
      setState(() {
        _user = user;
        _publicLinks = links;
        _isLoading = false;
      });
    }
  }

  Future<void> _openSocialMedia(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF572D74),
                    child: Text(
                      _user?.username[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    _user?.username ?? widget.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Email (if available)
                  if (_user?.email != null && _user!.email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _user!.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  // Bio (if available)
                  if (_user?.bio != null && _user!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _user!.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  
                  // Public Social Media Links
                  if (_publicLinks != null &&
                      ((_publicLinks!.instagram != null && _publicLinks!.instagram!.isNotEmpty) ||
                       (_publicLinks!.linkedin != null && _publicLinks!.linkedin!.isNotEmpty) ||
                       (_publicLinks!.facebook != null && _publicLinks!.facebook!.isNotEmpty))) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Social Media',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        if (_publicLinks!.instagram != null && _publicLinks!.instagram!.isNotEmpty)
                          _buildSocialMediaButton(
                            icon: Icons.camera_alt,
                            label: 'Instagram',
                            color: Colors.purple,
                            onTap: () => _openSocialMedia(_publicLinks!.instagram!),
                          ),
                        if (_publicLinks!.linkedin != null && _publicLinks!.linkedin!.isNotEmpty)
                          _buildSocialMediaButton(
                            icon: Icons.business,
                            label: 'LinkedIn',
                            color: AppColors.primary,
                            onTap: () => _openSocialMedia(_publicLinks!.linkedin!),
                          ),
                        if (_publicLinks!.facebook != null && _publicLinks!.facebook!.isNotEmpty)
                          _buildSocialMediaButton(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            color: AppColors.primary,
                            onTap: () => _openSocialMedia(_publicLinks!.facebook!),
                          ),
                      ],
                    ),
                  ] else if (_publicLinks == null ||
                      ((_publicLinks!.instagram == null || _publicLinks!.instagram!.isEmpty) &&
                       (_publicLinks!.linkedin == null || _publicLinks!.linkedin!.isEmpty) &&
                       (_publicLinks!.facebook == null || _publicLinks!.facebook!.isEmpty))) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'No public social media links',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSocialMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

