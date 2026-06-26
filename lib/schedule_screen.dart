import 'package:flutter/material.dart';
import 'dart:io';
import 'performance_screen.dart';
import 'models/scheduled_post.dart';
import 'models/post.dart';
import 'services/post_storage_service.dart';
import 'services/post_service.dart';
import 'services/user_storage_service.dart';
import 'scheduled_posts_list_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final File? imageFile;
  final String caption;
  final List<String> tags;
  final String? apiKey;
  final String? imageApiKey;
  final String contentType;

  const ScheduleScreen({
    super.key,
    this.imageFile,
    required this.caption,
    required this.tags,
    this.apiKey,
    this.imageApiKey,
    this.contentType = 'Social Media Post',
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPosting = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _schedulePost() async {
    setState(() {
      _isPosting = true;
    });

    // Combine date and time
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Create scheduled post
    final post = ScheduledPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageFile: widget.imageFile,
      caption: widget.caption,
      tags: widget.tags,
      scheduledDate: scheduledDateTime,
      contentType: widget.contentType,
    );

    // Save to storage
    await PostStorageService.saveScheduledPost(post);

    // Simulate scheduling
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isPosting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post scheduled successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to scheduled posts list
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduledPostsListScreen(
            apiKey: widget.apiKey,
            imageApiKey: widget.imageApiKey,
          ),
        ),
      );
    }
  }

  void _postNow() async {
    setState(() {
      _isPosting = true;
    });

    // Get current user
    final currentUser = await UserStorageService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to publish posts'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final postId = now.millisecondsSinceEpoch.toString();

    // Create scheduled post
    final scheduledPost = ScheduledPost(
      id: postId,
      imageFile: widget.imageFile,
      caption: widget.caption,
      tags: widget.tags,
      scheduledDate: now,
      isPublished: true,
      publishedDate: now,
      contentType: widget.contentType,
    );

    // Save to scheduled posts
    await PostStorageService.saveScheduledPost(scheduledPost);

    // Create and save published post
    final publishedPost = Post(
      id: postId,
      username: currentUser.username,
      imageFile: widget.imageFile,
      caption: widget.caption,
      tags: widget.tags,
      contentType: widget.contentType,
      publishedDate: now,
      createdAt: now,
    );

    final saved = await PostService.savePost(publishedPost);

    // Simulate posting
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isPosting = false;
      });

      // Show success or error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved 
              ? 'Post published successfully!'
              : 'Failed to save post. Please try again.'),
          backgroundColor: saved ? Colors.green : Colors.red,
        ),
      );

      // Navigate to performance screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PerformanceScreen(
            apiKey: widget.apiKey,
            imageApiKey: widget.imageApiKey,
          ),
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
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview Card
                    _buildPreviewCard(),
                    
                    const SizedBox(height: 30),
                    
                    // Schedule Section
                    _buildScheduleSection(),
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    _buildActionButtons(),
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
                colors: [Colors.orange[400]!, Colors.deepOrange[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Schedule Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Image Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: widget.imageFile != null && widget.imageFile!.existsSync()
                ? Image.file(
                    widget.imageFile!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                      ),
                    ),
                    child: const Icon(Icons.image, size: 60, color: Colors.white),
                  ),
          ),
          
          // Caption and Tags
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caption,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  children: widget.tags.take(5).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Date & Time',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 20),
        
        // Date Picker
        _buildPickerCard(
          icon: Icons.calendar_today,
          label: 'Date',
          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          onTap: _selectDate,
        ),
        
        const SizedBox(height: 16),
        
        // Time Picker
        _buildPickerCard(
          icon: Icons.access_time,
          label: 'Time',
          value: _selectedTime.format(context),
          onTap: _selectTime,
        ),
        
        const SizedBox(height: 20),
        
        // Scheduled Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF572D74), Color(0xFFE0185F)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post will be published on:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Post Now Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isPosting ? null : _postNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isPosting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Post Now',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Schedule Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isPosting ? null : _schedulePost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF572D74),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isPosting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Schedule Post',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

