import 'dart:convert';

class BabaPageStory {
  final String id;
  final String babaPageId;
  final String content;
  final BabaPageStoryMedia media;
  final int viewsCount;
  final int likesCount;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabaPageStory({
    required this.id,
    required this.babaPageId,
    required this.content,
    required this.media,
    required this.viewsCount,
    required this.likesCount,
    required this.isActive,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabaPageStory.fromJson(Map<String, dynamic> json) {
    return BabaPageStory(
      id: json['_id'] ?? json['id'] ?? '',
      babaPageId: json['babaPageId'] ?? '',
      content: json['content'] ?? '',
      media: BabaPageStoryMedia.fromJson(json['media'] ?? {}),
      viewsCount: json['viewsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      isActive: json['isActive'] ?? false,
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babaPageId': babaPageId,
      'content': content,
      'media': media.toJson(),
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'isActive': isActive,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BabaPageStory(id: $id, content: $content, viewsCount: $viewsCount, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BabaPageStory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class BabaPageStoryMedia {
  final String type;
  final String url;
  final String filename;
  final int size;
  final String mimeType;
  final String publicId;

  BabaPageStoryMedia({
    required this.type,
    required this.url,
    required this.filename,
    required this.size,
    required this.mimeType,
    required this.publicId,
  });

  factory BabaPageStoryMedia.fromJson(Map<String, dynamic> json) {
    String url = json['url'] ?? '';
    
    // Convert relative URL to absolute URL
    if (url.isNotEmpty && url.startsWith('/uploads/')) {
      url = 'http://103.14.120.163:8081$url';
    }
    
    return BabaPageStoryMedia(
      type: json['type'] ?? '',
      url: url,
      filename: json['filename'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'publicId': publicId,
    };
  }

  @override
  String toString() {
    return 'BabaPageStoryMedia(type: $type, url: $url, filename: $filename)';
  }
}

class BabaPageStoryUploadResponse {
  final bool success;
  final String message;
  final BabaPageStory? data;

  BabaPageStoryUploadResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BabaPageStoryUploadResponse.fromJson(Map<String, dynamic> json) {
    print('BabaPageStoryUploadResponse: Parsing JSON: $json');
    
    bool isSuccess = json['success'] == true;
    print('BabaPageStoryUploadResponse: Success from API: $isSuccess');
    
    return BabaPageStoryUploadResponse(
      success: isSuccess,
      message: json['message'] ?? '',
      data: json['data'] != null ? BabaPageStory.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }

  @override
  String toString() {
    return 'BabaPageStoryUploadResponse(success: $success, message: $message, data: $data)';
  }
}
