class ReelAuthor {
  final String id;
  final String username;
  final String fullName;
  final String avatar;

  ReelAuthor({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
  });

  factory ReelAuthor.fromJson(Map<String, dynamic> json) {
    return ReelAuthor(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
    };
  }
}

class ReelPost {
  final ReelAuthor author;
  final String content;
  final List<String> images;
  final List<String> videos;
  final List<String> externalUrls;
  final String type;
  final String provider;
  final int duration;
  final String category;
  final String religion;
  final List<String> likes;
  final int likesCount;
  final int commentsCount;
  final List<String> shares;
  final int sharesCount;
  final List<String> saves;
  final int savesCount;
  final bool isActive;
  final String id;
  final DateTime createdAt;
  final List<String> comments;
  final DateTime updatedAt;

  ReelPost({
    required this.author,
    required this.content,
    required this.images,
    required this.videos,
    required this.externalUrls,
    required this.type,
    required this.provider,
    required this.duration,
    required this.category,
    required this.religion,
    required this.likes,
    required this.likesCount,
    required this.commentsCount,
    required this.shares,
    required this.sharesCount,
    required this.saves,
    required this.savesCount,
    required this.isActive,
    required this.id,
    required this.createdAt,
    required this.comments,
    required this.updatedAt,
  });

  factory ReelPost.fromJson(Map<String, dynamic> json) {
    return ReelPost(
      author: ReelAuthor.fromJson(json['author'] ?? {}),
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      externalUrls: List<String>.from(json['externalUrls'] ?? []),
      type: json['type'] ?? '',
      provider: json['provider'] ?? '',
      duration: json['duration'] ?? 0,
      category: json['category'] ?? '',
      religion: json['religion'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      shares: List<String>.from(json['shares'] ?? []),
      sharesCount: json['sharesCount'] ?? 0,
      saves: List<String>.from(json['saves'] ?? []),
      savesCount: json['savesCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      id: json['_id'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      comments: List<String>.from(json['comments'] ?? []),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author.toJson(),
      'content': content,
      'images': images,
      'videos': videos,
      'externalUrls': externalUrls,
      'type': type,
      'provider': provider,
      'duration': duration,
      'category': category,
      'religion': religion,
      'likes': likes,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'shares': shares,
      'sharesCount': sharesCount,
      'saves': saves,
      'savesCount': savesCount,
      'isActive': isActive,
      '_id': id,
      'createdAt': createdAt.toIso8601String(),
      'comments': comments,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ReelUploadResponse {
  final bool success;
  final String message;
  final ReelUploadData data;

  ReelUploadResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ReelUploadResponse.fromJson(Map<String, dynamic> json) {
    return ReelUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ReelUploadData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class ReelUploadData {
  final ReelPost post;

  ReelUploadData({
    required this.post,
  });

  factory ReelUploadData.fromJson(Map<String, dynamic> json) {
    return ReelUploadData(
      post: ReelPost.fromJson(json['post'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post': post.toJson(),
    };
  }
}
