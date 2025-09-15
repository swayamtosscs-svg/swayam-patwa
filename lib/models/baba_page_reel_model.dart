// Helper function to construct full URL from relative path
String _constructFullUrl(String url) {
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

class BabaPageReel {
  final String id;
  final String babaPageId;
  final String title;
  final String description;
  final ReelVideo video;
  final ReelThumbnail thumbnail;
  final String category;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabaPageReel({
    required this.id,
    required this.babaPageId,
    required this.title,
    required this.description,
    required this.video,
    required this.thumbnail,
    required this.category,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabaPageReel.fromJson(Map<String, dynamic> json) {
    return BabaPageReel(
      id: json['_id'] ?? json['id'] ?? '',
      babaPageId: json['babaPageId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      video: ReelVideo.fromJson(json['video'] ?? {}),
      thumbnail: ReelThumbnail.fromJson(json['thumbnail'] ?? {}),
      category: json['category'] ?? 'video',
      viewsCount: json['viewsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babaPageId': babaPageId,
      'title': title,
      'description': description,
      'video': video.toJson(),
      'thumbnail': thumbnail.toJson(),
      'category': category,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BabaPageReel copyWith({
    String? id,
    String? babaPageId,
    String? title,
    String? description,
    ReelVideo? video,
    ReelThumbnail? thumbnail,
    String? category,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabaPageReel(
      id: id ?? this.id,
      babaPageId: babaPageId ?? this.babaPageId,
      title: title ?? this.title,
      description: description ?? this.description,
      video: video ?? this.video,
      thumbnail: thumbnail ?? this.thumbnail,
      category: category ?? this.category,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReelVideo {
  final String url;
  final String filename;
  final int size;
  final int duration;
  final String mimeType;
  final String publicId;

  ReelVideo({
    required this.url,
    required this.filename,
    required this.size,
    required this.duration,
    required this.mimeType,
    required this.publicId,
  });

  factory ReelVideo.fromJson(Map<String, dynamic> json) {
    return ReelVideo(
      url: _constructFullUrl(json['url'] ?? ''),
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      duration: json['duration'] ?? 0,
      mimeType: json['mimeType'] ?? 'video/mp4',
      publicId: json['publicId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filename': filename,
      'size': size,
      'duration': duration,
      'mimeType': mimeType,
      'publicId': publicId,
    };
  }
}

class ReelThumbnail {
  final String url;
  final String filename;
  final int size;
  final String mimeType;
  final String publicId;

  ReelThumbnail({
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
    required this.publicId,
  });

  factory ReelThumbnail.fromJson(Map<String, dynamic> json) {
    return ReelThumbnail(
      url: _constructFullUrl(json['url'] ?? ''),
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mimeType'] ?? 'image/jpeg',
      publicId: json['publicId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'publicId': publicId,
    };
  }
}

class ReelPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  ReelPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory ReelPagination.fromJson(Map<String, dynamic> json) {
    return ReelPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
    };
  }
}



