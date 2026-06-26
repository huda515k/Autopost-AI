import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'auth_screen.dart';
import 'models/user_model.dart';
import 'models/social_media_links.dart';
import 'services/user_storage_service.dart';
import 'services/social_media_service.dart';
import 'services/theme_service.dart';
import 'screens/help_support_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'screens/about_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? apiKey;
  final String? imageApiKey;
  final UserModel? currentUser;

  const ProfileScreen({
    super.key,
    this.apiKey,
    this.imageApiKey,
    this.currentUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _linkedinController;
  late TextEditingController _facebookController;
  bool _isEditing = false;
  bool _isEditingSocial = false;
  bool _isDarkMode = false;
  UserModel? _currentUser;
  SocialMediaLinks? _socialMediaLinks;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _instagramController = TextEditingController();
    _linkedinController = TextEditingController();
    _facebookController = TextEditingController();
    _loadUserData();
    _loadThemePreference();
    // Listen to theme changes
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _isDarkMode = ThemeService.instance.isDarkMode;
      });
    }
  }

  Future<void> _loadThemePreference() async {
    final isDark = await ThemeService.instance.getDarkModeAsync();
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }
  }

  Future<void> _toggleTheme() async {
    await ThemeService.instance.toggleTheme();
    // Theme will update automatically via listener
  }


  Future<void> _loadUserData() async {
    final user = widget.currentUser ?? await UserStorageService.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.username;
        _emailController.text = user.email;
        _bioController.text = user.bio ?? '';
      });
      
      // Load social media links
      final links = await SocialMediaService.getSocialMediaLinks(user.username);
      if (links != null) {
        setState(() {
          _socialMediaLinks = links;
          _instagramController.text = links.instagram ?? '';
          _linkedinController.text = links.linkedin ?? '';
          _facebookController.text = links.facebook ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      email: _emailController.text.trim(),
      bio: _bioController.text.trim(),
    );

    final success = await UserStorageService.updateUser(updatedUser);
    
    if (mounted) {
      setState(() {
        _isEditing = false;
        if (success) {
          _currentUser = updatedUser;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Profile updated successfully!'
              : 'Failed to update profile'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSocialMediaLinks() async {
    if (_currentUser == null) return;

    // Preserve existing privacy settings
    final existingLinks = _socialMediaLinks;
    final links = SocialMediaLinks(
      username: _currentUser!.username,
      instagram: _instagramController.text.trim().isEmpty 
          ? null 
          : _instagramController.text.trim(),
      linkedin: _linkedinController.text.trim().isEmpty 
          ? null 
          : _linkedinController.text.trim(),
      facebook: _facebookController.text.trim().isEmpty 
          ? null 
          : _facebookController.text.trim(),
      instagramPublic: existingLinks?.instagramPublic ?? true,
      linkedinPublic: existingLinks?.linkedinPublic ?? true,
      facebookPublic: existingLinks?.facebookPublic ?? true,
      updatedAt: DateTime.now(),
    );

    final success = await SocialMediaService.saveSocialMediaLinks(links);
    
    if (mounted) {
      setState(() {
        _isEditingSocial = false;
        if (success) {
          _socialMediaLinks = links;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Social media links updated successfully!'
              : 'Failed to update social media links'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await UserStorageService.logout();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Section
                    _buildProfileSection(),
                    
                    const SizedBox(height: 30),
                    
                    // Stats Cards
                    _buildStatsCards(),
                    
                    const SizedBox(height: 30),
                    
                    // Social Media Links Section
                    _buildSocialMediaSection(),
                    
                    const SizedBox(height: 30),
                    
                    // Settings Section
                    _buildSettingsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF572D74),
            ),
            onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/splash.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF572D74),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Username (not editable)
          Text(
            _currentUser?.username ?? 'Guest',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Email
          TextField(
            controller: _emailController,
            enabled: _isEditing,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            decoration: InputDecoration(
              border: _isEditing ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ) : InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bio
          TextField(
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            decoration: InputDecoration(
              hintText: 'Add a bio...',
              border: _isEditing ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ) : InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('4.5K', 'Posts', Icons.article_outlined, AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('12.3K', 'Followers', Icons.people_outline, Colors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('890', 'Following', Icons.person_add_outlined, Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
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
            children: [
              Text(
                'Social Media Links',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isEditingSocial ? Icons.check : Icons.edit,
                  color: const Color(0xFF572D74),
                ),
                onPressed: _isEditingSocial 
                    ? _saveSocialMediaLinks 
                    : () => setState(() => _isEditingSocial = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Instagram
          _buildSocialMediaField(
            icon: Icons.camera_alt,
            label: 'Instagram',
            controller: _instagramController,
            hint: '@username',
            color: Colors.purple,
          ),
          
          const SizedBox(height: 12),
          
          // LinkedIn
          _buildSocialMediaField(
            icon: Icons.business,
            label: 'LinkedIn',
            controller: _linkedinController,
            hint: 'linkedin.com/in/username',
            color: AppColors.primary,
          ),
          
          const SizedBox(height: 12),
          
          // Facebook
          _buildSocialMediaField(
            icon: Icons.facebook,
            label: 'Facebook',
            controller: _facebookController,
            hint: 'facebook.com/username',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: _isEditingSocial,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: _isEditingSocial ? Colors.white : Colors.grey[50],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
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
        children: [
          _buildSettingTile(
            icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            title: _isDarkMode ? 'Light Mode' : 'Dark Mode',
            subtitle: 'Switch between light and dark theme',
            onTap: _toggleTheme,
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (_) => _toggleTheme(),
              activeTrackColor: const Color(0xFF572D74),
            ),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacySettingsScreen(
                    currentUser: _currentUser,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: isDestructive
              ? LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!])
              : const LinearGradient(
                  colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : const Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

