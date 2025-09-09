class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? imageUrl;
  final String? targetId;
  final String? targetType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    this.targetId,
    this.targetType,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      targetId: json['targetId'] ?? json['target_id'],
      targetType: json['targetType'] ?? json['target_type'],
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'targetId': targetId,
      'targetType': targetType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? imageUrl,
    String? targetId,
    String? targetType,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  /// Get notification icon based on type
  String get icon {
    switch (type.toLowerCase()) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'follow':
        return '👥';
      case 'friend_request':
        return '🤝';
      case 'mention':
        return '📢';
      case 'share':
        return '📤';
      default:
        return '🔔';
    }
  }

  /// Get notification color based on type
  String get color {
    switch (type.toLowerCase()) {
      case 'like':
        return '#FF4757';
      case 'comment':
        return '#2ED573';
      case 'follow':
        return '#3742FA';
      case 'friend_request':
        return '#FFA502';
      case 'mention':
        return '#FF6348';
      case 'share':
        return '#5352ED';
      default:
        return '#6366F1';
    }
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
