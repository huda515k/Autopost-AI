import 'dart:io';

class Post {
  final String id;
  final String username;
  final File? imageFile;
  final String caption;
  final List<String> tags;
  final String contentType;
  final DateTime publishedDate;
  final DateTime createdAt;
  int likeCount;
  int commentCount;
  bool isLikedByCurrentUser;

  Post({
    required this.id,
    required this.username,
    this.imageFile,
    required this.caption,
    required this.tags,
    required this.contentType,
    required this.publishedDate,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'image_path': imageFile?.path,
      'caption': caption,
      'tags': tags.join(','),
      'content_type': contentType,
      'published_date': publishedDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      username: json['username'] as String,
      imageFile: json['image_path'] != null
          ? File(json['image_path'] as String)
          : null,
      caption: json['caption'] as String,
      tags: (json['tags'] as String).split(',').where((t) => t.isNotEmpty).toList(),
      contentType: json['content_type'] as String,
      publishedDate: DateTime.parse(json['published_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLikedByCurrentUser: (json['is_liked'] as int? ?? 0) == 1,
    );
  }
}

