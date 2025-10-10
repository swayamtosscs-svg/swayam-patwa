import 'dart:convert';

class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorAvatar;
  final String media;
  final String mediaId; // Add media ID for retrieval
  final String type;
  final String? caption; // Add caption/description field
  final List<String> mentions;
  final List<String> hashtags;
  final bool isActive;
  final List<String> views;
  final int viewsCount;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorAvatar,
    required this.media,
    required this.mediaId,
    required this.type,
    this.caption, // Add caption parameter
    required this.mentions,
    required this.hashtags,
    required this.isActive,
    required this.views,
    required this.viewsCount,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    // Handle author object structure
    Map<String, dynamic> authorData = {};
    if (json['author'] is Map<String, dynamic>) {
      authorData = json['author'] as Map<String, dynamic>;
    }
    
    return Story(
      id: json['_id'] ?? '',
      authorId: authorData['_id'] ?? json['author'] ?? '',
      authorName: authorData['fullName'] ?? authorData['username'] ?? 'Unknown User',
      authorUsername: authorData['username'] ?? 'unknown',
      authorAvatar: authorData['avatar'],
      media: json['media'] ?? '',
      mediaId: json['mediaId'] ?? json['_id'] ?? '', // Use media ID if available, fallback to story ID
      type: json['type'] ?? '',
      caption: json['caption'] ?? json['description'], // Add caption field
      mentions: List<String>.from(json['mentions'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      isActive: json['isActive'] ?? false,
      views: List<String>.from(json['views'] ?? []),
      viewsCount: json['viewsCount'] ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'author': {
        '_id': authorId,
        'fullName': authorName,
        'username': authorUsername,
        'avatar': authorAvatar,
      },
      'media': media,
      'type': type,
      'caption': caption, // Add caption field
      'mentions': mentions,
      'hashtags': hashtags,
      'isActive': isActive,
      'views': views,
      'viewsCount': viewsCount,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Story copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    String? media,
    String? mediaId,
    String? type,
    String? caption, // Add caption parameter
    List<String>? mentions,
    List<String>? hashtags,
    bool? isActive,
    List<String>? views,
    int? viewsCount,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Story(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      media: media ?? this.media,
      mediaId: mediaId ?? this.mediaId,
      type: type ?? this.type,
      caption: caption ?? this.caption, // Add caption field
      mentions: mentions ?? this.mentions,
      hashtags: hashtags ?? this.hashtags,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      viewsCount: viewsCount ?? this.viewsCount,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Story(id: $id, author: $authorName, media: $media, type: $type, isActive: $isActive, viewsCount: $viewsCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Story && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class StoryUploadResponse {
  final bool success;
  final String message;
  final Story? story;

  StoryUploadResponse({
    required this.success,
    required this.message,
    this.story,
  });

  factory StoryUploadResponse.fromJson(Map<String, dynamic> json) {
    print('StoryUploadResponse: Parsing JSON: $json');
    
    // Simple success check - just use what the API gives us
    bool isSuccess = json['success'] == true;
    print('StoryUploadResponse: Success from API: $isSuccess');
    
    return StoryUploadResponse(
      success: isSuccess,
      message: json['message'] ?? '',
      story: json['data'] != null && json['data']['story'] != null
          ? Story.fromJson(json['data']['story'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': story != null ? {'story': story!.toJson()} : null,
    };
  }
}
