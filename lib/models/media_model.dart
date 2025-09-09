import 'dart:convert';

class MediaUploadResponse {
  final bool success;
  final MediaData? data;

  MediaUploadResponse({
    required this.success,
    this.data,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? MediaData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class MediaData {
  final String publicId;
  final String url;
  final String secureUrl;
  final String format;
  final String resourceType;
  final int width;
  final int height;
  final List<String> tags;
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaData({
    required this.publicId,
    required this.url,
    required this.secureUrl,
    required this.format,
    required this.resourceType,
    required this.width,
    required this.height,
    required this.tags,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaData.fromJson(Map<String, dynamic> json) {
    return MediaData(
      publicId: json['publicId'] ?? '',
      url: json['url'] ?? '',
      secureUrl: json['secureUrl'] ?? '',
      format: json['format'] ?? '',
      resourceType: json['resourceType'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      id: json['_id'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'url': url,
      'secureUrl': secureUrl,
      'format': format,
      'resourceType': resourceType,
      'width': width,
      'height': height,
      'tags': tags,
      '_id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MediaRetrieveResponse {
  final bool success;
  final List<MediaData> data;
  final PaginationInfo pagination;

  MediaRetrieveResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory MediaRetrieveResponse.fromJson(Map<String, dynamic> json) {
    return MediaRetrieveResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => MediaData.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class PaginationInfo {
  final int total;
  final int page;
  final int pages;

  PaginationInfo({
    required this.total,
    required this.page,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'pages': pages,
    };
  }
}
