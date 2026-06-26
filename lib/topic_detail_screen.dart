import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'config/api_config.dart';
import 'edit_content_screen.dart';
import 'trending_screen.dart';
import 'utils/image_utils.dart';
import 'widgets/full_screen_image_viewer.dart';

class TopicDetailScreen extends StatefulWidget {
  final TrendingTopic topic;

  const TopicDetailScreen({
    super.key,
    required this.topic,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late final GenerativeModel _model;
  List<CaptionOption> _captionOptions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConfig.geminiApiKey,
    );
    _generateCaptionOptions();
  }

  Future<void> _generateCaptionOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prompt = '''
Generate 5 different engaging social media post captions with hashtags for the topic: "${widget.topic.title} - ${widget.topic.description}"

For each caption, provide:
1. A unique, engaging caption (2-3 sentences)
2. 5-7 relevant hashtags

Format your response as:
Caption 1:
[Caption text here]
Hashtags: #tag1 #tag2 #tag3 #tag4 #tag5

Caption 2:
[Caption text here]
Hashtags: #tag1 #tag2 #tag3 #tag4 #tag5

...and so on for all 5 captions.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse the response to extract captions and hashtags
      _captionOptions = _parseCaptionOptions(responseText);

      if (_captionOptions.isEmpty) {
        // Fallback: create default options
        _captionOptions = [
          CaptionOption(
            caption: 'Exciting updates about ${widget.topic.title}! Stay tuned for more.',
            hashtags: widget.topic.hashtags,
          ),
        ];
      }
    } catch (e) {
      // Fallback options on error
      _captionOptions = [
        CaptionOption(
          caption: 'Exciting updates about ${widget.topic.title}! Stay tuned for more.',
          hashtags: widget.topic.hashtags,
        ),
      ];
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<CaptionOption> _parseCaptionOptions(String response) {
    List<CaptionOption> options = [];
    
    // Split by "Caption" markers
    final captionSections = response.split(RegExp(r'Caption\s+\d+:', caseSensitive: false));
    
    for (var section in captionSections) {
      if (section.trim().isEmpty) continue;
      
      // Extract hashtags
      final hashtagMatch = RegExp(r'Hashtags?:\s*([^\n]+)', caseSensitive: false).firstMatch(section);
      List<String> hashtags = [];
      if (hashtagMatch != null) {
        hashtags = RegExp(r'#[\w]+').allMatches(hashtagMatch.group(1)!).map((m) => m.group(0)!).toList();
      }
      
      // Extract caption (everything before "Hashtags:")
      String caption = section.split(RegExp(r'Hashtags?:', caseSensitive: false)).first.trim();
      caption = caption.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
      
      if (caption.isNotEmpty) {
        // If no hashtags found, use topic hashtags
        if (hashtags.isEmpty) {
          hashtags = List.from(widget.topic.hashtags);
        }
        
        options.add(CaptionOption(
          caption: caption,
          hashtags: hashtags,
        ));
      }
    }
    
    // Limit to 5 options
    return options.take(5).toList();
  }

  Future<void> _selectCaption(CaptionOption option) async {
    // Download the topic image
    File? imageFile;
    if (widget.topic.imageUrl.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      imageFile = await ImageUtils.downloadImageFromUrl(widget.topic.imageUrl);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditContentScreen(
            imageFile: imageFile,
            imageUrl: widget.topic.imageUrl, // Pass URL for display
            caption: option.caption,
            tags: option.hashtags,
            apiKey: ApiConfig.geminiApiKey,
            imageApiKey: ApiConfig.imageApiKey,
            contentType: 'Social Media Post',
            topicTitle: widget.topic.title, // Pass topic title for AI image generation
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic Image
                    _buildTopicImage(),
                    
                    // Topic Info
                    _buildTopicInfo(),
                    
                    const SizedBox(height: 30),
                    
                    // Caption Options
                    _buildCaptionOptions(),
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
                colors: [Colors.pink[400]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Topic Details',
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

  Widget _buildTopicImage() {
    return GestureDetector(
      onTap: () {
        FullScreenImageViewer.show(
          context,
          imageUrl: widget.topic.imageUrl,
        );
      },
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: CachedNetworkImage(
          imageUrl: widget.topic.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.purple[400]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.topic.trendScore}',
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.topic.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.topic.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: widget.topic.hashtags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionOptions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Captions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._captionOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return _buildCaptionCard(option, index + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildCaptionCard(CaptionOption option, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _selectCaption(option),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF572D74), Color(0xFFE0185F)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                option.caption,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: option.hashtags.take(7).map((tag) => Chip(
                  label: Text(tag, style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaptionOption {
  final String caption;
  final List<String> hashtags;

  CaptionOption({
    required this.caption,
    required this.hashtags,
  });
}

