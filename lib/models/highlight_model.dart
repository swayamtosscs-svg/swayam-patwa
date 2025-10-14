import 'dart:convert';
import 'story_model.dart';

class Highlight {
  final String id;
  final String name;
  final String description;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorAvatar;
  final List<Story> stories;
  final int storiesCount;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Highlight({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorAvatar,
    required this.stories,
    required this.storiesCount,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    // Handle author object structure
    Map<String, dynamic> authorData = {};
    if (json['author'] is Map<String, dynamic>) {
      authorData = json['author'] as Map<String, dynamic>;
    }
    
    // Parse stories from the API response
    List<Story> stories = [];
    if (json['stories'] != null) {
      final List<dynamic> storiesJson = json['stories'];
      for (var storyJson in storiesJson) {
        try {
          // Construct full URL for media
          final mediaUrl = _constructFullUrl(storyJson['media'] ?? '');
          storyJson['media'] = mediaUrl;
          stories.add(Story.fromJson(storyJson));
        } catch (e) {
          print('Error parsing story in highlight: $e');
        }
      }
    }
    
    return Highlight(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      authorId: authorData['_id'] ?? json['author'] ?? '',
      authorName: authorData['fullName'] ?? authorData['username'] ?? 'Unknown User',
      authorUsername: authorData['username'] ?? 'unknown',
      authorAvatar: authorData['avatar'],
      stories: stories,
      storiesCount: json['storiesCount'] ?? stories.length,
      isPublic: json['isPublic'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'author': {
        '_id': authorId,
        'fullName': authorName,
        'username': authorUsername,
        'avatar': authorAvatar,
      },
      'stories': stories.map((story) => story.toJson()).toList(),
      'storiesCount': storiesCount,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Highlight copyWith({
    String? id,
    String? name,
    String? description,
    String? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    List<Story>? stories,
    int? storiesCount,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      stories: stories ?? this.stories,
      storiesCount: storiesCount ?? this.storiesCount,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Highlight(id: $id, name: $name, storiesCount: $storiesCount, isPublic: $isPublic)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Highlight && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
  
  /// Construct full URL for media files
  static String _constructFullUrl(String url) {
    if (url.isEmpty) {
      return url;
    }
    
    // If it's already a full URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a relative path starting with /assets, construct full URL
    if (url.startsWith('/assets/')) {
      return 'http://103.14.120.163:8081$url';
    }
    
    // If it's a relative path starting with /uploads, construct full URL
    if (url.startsWith('/uploads/')) {
      return 'http://103.14.120.163:8081$url';
    }
    
    // If it's a relative path without leading slash, add it
    if (url.startsWith('uploads/')) {
      return 'http://103.14.120.163:8081/$url';
    }
    
    return url;
  }
}

class HighlightCreateRequest {
  final String name;
  final String description;
  final List<String> storyIds;
  final bool isPublic;

  HighlightCreateRequest({
    required this.name,
    required this.description,
    required this.storyIds,
    required this.isPublic,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'storyIds': storyIds,
      'isPublic': isPublic,
    };
  }
}

class HighlightUpdateRequest {
  final String? name;
  final String? description;

  HighlightUpdateRequest({
    this.name,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    return data;
  }
}

class HighlightAddStoryRequest {
  final String storyId;

  HighlightAddStoryRequest({
    required this.storyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
    };
  }
}

class HighlightRemoveStoryRequest {
  final String storyId;

  HighlightRemoveStoryRequest({
    required this.storyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
    };
  }
}

class HighlightResponse {
  final bool success;
  final String message;
  final Highlight? highlight;

  HighlightResponse({
    required this.success,
    required this.message,
    this.highlight,
  });

  factory HighlightResponse.fromJson(Map<String, dynamic> json) {
    return HighlightResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      highlight: json['data'] != null && json['data']['highlight'] != null
          ? Highlight.fromJson(json['data']['highlight'])
          : null,
    );
  }
}

class HighlightsListResponse {
  final bool success;
  final String message;
  final List<Highlight> highlights;
  final Map<String, dynamic>? pagination;

  HighlightsListResponse({
    required this.success,
    required this.message,
    required this.highlights,
    this.pagination,
  });

  factory HighlightsListResponse.fromJson(Map<String, dynamic> json) {
    List<Highlight> highlights = [];
    if (json['data'] != null && json['data']['highlights'] != null) {
      final List<dynamic> highlightsJson = json['data']['highlights'];
      for (var highlightJson in highlightsJson) {
        try {
          highlights.add(Highlight.fromJson(highlightJson));
        } catch (e) {
          print('Error parsing highlight: $e');
        }
      }
    }

    return HighlightsListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      highlights: highlights,
      pagination: json['data']?['pagination'],
    );
  }
}


