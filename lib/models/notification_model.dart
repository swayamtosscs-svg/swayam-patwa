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
    // Debug print to see what data we're getting
    print('NotificationModel.fromJson: $json');
    
    // Extract follower information from the main JSON if available
    Map<String, dynamic>? enhancedData = json['data'];
    
    // If this is a notification with user info, try to extract user info from main JSON
    final notificationType = (json['type'] ?? '').toLowerCase();
    if (notificationType == 'follow' || 
        notificationType == 'like' || 
        notificationType == 'comment' ||
        notificationType == 'video' ||
        notificationType == 'reel' ||
        notificationType == 'share' ||
        notificationType == 'mention') {
      enhancedData = enhancedData ?? <String, dynamic>{};
      
      // Try to get user info from various possible locations
      final userName = json['followerName'] ?? 
                      json['follower_name'] ?? 
                      json['userName'] ?? 
                      json['user_name'] ?? 
                      json['name'] ?? 
                      json['username'] ?? 
                      json['fullName'] ?? 
                      json['full_name'] ?? 
                      json['posterName'] ?? 
                      json['poster_name'] ?? 
                      json['authorName'] ?? 
                      json['author_name'] ?? '';
      
      final userId = json['followerId'] ?? 
                    json['follower_id'] ?? 
                    json['userId'] ?? 
                    json['user_id'] ?? 
                    json['posterId'] ?? 
                    json['poster_id'] ?? 
                    json['authorId'] ?? 
                    json['author_id'] ?? '';
      
      final userProfileImage = json['followerProfileImage'] ?? 
                              json['follower_profile_image'] ?? 
                              json['profileImage'] ?? 
                              json['profile_image'] ?? 
                              json['avatar'] ?? 
                              json['posterProfileImage'] ?? 
                              json['poster_profile_image'] ?? 
                              json['authorProfileImage'] ?? 
                              json['author_profile_image'] ?? '';
      
      // Add user info to data if found
      if (userName.isNotEmpty) {
        enhancedData!['followerName'] = userName;
      }
      if (userId.isNotEmpty) {
        enhancedData!['followerId'] = userId;
      }
      if (userProfileImage.isNotEmpty) {
        enhancedData!['followerProfileImage'] = userProfileImage;
      }
      
      print('NotificationModel.fromJson - Enhanced data for $notificationType notification: $enhancedData');
    }
    
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
      data: enhancedData,
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
      case 'video':
        return '🎥';
      case 'reel':
        return '🎬';
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
      case 'video':
        return '#9C27B0';
      case 'reel':
        return '#E91E63';
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

  /// Get follower name from notification data
  String get followerName {
    if (data != null) {
      print('NotificationModel.followerName - data: $data');
      
      // Try multiple possible field names
      final followerName = data!['followerName'] ?? 
             data!['follower_name'] ?? 
             data!['userName'] ?? 
             data!['user_name'] ?? 
             data!['name'] ?? 
             data!['username'] ?? 
             data!['fullName'] ?? 
             data!['full_name'] ?? 
             data!['posterName'] ?? 
             data!['poster_name'] ?? 
             data!['authorName'] ?? 
             data!['author_name'] ?? '';
      
      print('NotificationModel.followerName - extracted: $followerName');
      return followerName;
    }
    
    // Fallback: Try to extract follower name from the message
    if ((type.toLowerCase() == 'follow' || 
         type.toLowerCase() == 'like' || 
         type.toLowerCase() == 'comment' ||
         type.toLowerCase() == 'video' ||
         type.toLowerCase() == 'reel' ||
         type.toLowerCase() == 'share') && message.isNotEmpty) {
      
      // Look for patterns like "John Doe started following you", "John Doe liked your post", etc.
      final patterns = [
        RegExp(r'^([^]+?)\s+started\s+following\s+you', caseSensitive: false),
        RegExp(r'^([^]+?)\s+liked\s+your\s+post', caseSensitive: false),
        RegExp(r'^([^]+?)\s+commented\s+on\s+your\s+post', caseSensitive: false),
        RegExp(r'^([^]+?)\s+posted\s+a\s+new\s+video', caseSensitive: false),
        RegExp(r'^([^]+?)\s+shared\s+your\s+post', caseSensitive: false),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(message);
        if (match != null && match.group(1) != null) {
          final extractedName = match.group(1)!.trim();
          print('NotificationModel.followerName - extracted from message: $extractedName');
          return extractedName;
        }
      }
    }
    
    return '';
  }

  /// Get follower ID from notification data
  String get followerId {
    if (data != null) {
      return data!['followerId'] ?? 
             data!['follower_id'] ?? 
             data!['userId'] ?? 
             data!['user_id'] ?? '';
    }
    return '';
  }

  /// Get follower profile image from notification data
  String get followerProfileImage {
    if (data != null) {
      return data!['followerProfileImage'] ?? 
             data!['follower_profile_image'] ?? 
             data!['profileImage'] ?? 
             data!['profile_image'] ?? 
             data!['avatar'] ?? '';
    }
    return '';
  }

  /// Get formatted message with follower name
  String get formattedMessage {
    if (type.toLowerCase() == 'follow') {
      if (followerName.isNotEmpty) {
        return '$followerName started following you';
      } else if (message.isNotEmpty) {
        return message;
      } else {
        return 'Someone started following you';
      }
    } else if (type.toLowerCase() == 'like') {
      if (followerName.isNotEmpty) {
        return '$followerName liked your post';
      } else if (message.isNotEmpty) {
        return message;
      } else {
        return 'Someone liked your post';
      }
    } else if (type.toLowerCase() == 'comment') {
      if (followerName.isNotEmpty) {
        return '$followerName commented on your post';
      } else if (message.isNotEmpty) {
        return message;
      } else {
        return 'Someone commented on your post';
      }
    } else if (type.toLowerCase() == 'video' || type.toLowerCase() == 'reel') {
      if (followerName.isNotEmpty) {
        return '$followerName posted a new video';
      } else if (message.isNotEmpty) {
        return message;
      } else {
        return 'Someone posted a new video';
      }
    } else if (type.toLowerCase() == 'share') {
      if (followerName.isNotEmpty) {
        return '$followerName shared your post';
      } else if (message.isNotEmpty) {
        return message;
      } else {
        return 'Someone shared your post';
      }
    }
    return message.isNotEmpty ? message : 'You have a new notification';
  }

  /// Get display title with user name for follow notifications
  String get displayTitle {
    if (type.toLowerCase() == 'follow' && followerName.isNotEmpty) {
      return 'New Follower';
    }
    return title.isNotEmpty ? title : 'Notification';
  }
}
