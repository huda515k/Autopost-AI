import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/social_media_links.dart';
import '../services/social_media_service.dart';
import '../services/user_storage_service.dart';
import '../models/user_model.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final UserModel? currentUser;

  const PrivacySettingsScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  SocialMediaLinks? _socialMediaLinks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final user = widget.currentUser ?? await UserStorageService.getCurrentUser();
    if (user != null) {
      final links = await SocialMediaService.getSocialMediaLinks(user.username);
      setState(() {
        _socialMediaLinks = links;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrivacy(String platform, bool isPublic) async {
    final user = widget.currentUser ?? await UserStorageService.getCurrentUser();
    if (user == null || _socialMediaLinks == null) return;

    final updatedLinks = _socialMediaLinks!.copyWith(
      instagramPublic: platform == 'instagram' ? isPublic : _socialMediaLinks!.instagramPublic,
      linkedinPublic: platform == 'linkedin' ? isPublic : _socialMediaLinks!.linkedinPublic,
      facebookPublic: platform == 'facebook' ? isPublic : _socialMediaLinks!.facebookPublic,
      updatedAt: DateTime.now(),
    );

    final success = await SocialMediaService.saveSocialMediaLinks(updatedLinks);
    
    if (mounted) {
      if (success) {
        setState(() {
          _socialMediaLinks = updatedLinks;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update privacy settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.privacy_tip, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Social Media Privacy',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Control which social media links are visible to other users in the feed.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Instagram Privacy
                  if (_socialMediaLinks?.instagram != null && _socialMediaLinks!.instagram!.isNotEmpty)
                    _buildPrivacyCard(
                      platform: 'Instagram',
                      icon: Icons.camera_alt,
                      color: Colors.purple,
                      isPublic: _socialMediaLinks!.instagramPublic,
                      onChanged: (value) => _updatePrivacy('instagram', value),
                    ),
                  
                  // LinkedIn Privacy
                  if (_socialMediaLinks?.linkedin != null && _socialMediaLinks!.linkedin!.isNotEmpty)
                    _buildPrivacyCard(
                      platform: 'LinkedIn',
                      icon: Icons.business,
                      color: AppColors.primary,
                      isPublic: _socialMediaLinks!.linkedinPublic,
                      onChanged: (value) => _updatePrivacy('linkedin', value),
                    ),
                  
                  // Facebook Privacy
                  if (_socialMediaLinks?.facebook != null && _socialMediaLinks!.facebook!.isNotEmpty)
                    _buildPrivacyCard(
                      platform: 'Facebook',
                      icon: Icons.facebook,
                      color: AppColors.primary,
                      isPublic: _socialMediaLinks!.facebookPublic,
                      onChanged: (value) => _updatePrivacy('facebook', value),
                    ),
                  
                  if ((_socialMediaLinks?.instagram == null || _socialMediaLinks!.instagram!.isEmpty) &&
                      (_socialMediaLinks?.linkedin == null || _socialMediaLinks!.linkedin!.isEmpty) &&
                      (_socialMediaLinks?.facebook == null || _socialMediaLinks!.facebook!.isEmpty))
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No social media links added',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add social media links in your profile to manage their privacy settings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPrivacyCard({
    required String platform,
    required IconData icon,
    required Color color,
    required bool isPublic,
    required ValueChanged<bool> onChanged,
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
                  platform,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPublic ? 'Visible to everyone' : 'Private',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isPublic,
            onChanged: onChanged,
                      activeThumbColor: const Color(0xFF572D74),
          ),
        ],
      ),
    );
  }
}

