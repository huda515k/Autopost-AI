import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_content_screen.dart';
import 'content_type_screen.dart';
import 'imagine_ai_service.dart';
import 'free_image_service.dart';
import 'dart:io';
// New Import for the Gemini SDK
import 'package:google_generative_ai/google_generative_ai.dart';
import 'widgets/full_screen_image_viewer.dart';
// Note: 'package:flutter/foundation.dart' was removed as debugPrint is in material.dart

// Chat Message Model
enum MessageSender { user, ai, option }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final File? image;

  ChatMessage({required this.text, required this.sender, this.image});
}

// Main AI Chat Screen
class AIChatScreen extends StatefulWidget {
  final String apiKey;
  final String? imageApiKey;
  final ContentType? contentType;

  const AIChatScreen({
    super.key,
    required this.apiKey,
    this.imageApiKey,
    this.contentType,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State for the chat messages
  late final List<ChatMessage> _messages;

  String _getWelcomeMessage(ContentType type) {
    switch (type) {
      case ContentType.socialMediaPost:
        return "Great! Let's create an engaging social media post. What's the topic or theme you'd like to post about?";
      case ContentType.blogArticle:
        return "Perfect! I'll help you create a blog article. What topic would you like to write about?";
      case ContentType.instagramPost:
        return "Awesome! Let's create an Instagram post. Tell me what you'd like to share - I'll generate a caption with relevant hashtags!";
      case ContentType.twitterPost:
        return "Let's craft a Twitter/X post! What message do you want to share? (I'll keep it within character limits)";
      case ContentType.linkedinPost:
        return "Let's create a professional LinkedIn post. What professional insight or update would you like to share?";
      case ContentType.facebookPost:
        return "Great! Let's create a Facebook post. What would you like to share with your audience?";
    }
  }

  // Build prompt specifically for caption and hashtag generation (Gemini)
  String _buildCaptionPrompt(String originalPrompt, {File? image}) {
    String prompt = originalPrompt;

    // If there's an image, focus on describing it
    if (image != null) {
      if (widget.contentType != null) {
        switch (widget.contentType!) {
          case ContentType.blogArticle:
            prompt =
                "Write a complete, well-structured blog article inspired by this image. "
                "Include a catchy title, an engaging introduction, 3-5 body sections with clear subheadings, "
                "and a conclusion, in a clear and engaging tone (roughly 500-800 words). "
                "The image relates to: $originalPrompt. End with 5-7 relevant hashtags.";
            break;
          case ContentType.instagramPost:
            prompt =
                "Analyze this image and generate an engaging Instagram caption (max 2200 characters) with 5-7 relevant hashtags. The image shows: $originalPrompt";
            break;
          case ContentType.twitterPost:
            prompt =
                "Analyze this image and generate a Twitter/X post (max 280 characters) with 3-5 relevant hashtags. The image shows: $originalPrompt";
            break;
          case ContentType.linkedinPost:
            prompt =
                "Analyze this image and generate a professional LinkedIn post caption with 3-5 relevant hashtags. The image shows: $originalPrompt";
            break;
          case ContentType.facebookPost:
            prompt =
                "Analyze this image and generate a friendly Facebook post caption with 5-7 relevant hashtags. The image shows: $originalPrompt";
            break;
          default:
            prompt =
                "Analyze this image and generate an engaging social media caption with 5-7 relevant hashtags. The image shows: $originalPrompt";
        }
      } else {
        prompt =
            "Analyze this image and generate a caption with 5-7 relevant hashtags. The image shows: $originalPrompt";
      }
    } else {
      // No image - generate caption based on text prompt
      if (widget.contentType != null) {
        switch (widget.contentType!) {
          case ContentType.socialMediaPost:
            prompt =
                "Generate an engaging social media post caption and 5-7 relevant hashtags for the following topic: $originalPrompt. Make it concise and impactful.";
            break;
          case ContentType.blogArticle:
            prompt =
                "Write a complete, well-structured blog article about: $originalPrompt. "
                "Include a catchy title, an engaging introduction, 3-5 body sections with clear subheadings, "
                "and a conclusion. Aim for roughly 500-800 words in a clear, engaging tone. "
                "End with 5-7 relevant hashtags.";
            break;
          case ContentType.instagramPost:
            prompt =
                "Generate an Instagram caption (max 2200 characters) and 5-7 relevant hashtags for: $originalPrompt. Focus on visual appeal and engagement.";
            break;
          case ContentType.twitterPost:
            prompt =
                "Generate a Twitter/X post (max 280 characters) and 3-5 relevant hashtags for: $originalPrompt. Make it punchy and attention-grabbing.";
            break;
          case ContentType.linkedinPost:
            prompt =
                "Generate a professional LinkedIn post caption and 3-5 relevant hashtags for: $originalPrompt. Focus on industry insights or professional updates.";
            break;
          case ContentType.facebookPost:
            prompt =
                "Generate a Facebook post caption and 5-7 relevant hashtags for: $originalPrompt. Make it friendly and shareable.";
            break;
        }
      }
    }
    return prompt;
  }

  // Build prompt specifically for image generation (Imagine AI)
  String _buildImagePrompt(String originalPrompt) {
    // Clean the prompt - remove caption/hashtag generation instructions
    String prompt = originalPrompt
        .replaceAll(
          RegExp(r'generate\s+(a\s+)?(caption|hashtag)', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'for\s+(this|the)\s+(image|picture|photo)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'with\s+\d+\s+hashtags?', caseSensitive: false), '')
        .trim();

    String lowerPrompt = prompt.toLowerCase();

    // For logo/design requests, preserve all key elements
    if (lowerPrompt.contains('logo') ||
        lowerPrompt.contains('tagline') ||
        lowerPrompt.contains('clothing line') ||
        lowerPrompt.contains('design')) {
      // Keep the full prompt but clean it up
      prompt = prompt
          .replaceAll(
            RegExp(
              r'create\s+(an\s+)?instagram\s+post\s+for',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(r'an\s+instagram\s+post', caseSensitive: false),
            '',
          )
          .trim();

      // Ensure key elements are emphasized
      if (!prompt.toLowerCase().contains('logo') &&
          lowerPrompt.contains('logo')) {
        prompt = 'Logo design, $prompt';
      }
      if (!prompt.toLowerCase().contains('tagline') &&
          lowerPrompt.contains('tagline')) {
        prompt = '$prompt, with tagline';
      }
      if (!prompt.toLowerCase().contains('vibrant') &&
          lowerPrompt.contains('vibrant')) {
        prompt = '$prompt, vibrant color scheme';
      }

      return prompt.trim();
    }

    // For blog/article, focus on creating an appropriate editorial image
    if (lowerPrompt.contains('blog') || lowerPrompt.contains('article')) {
      prompt = prompt.replaceAll(
        RegExp(r'blog\s+(on|about|for)', caseSensitive: false),
        '',
      );
      prompt = prompt.replaceAll(
        RegExp(r'article\s+(on|about|for)', caseSensitive: false),
        '',
      );
      prompt = 'Editorial illustration for: $prompt';
    }

    // For Instagram posts, ensure it's formatted correctly
    if (lowerPrompt.contains('instagram post')) {
      prompt = prompt.replaceAll(
        RegExp(r'instagram\s+post\s+for', caseSensitive: false),
        '',
      );
      prompt = prompt.replaceAll(
        RegExp(r'an\s+instagram\s+post', caseSensitive: false),
        '',
      );
    }

    return prompt.trim();
  }

  final ImagePicker _picker = ImagePicker();

  // Gemini Integration Variables
  late final GenerativeModel _model;

  // State for image input and loading
  File? _pickedImage;
  bool _isAITyping = false;
  bool _isPickingImage = false; // Prevent multiple simultaneous picker calls

  @override
  void initState() {
    super.initState();
    // Initialize messages first
    final contentType = widget.contentType;
    if (contentType != null) {
      _messages = [
        ChatMessage(
          text: _getWelcomeMessage(contentType),
          sender: MessageSender.ai,
        ),
      ];
    } else {
      _messages = [
        ChatMessage(
          text:
              "Hello! What type of content would you like to create? Please tell me the topic and goal.",
          sender: MessageSender.ai,
        ),
        ChatMessage(text: "Social Media Post", sender: MessageSender.option),
        ChatMessage(text: "Blog Article Idea", sender: MessageSender.option),
      ];
    }

    // Initialize the model once
    try {
      if (widget.apiKey.isEmpty) {
        debugPrint("Warning: API key is empty");
        _messages.add(
          ChatMessage(
            text: "⚠️ Please enter a valid API key in the login screen.",
            sender: MessageSender.ai,
          ),
        );
        return;
      }
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', // A great model for chat and vision
        apiKey: widget.apiKey,
      );
    } catch (e) {
      // Handle the case where the API key might be missing or invalid
      debugPrint("Gemini API Initialization Error: $e");
      _messages.add(
        ChatMessage(
          text: "⚠️ Error initializing AI. Please check your API key.",
          sender: MessageSender.ai,
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to scroll to the end of the list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // New Function: Call the Gemini API and handle response
  Future<void> _getGeminiResponse(String prompt, {File? image}) async {
    // Start loading state and add a temporary AI message
    setState(() {
      _isAITyping = true;
      _messages.add(
        ChatMessage(text: "Generating content...", sender: MessageSender.ai),
      );
      _scrollToBottom();
    });

    try {
      // Build enhanced prompt for caption/hashtag generation (separate from image generation)
      String enhancedPrompt = _buildCaptionPrompt(prompt, image: image);

      // Build the request parts (text and optional image)
      final List<Part> parts = [TextPart(enhancedPrompt)];

      if (image != null) {
        // Prepare the image for the multimodal model
        final bytes = await image.readAsBytes();

        // Check image type (Gemini supports a wide range, but JPEG/PNG are common)
        final mimeType = _getMimeType(image.path);

        parts.add(DataPart(mimeType, bytes));
      }

      // FIX APPLIED HERE: Use Content.multi(parts) instead of Content.fromParts(parts)
      // Create content from parts
      final content = Content.multi(parts);
      final response = await _model.generateContent([content]);
      final responseText = response.text?.trim();

      // If the model returned no usable text, fall back immediately so the user still gets a caption.
      if (responseText == null || responseText.isEmpty) {
        final fallbackResponse = _buildFallbackCaptionResponse(
          prompt,
          image: image,
        );
        if (mounted) {
          setState(() {
            _isAITyping = false;
            _messages.last = ChatMessage(
              text: fallbackResponse,
              sender: MessageSender.ai,
            );
          });
          await Future.delayed(const Duration(milliseconds: 300));
          _extractAndNavigateToPreview(fallbackResponse, imageToSend: image);
        }
        return;
      }

      // Update the last message with the final response
      setState(() {
        _isAITyping = false;
        // Find and replace the "Generating content..." message
        _messages.last = ChatMessage(
          text: responseText,
          sender: MessageSender.ai,
        );
      });

      // Navigate to preview if we have generated content
      // Check if response contains hashtags, caption, or is a social media post response
      final lowerResponse = responseText.toLowerCase();
      if (lowerResponse.contains("#") ||
          lowerResponse.contains("caption") ||
          lowerResponse.contains("hashtag") ||
          lowerResponse.contains("social media") ||
          widget.contentType != null ||
          image != null) {
        // Small delay to ensure UI is updated
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _extractAndNavigateToPreview(responseText, imageToSend: image);
        }
      }
    } catch (e) {
      // Handle API or network errors by generating a local fallback caption instead of failing.
      debugPrint('❌ Caption generation failed, using fallback: $e');
      final fallbackResponse = _buildFallbackCaptionResponse(
        prompt,
        image: image,
      );

      if (mounted) {
        setState(() {
          _isAITyping = false;
          _messages.last = ChatMessage(
            text: fallbackResponse,
            sender: MessageSender.ai,
          );
        });

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _extractAndNavigateToPreview(fallbackResponse, imageToSend: image);
        }
      }
    }
    _scrollToBottom();
  }

  /// Builds a deterministic caption response so the UX never fails when Gemini is slow or unavailable.
  String _buildFallbackCaptionResponse(String prompt, {File? image}) {
    final contentType = widget.contentType;
    final fallbackCaption = _buildFallbackCaption(
      prompt,
      contentType: contentType,
    );
    final hashtags = _buildFallbackHashtags(prompt, contentType: contentType);

    return '''
Caption:
$fallbackCaption

Hashtags:
${hashtags.join(' ')}
''';
  }

  /// Generates a clean, publishable caption from the user's prompt.
  String _buildFallbackCaption(String prompt, {ContentType? contentType}) {
    final cleaned = prompt
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(r'^(generate|create|make)\s+', caseSensitive: false),
          '',
        )
        .trim();

    switch (contentType) {
      case ContentType.instagramPost:
        return '✨ $cleaned ✨\n\nA fresh Instagram moment worth sharing.';
      case ContentType.twitterPost:
        return '$cleaned. Quick thoughts, big impact.';
      case ContentType.linkedinPost:
        return '$cleaned\n\nSharing a professional update and key insight.';
      case ContentType.facebookPost:
        return '$cleaned\n\nThoughts worth sharing with the community.';
      case ContentType.blogArticle:
        return '$cleaned\n\nHere’s a clear, engaging caption to introduce the topic.';
      case ContentType.socialMediaPost:
      case null:
        return '$cleaned\n\nReady to post and share with your audience.';
    }
  }

  /// Generates a safe set of hashtags when Gemini is unavailable.
  List<String> _buildFallbackHashtags(
    String prompt, {
    ContentType? contentType,
  }) {
    final lowerPrompt = prompt.toLowerCase();
    final tags = <String>{'#ai', '#autopost'};

    if (contentType == ContentType.instagramPost ||
        lowerPrompt.contains('instagram')) {
      tags.add('#instagram');
      tags.add('#instagood');
    }
    if (lowerPrompt.contains('business') ||
        contentType == ContentType.linkedinPost) {
      tags.add('#business');
      tags.add('#linkedin');
    }
    if (lowerPrompt.contains('blog') ||
        contentType == ContentType.blogArticle) {
      tags.add('#blog');
      tags.add('#contentcreator');
    }
    if (lowerPrompt.contains('twitter') ||
        contentType == ContentType.twitterPost) {
      tags.add('#twitter');
      tags.add('#x');
    }
    if (lowerPrompt.contains('facebook') ||
        contentType == ContentType.facebookPost) {
      tags.add('#facebook');
      tags.add('#socialmedia');
    }

    while (tags.length < 5) {
      tags.add('#post');
      tags.add('#content');
      tags.add('#creator');
    }

    return tags.take(7).toList();
  }

  // Simple utility to guess MIME type
  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  // Update _handleSubmitted to be async and use Gemini
  void _handleSubmitted(String text) async {
    final textToSend = text.trim();
    final imageToSend = _pickedImage;

    // Do nothing if no text and no image are present
    if (textToSend.isEmpty && imageToSend == null) return;

    // Clear the input fields immediately
    _textController.clear();
    setState(() {
      _pickedImage = null; // Clear the image state

      // Add the user's message to the chat list
      _messages.add(
        ChatMessage(
          text: textToSend.isEmpty && imageToSend != null
              ? "Generate content for this image."
              : textToSend,
          sender: MessageSender.user,
          image: imageToSend,
        ),
      );
    });

    // Send the message to Gemini
    await _getGeminiResponse(textToSend, image: imageToSend);
  }

  // --- Option tap ---
  void _handleOptionTap(String optionText) {
    _handleSubmitted(optionText);
  }

  // --- Extract data and navigate (new helper) ---
  void _extractAndNavigateToPreview(String aiResponse, {File? imageToSend}) {
    // Extract caption and tags from AI response
    String caption = '';
    List<String> tags = [];

    // Blog articles keep the FULL structured article as the body; only the
    // hashtags are pulled out as tags. The short-caption extractor below would
    // truncate a multi-section article at the first heading, so skip it here.
    if (widget.contentType == ContentType.blogArticle) {
      final hashtags = RegExp(r'#[\w]+')
          .allMatches(aiResponse)
          .map((m) => m.group(0)!)
          .toList();
      // Remove only a trailing block of hashtags from the article body.
      caption = aiResponse.replaceAll(RegExp(r'(\s*#[\w]+)+\s*$'), '').trim();
      if (caption.isEmpty) caption = aiResponse.trim();
      tags = hashtags;
    } else {
      try {
      debugPrint(
        '📝 Extracting caption from: ${aiResponse.substring(0, aiResponse.length > 200 ? 200 : aiResponse.length)}',
      );

      // Try multiple patterns to extract caption
      // Pattern 1: Look for "**1. An engaging social media caption:**" followed by text
      final captionPattern1 = RegExp(
        r'\*\*[0-9]+\.?\s*(?:An engaging|A|The)?\s*(?:social media|Instagram|Twitter|LinkedIn|Facebook)?\s*caption[:\*]*\s*\n(.+?)(?:\n\*\*[0-9]+\.?\s*hashtag|\n---|\n\*\*|\n#|$)',
        caseSensitive: false,
        dotAll: true,
      );

      // Pattern 2: Look for text after "caption:" or "caption is:" or similar
      final captionPattern2 = RegExp(
        r'(?:caption|caption is|engaging caption)[:\*]?\s*\n(.+?)(?:\n\*\*[0-9]+\.?\s*hashtag|\n---|\n\*\*|\n#|$)',
        caseSensitive: false,
        dotAll: true,
      );

      // Pattern 3: Text between first "---" and second "---" or before hashtags
      final captionPattern3 = RegExp(
        r'---\s*\n(.+?)(?:\n---|\n\*\*[0-9]+\.?\s*hashtag|\n\*\*[0-9]+\.?\s*[0-9]+-|$)',
        caseSensitive: false,
        dotAll: true,
      );

      // Pattern 4: Text after "Here's" or "Here is" until hashtags
      final captionPattern4 = RegExp(
        r"(?:Here's|Here is|Here's the).+?caption[^:]*:\s*\n?(.+?)(?:\n\*\*[0-9]+\.?\s*hashtag|\n---|\n#|$)",
        caseSensitive: false,
        dotAll: true,
      );

      var match = captionPattern1.firstMatch(aiResponse);
      if (match != null && match.group(1) != null) {
        caption = match.group(1)!.trim();
      } else {
        match = captionPattern4.firstMatch(aiResponse);
        if (match != null && match.group(1) != null) {
          caption = match.group(1)!.trim();
        } else {
          match = captionPattern2.firstMatch(aiResponse);
          if (match != null && match.group(1) != null) {
            caption = match.group(1)!.trim();
          } else {
            match = captionPattern3.firstMatch(aiResponse);
            if (match != null && match.group(1) != null) {
              caption = match.group(1)!.trim();
            }
          }
        }
      }

      // Clean up markdown formatting
      if (caption.isNotEmpty) {
        caption = caption
            .replaceAll(RegExp(r'\*\*'), '')
            .replaceAll(RegExp(r'\*'), '')
            .replaceAll(RegExp(r'^[0-9]+\.\s*'), '')
            .trim();
      }

      // If still no caption, extract text before hashtags or separators
      if (caption.isEmpty || caption.length < 10) {
        // Remove markdown and get first substantial paragraph
        String cleaned = aiResponse
            .replaceAll(RegExp(r'\*\*'), '')
            .replaceAll(RegExp(r'---'), '')
            .replaceAll(
              RegExp(r"^Here's.*?caption.*?:\\s*", caseSensitive: false),
              '',
            )
            .trim();

        // Split by newlines and find first substantial block (skip headers)
        final lines = cleaned.split('\n');
        bool foundCaptionStart = false;
        for (var line in lines) {
          line = line.trim();

          // Skip header lines
          if (line.toLowerCase().contains('here\'s') ||
              line.toLowerCase().contains('caption, hashtags') ||
              line.toLowerCase().startsWith('**')) {
            foundCaptionStart = true;
            continue;
          }

          // Skip hashtag section headers
          if (line.toLowerCase().contains('hashtag') && line.length < 30) {
            break;
          }

          // Get first substantial line after header
          if (line.isNotEmpty &&
              !line.toLowerCase().contains('hashtag') &&
              !line.toLowerCase().startsWith('#') &&
              line.length > 20) {
            if (foundCaptionStart || caption.isEmpty) {
              caption = line;
              if (caption.length > 50) break; // Got a good caption
            }
          }
        }

        // If still empty, use first substantial text before hashtags
        if (caption.isEmpty || caption.length < 20) {
          // Remove everything before the actual caption content
          String textBeforeHashtags = cleaned.split('#').first.trim();
          // Remove common prefixes
          textBeforeHashtags = textBeforeHashtags
              .replaceAll(
                RegExp(r"^Here's.*?caption.*?:\s*", caseSensitive: false),
                '',
              )
              .replaceAll(RegExp(r'^[0-9]+\.\s*'), '')
              .trim();

          if (textBeforeHashtags.length > 20) {
            // Take first sentence or first 300 chars
            final firstSentence = textBeforeHashtags.split('.').first.trim();
            if (firstSentence.length > 20) {
              caption = firstSentence;
            } else {
              caption = textBeforeHashtags.substring(
                0,
                textBeforeHashtags.length > 300
                    ? 300
                    : textBeforeHashtags.length,
              );
            }
          }
        }
      }

      // Clean up caption - remove extra whitespace, newlines, and unwanted prefixes
      caption = caption
          .replaceAll(RegExp(r'\n+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^,+\s*'), '') // Remove leading commas
          .replaceAll(
            RegExp(r'^hashtags,?\s*', caseSensitive: false),
            '',
          ) // Remove "hashtags," prefix
          .replaceAll(
            RegExp(r'and image description.*$', caseSensitive: false),
            '',
          ) // Remove "and image description" suffix
          .trim();

      // Extract all hashtags
      final tagsMatch = RegExp(
        r'#[\w]+',
      ).allMatches(aiResponse).map((m) => m.group(0)!).toList();

      if (tagsMatch.isNotEmpty) {
        tags = tagsMatch;
      } else {
        // If no hashtags found, add some default ones
        tags = ['#ai', '#autopost', '#socialmedia'];
      }

      // Final validation - if caption is still empty or too short, use fallback
      if (caption.isEmpty || caption.length < 5) {
        // Last resort: extract first substantial paragraph
        // Remove all markdown first
        String cleanResponse = aiResponse
            .replaceAll(RegExp(r'\*\*'), '')
            .replaceAll(RegExp(r'\*'), '')
            .replaceAll(RegExp(r'---'), '')
            .trim();

        // Split by double newlines or separators to get paragraphs
        List<String> paragraphs = cleanResponse.split(RegExp(r'\n\n+'));

        for (var para in paragraphs) {
          para = para.trim();
          // Skip headers and hashtag sections
          if (para.length > 30 &&
              !para.toLowerCase().contains('hashtag') &&
              !para.toLowerCase().startsWith('here\'s') &&
              !para.toLowerCase().startsWith('caption,') &&
              !para.toLowerCase().startsWith('**') &&
              !para.toLowerCase().startsWith('#') &&
              para.split(' ').length > 5) {
            // At least 5 words
            caption = para;
            // Take first sentence if paragraph is too long
            if (caption.length > 200) {
              final firstSentence = caption
                  .split(RegExp(r'[.!?]'))
                  .first
                  .trim();
              if (firstSentence.length > 20) {
                caption = firstSentence;
              } else {
                caption = caption.substring(0, 200);
              }
            }
            break;
          }
        }

        // If still empty, use first 200 chars of cleaned response
        if (caption.isEmpty || caption.length < 5) {
          final firstPart = cleanResponse.split('#').first.trim();
          if (firstPart.length > 20) {
            caption = firstPart.substring(
              0,
              firstPart.length > 300 ? 300 : firstPart.length,
            );
          } else {
            caption = 'Generated content - please edit';
          }
        }
      }

      debugPrint(
        '✅ Final extracted caption: ${caption.substring(0, caption.length > 100 ? 100 : caption.length)}...',
      );
      debugPrint('✅ Caption length: ${caption.length}');
      debugPrint('✅ Extracted tags: $tags');
    } catch (e) {
      debugPrint("❌ Parsing error: $e");
      // Fallback: use first substantial line
      final lines = aiResponse.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isNotEmpty &&
            line.length > 20 &&
            !line.startsWith('*') &&
            !line.startsWith('#')) {
          caption = line.replaceAll(RegExp(r'\*\*'), '').trim();
          break;
        }
      }
      if (caption.isEmpty) {
        caption = aiResponse.split('\n').first.trim();
      }
      tags = ['#ai', '#autopost'];
      }
    }

    // Find the image from messages or use the one passed
    File? imageFile = imageToSend;
    if (imageFile == null) {
      try {
        final userMessageWithImage = _messages.firstWhere(
          (m) => m.sender == MessageSender.user && m.image != null,
          orElse: () =>
              ChatMessage(text: '', sender: MessageSender.user, image: null),
        );
        imageFile = userMessageWithImage.image;
      } catch (e) {
        debugPrint("No image found: $e");
      }
    }

    // Get content type name
    String contentTypeName = 'Social Media Post';
    if (widget.contentType != null) {
      switch (widget.contentType!) {
        case ContentType.socialMediaPost:
          contentTypeName = 'Social Media Post';
          break;
        case ContentType.blogArticle:
          contentTypeName = 'Blog Article';
          break;
        case ContentType.instagramPost:
          contentTypeName = 'Instagram Post';
          break;
        case ContentType.twitterPost:
          contentTypeName = 'Twitter/X Post';
          break;
        case ContentType.linkedinPost:
          contentTypeName = 'LinkedIn Post';
          break;
        case ContentType.facebookPost:
          contentTypeName = 'Facebook Post';
          break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditContentScreen(
          imageFile: imageFile,
          caption: caption,
          tags: tags,
          apiKey: widget.apiKey,
          imageApiKey: widget.imageApiKey,
          contentType: contentTypeName,
        ),
      ),
    );
  }

  // --- Pick image from gallery ---
  Future<void> _pickImage() async {
    // Prevent multiple simultaneous calls
    if (_isPickingImage) {
      debugPrint('⚠️ Image picker already open, ignoring duplicate call');
      return;
    }

    setState(() {
      _isPickingImage = true;
    });

    try {
      debugPrint('📸 Opening image picker...');

      // Try gallery first, if that fails, try both sources
      XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      // If gallery doesn't work, show helpful error message
      if (pickedFile == null) {
        debugPrint(
          '⚠️ Image picker returned null - user may have cancelled or permissions issue',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No image selected. If picker didn\'t open, check app permissions in System Settings > Privacy & Security > Photos.',
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (pickedFile != null) {
        debugPrint('✅ Image picked: ${pickedFile.path}');
        final file = File(pickedFile.path);

        // Verify file exists and is readable
        if (await file.exists()) {
          if (!mounted) return;
          setState(() {
            _pickedImage = file;
            // Pre-populate the text field to encourage a text prompt with the image
            _textController.text =
                "Generate a caption and 5 hashtags for this image. The style should be professional and engaging.";
          });
          // Scroll down to see the preview
          _scrollToBottom();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected successfully!'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          debugPrint('❌ File does not exist: ${pickedFile.path}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Selected file not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('⚠️ No image selected');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Always reset the flag, even if there was an error
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  // --- Generate image using AI ---
  Future<void> _generateImage(String prompt) async {
    // Note: FreeImageService works without API key, but Hugging Face models work better with one

    setState(() {
      _isAITyping = true;
      _messages.add(
        ChatMessage(
          text: "Generating image: $prompt...",
          sender: MessageSender.ai,
        ),
      );
      _scrollToBottom();
    });

    try {
      // Build image-specific prompt (separate from caption generation)
      String imagePrompt = _buildImagePrompt(prompt);
      debugPrint('🖼️ Starting image generation with prompt: $imagePrompt');

      String? imagePath;
      String? failureError;

      debugPrint(
        '🎨 Using Free Image Service with multiple high-quality models...',
      );
      final freeResult = await FreeImageService.generateImage(
        prompt: imagePrompt,
        apiKey: widget.imageApiKey,
      );

      if (freeResult.success) {
        imagePath = freeResult.path;
      } else {
        debugPrint('🔍 FreeImageService failed: ${freeResult.error}');
        // Try Imagine AI as fallback when API key present
        if (widget.imageApiKey != null && widget.imageApiKey!.isNotEmpty) {
          debugPrint(
            '🔄 Free services failed, trying Imagine AI as premium fallback...',
          );
          final imagineResult = await ImagineAIService.generateImage(
            prompt: imagePrompt,
            apiKey: widget.imageApiKey!,
          );
          if (imagineResult.success) {
            imagePath = imagineResult.path;
          } else {
            debugPrint('🖼️ Imagine AI failed: ${imagineResult.error}');
            failureError =
                '${freeResult.error ?? ''}; ${imagineResult.error ?? ''}';
          }
        } else {
          failureError = freeResult.error;
        }
      }

      setState(() {
        _isAITyping = false;
        _messages.removeLast(); // Remove "Generating..." message

        if (imagePath != null) {
          _pickedImage = File(imagePath);
          _messages.add(
            ChatMessage(
              text:
                  "✅ Image generated successfully! Generating caption and hashtags...",
              sender: MessageSender.ai,
              image: _pickedImage,
            ),
          );
          _scrollToBottom();

          // Automatically generate caption and hashtags for the generated image
          // Use the original user prompt for caption generation (not the image prompt)
          String originalPrompt = _textController.text.trim();

          // Generate caption using Gemini (separate from image generation)
          // This ensures caption matches the user's intent, not just the image
          _getGeminiResponse(originalPrompt, image: _pickedImage);
        } else {
          final details = failureError != null && failureError.isNotEmpty
              ? '\nDetails: ${failureError}'
              : '';
          _messages.add(
            ChatMessage(
              text:
                  "❌ Failed to generate image. Possible reasons:\n• Model is loading (wait 30-60 seconds and try again)\n• API key might be invalid\n• Network connection issue\n\nCheck the console/debug logs for details.$details",
              sender: MessageSender.ai,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isAITyping = false;
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            text: "Error generating image: $e",
            sender: MessageSender.ai,
          ),
        );
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat'), centerTitle: true),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          // Typing Indicator
          if (_isAITyping) _buildTypingIndicator(),

          const Divider(height: 1, color: Colors.white30),
          // Input composer
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "AI is typing...",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.sender == MessageSender.user;

    // Option button
    if (message.sender == MessageSender.option) {
      // ... (Option button rendering remains the same)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: _isAITyping
                ? null
                : () => _handleOptionTap(
                    message.text,
                  ), // Disable when AI is typing
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B3E42),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Standard AI/User chat bubble
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF4C4F53)
                    : const Color(0xFF3B3E42),
                borderRadius: BorderRadius.circular(20),
              ),
              child: message.image != null && message.text.isEmpty
                  // If there is only an image, display the image
                  ? GestureDetector(
                      onTap: () {
                        FullScreenImageViewer.show(
                          context,
                          imageFile: message.image,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(message.image!),
                      ),
                    )
                  // Otherwise, display text (and the image if included with text)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.image != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                FullScreenImageViewer.show(
                                  context,
                                  imageFile: message.image,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  message.image!,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Column(
      children: [
        // Image Preview Banner
        if (_pickedImage != null) _buildImagePreview(),

        Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F33),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Row(
            children: [
              // Image upload button
              IconButton(
                icon: const Icon(Icons.image, color: Colors.blueAccent),
                onPressed: (_isAITyping || _isPickingImage)
                    ? null
                    : _pickImage, // Disable while typing or picking
                tooltip: 'Upload image',
              ),
              // Generate image button (if API key available)
              if (widget.imageApiKey != null && widget.imageApiKey!.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.auto_awesome,
                    color: Colors.purpleAccent,
                  ),
                  onPressed: _isAITyping
                      ? null
                      : () {
                          if (_textController.text.trim().isNotEmpty) {
                            _generateImage(_textController.text.trim());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a description to generate an image',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  tooltip: 'Generate image with AI',
                ),
              // Text input
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !_isAITyping, // Disable while typing
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _handleSubmitted,
                ),
              ),
              // Send button
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                // Disable button if AI is typing OR text is empty AND no image is selected
                onPressed:
                    _isAITyping ||
                        (_textController.text.isEmpty && _pickedImage == null)
                    ? null
                    : () => _handleSubmitted(_textController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget to display a preview of the image to be sent
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(color: Color(0xFF2C2F33)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              FullScreenImageViewer.show(context, imageFile: _pickedImage);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                _pickedImage!,
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "Image selected. Ready to send.",
            style: TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _pickedImage = null; // Clear image
                _textController.clear(); // Clear prompt
              });
            },
          ),
        ],
      ),
    );
  }
}
