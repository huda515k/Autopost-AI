import 'dart:io';

class ScheduledPost {
  final String id;
  final File? imageFile;
  final String caption;
  final List<String> tags;
  final DateTime scheduledDate;
  final bool isPublished;
  final DateTime? publishedDate;
  final String contentType;

  ScheduledPost({
    required this.id,
    this.imageFile,
    required this.caption,
    required this.tags,
    required this.scheduledDate,
    this.isPublished = false,
    this.publishedDate,
    required this.contentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imageFile?.path,
      'caption': caption,
      'tags': tags,
      'scheduledDate': scheduledDate.toIso8601String(),
      'isPublished': isPublished,
      'publishedDate': publishedDate?.toIso8601String(),
      'contentType': contentType,
    };
  }

  factory ScheduledPost.fromJson(Map<String, dynamic> json) {
    return ScheduledPost(
      id: json['id'],
      imageFile: json['imagePath'] != null ? File(json['imagePath']) : null,
      caption: json['caption'],
      tags: List<String>.from(json['tags']),
      scheduledDate: DateTime.parse(json['scheduledDate']),
      isPublished: json['isPublished'] ?? false,
      publishedDate: json['publishedDate'] != null 
          ? DateTime.parse(json['publishedDate']) 
          : null,
      contentType: json['contentType'] ?? 'Social Media Post',
    );
  }
}

