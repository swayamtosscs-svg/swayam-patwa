class BabaPagePost {
  final String id;
  final String babaPageId;
  final String content;
  final List<BabaPagePostMedia> media;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isActive;
  final bool isLiked;
  final List<BabaPagePostLike> likes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabaPagePost({
    required this.id,
    required this.babaPageId,
    required this.content,
    required this.media,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isActive,
    this.isLiked = false,
    this.likes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabaPagePost.fromJson(Map<String, dynamic> json) {
    try {
      return BabaPagePost(
        id: json['_id'] ?? json['id'] ?? '',
        babaPageId: json['babaPageId'] ?? '',
        content: json['content'] ?? '',
        media: (json['media'] as List<dynamic>?)
                ?.map((mediaJson) {
                  try {
                    return BabaPagePostMedia.fromJson(mediaJson);
                  } catch (e) {
                    print('BabaPagePost: Error parsing media: $e');
                    return null;
                  }
                })
                .where((media) => media != null)
                .cast<BabaPagePostMedia>()
                .toList() ??
            [],
        likesCount: json['likesCount'] ?? 0,
        commentsCount: json['commentsCount'] ?? 0,
        sharesCount: json['sharesCount'] ?? 0,
        isActive: json['isActive'] ?? true,
        isLiked: json['isLiked'] ?? false,
        likes: (json['likes'] as List<dynamic>?)
                ?.map((likeJson) {
                  try {
                    return BabaPagePostLike.fromJson(likeJson);
                  } catch (e) {
                    print('BabaPagePost: Error parsing like: $e');
                    return null;
                  }
                })
                .where((like) => like != null)
                .cast<BabaPagePostLike>()
                .toList() ??
            [],
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('BabaPagePost: Error parsing post: $e');
      print('BabaPagePost: Post data: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    try {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    } catch (e) {
      print('BabaPagePost: Error parsing date: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babaPageId': babaPageId,
      'content': content,
      'media': media.map((m) => m.toJson()).toList(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isActive': isActive,
      'isLiked': isLiked,
      'likes': likes.map((l) => l.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BabaPagePost copyWith({
    String? id,
    String? babaPageId,
    String? content,
    List<BabaPagePostMedia>? media,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isActive,
    bool? isLiked,
    List<BabaPagePostLike>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabaPagePost(
      id: id ?? this.id,
      babaPageId: babaPageId ?? this.babaPageId,
      content: content ?? this.content,
      media: media ?? this.media,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isActive: isActive ?? this.isActive,
      isLiked: isLiked ?? this.isLiked,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BabaPagePostMedia {
  final String id;
  final String type;
  final String url;
  final String filename;
  final int size;
  final String mimeType;
  final String publicId;

  BabaPagePostMedia({
    required this.id,
    required this.type,
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
    required this.publicId,
  });

  factory BabaPagePostMedia.fromJson(Map<String, dynamic> json) {
    try {
      return BabaPagePostMedia(
        id: json['_id'] ?? json['id'] ?? '',
        type: json['type'] ?? 'image',
        url: _constructFullUrl(json['url'] ?? ''),
        filename: json['filename'] ?? '',
        size: json['size'] ?? 0,
        mimeType: json['mimeType'] ?? 'image/jpeg',
        publicId: json['publicId'] ?? '',
      );
    } catch (e) {
      print('BabaPagePostMedia: Error parsing media: $e');
      print('BabaPagePostMedia: Media data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'publicId': publicId,
    };
  }

  // Helper method to construct full URL from relative path
  static String _constructFullUrl(String url) {
    if (url.isEmpty) return url;
    
    // If it's already a full URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
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

class BabaPagePostRequest {
  final String content;
  final List<String>? mediaFiles; // File paths for upload

  BabaPagePostRequest({
    required this.content,
    this.mediaFiles,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

class BabaPagePostResponse {
  final bool success;
  final String message;
  final BabaPagePost? data;

  BabaPagePostResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BabaPagePostResponse.fromJson(Map<String, dynamic> json) {
    return BabaPagePostResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BabaPagePost.fromJson(json['data']) : null,
    );
  }
}

class BabaPagePostListResponse {
  final bool success;
  final String message;
  final List<BabaPagePost> posts;
  final BabaPagePostPagination? pagination;

  BabaPagePostListResponse({
    required this.success,
    required this.message,
    required this.posts,
    this.pagination,
  });

  factory BabaPagePostListResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different response structures
      List<dynamic> postsData = [];
      Map<String, dynamic>? paginationData;
      
      if (json['data'] != null) {
        if (json['data'] is List) {
          // If data is directly a list of posts
          postsData = json['data'];
        } else if (json['data'] is Map<String, dynamic>) {
          // If data is an object with posts property
          postsData = json['data']['posts'] ?? [];
          paginationData = json['data']['pagination'];
        }
      }
      
      return BabaPagePostListResponse(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
        posts: postsData
            .map((postJson) {
              try {
                return BabaPagePost.fromJson(postJson);
              } catch (e) {
                print('BabaPagePostListResponse: Error parsing post: $e');
                print('BabaPagePostListResponse: Post data: $postJson');
                return null;
              }
            })
            .where((post) => post != null)
            .cast<BabaPagePost>()
            .toList(),
        pagination: paginationData != null
            ? BabaPagePostPagination.fromJson(paginationData)
            : null,
      );
    } catch (e) {
      print('BabaPagePostListResponse: Error parsing response: $e');
      print('BabaPagePostListResponse: Response data: $json');
      return BabaPagePostListResponse(
        success: false,
        message: 'Error parsing response: $e',
        posts: [],
      );
    }
  }
}

class BabaPagePostPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  BabaPagePostPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory BabaPagePostPagination.fromJson(Map<String, dynamic> json) {
    return BabaPagePostPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}

class BabaPagePostLike {
  final String id;
  final String username;
  final String fullName;
  final String avatar;

  BabaPagePostLike({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
  });

  factory BabaPagePostLike.fromJson(Map<String, dynamic> json) {
    try {
      return BabaPagePostLike(
        id: json['_id'] ?? json['id'] ?? '',
        username: json['username'] ?? '',
        fullName: json['fullName'] ?? '',
        avatar: json['avatar'] ?? '',
      );
    } catch (e) {
      print('BabaPagePostLike: Error parsing like: $e');
      print('BabaPagePostLike: Like data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
    };
  }
}
