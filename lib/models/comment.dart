class Comment {
  final String id;
  final String postId;
  final String username;
  final String commentText;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.username,
    required this.commentText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'username': username,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      username: json['username'] as String,
      commentText: json['comment_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

