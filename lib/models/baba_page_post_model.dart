class BabaPagePost {
  final String id;
  final String babaPageId;
  final String content;
  final List<BabaPagePostMedia> media;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isActive;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabaPagePost.fromJson(Map<String, dynamic> json) {
    return BabaPagePost(
      id: json['_id'] ?? json['id'] ?? '',
      babaPageId: json['babaPageId'] ?? '',
      content: json['content'] ?? '',
      media: (json['media'] as List<dynamic>?)
              ?.map((mediaJson) => BabaPagePostMedia.fromJson(mediaJson))
              .toList() ??
          [],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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
    return BabaPagePostMedia(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mimeType'] ?? 'image/jpeg',
      publicId: json['publicId'] ?? '',
    );
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
    return BabaPagePostListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      posts: (json['data']['posts'] as List<dynamic>?)
              ?.map((postJson) => BabaPagePost.fromJson(postJson))
              .toList() ??
          [],
      pagination: json['data']['pagination'] != null
          ? BabaPagePostPagination.fromJson(json['data']['pagination'])
          : null,
    );
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
