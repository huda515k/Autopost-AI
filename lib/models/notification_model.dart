class NotificationModel {
  final String id;
  final String type; // 'like', 'comment', 'scheduled_reminder', 'system'
  final String? postId; // For like/comment notifications
  final String? fromUsername; // User who liked/commented (null for system)
  final String? message; // Notification message
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional data (comment text, etc.)

  NotificationModel({
    required this.id,
    required this.type,
    this.postId,
    this.fromUsername,
    this.message,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'post_id': postId,
      'from_username': fromUsername,
      'message': message,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata != null ? metadata.toString() : null,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? metadata;
    if (json['metadata'] != null) {
      try {
        // Simple parsing - in production, use proper JSON parsing
        metadata = {'raw': json['metadata']};
      } catch (e) {
        metadata = null;
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      postId: json['post_id'] as String?,
      fromUsername: json['from_username'] as String?,
      message: json['message'] as String?,
      isRead: (json['is_read'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: metadata,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? postId,
    String? fromUsername,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      fromUsername: fromUsername ?? this.fromUsername,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

