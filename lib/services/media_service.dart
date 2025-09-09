import 'dart:convert';
import 'package:http/http.dart' as http;

class MediaItem {
  final String id;
  final String type;
  final String url;
  final String thumbnail;
  final String title;
  final String fileType;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    required this.thumbnail,
    required this.title,
    required this.fileType,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      title: json['title'] ?? '',
      fileType: json['fileType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'thumbnail': thumbnail,
      'title': title,
      'fileType': fileType,
    };
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPrevPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'hasNextPage': hasNextPage,
      'hasPrevPage': hasPrevPage,
    };
  }
}

class MediaResponse {
  final bool success;
  final List<MediaItem> items;
  final PaginationInfo pagination;

  MediaResponse({
    required this.success,
    required this.items,
    required this.pagination,
  });

  factory MediaResponse.fromJson(Map<String, dynamic> json) {
    return MediaResponse(
      success: json['success'] ?? false,
      items: (json['data']['items'] as List<dynamic>?)
              ?.map((item) => MediaItem.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['data']['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': {
        'items': items.map((item) => item.toJson()).toList(),
        'pagination': pagination.toJson(),
      },
    };
  }
}

class MediaService {
  static const String baseUrl = 'https://api-rgram1.vercel.app/api';

  /// Get combined media by type (video, image, etc.)
  static Future<MediaResponse> getCombinedMedia({
    required String type,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/media/combined?type=$type&page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return MediaResponse.fromJson(jsonResponse);
      } else {
        return MediaResponse(
          success: false,
          items: [],
          pagination: PaginationInfo(
            currentPage: 1,
            totalPages: 1,
            totalItems: 0,
            hasNextPage: false,
            hasPrevPage: false,
          ),
        );
      }
    } catch (e) {
      return MediaResponse(
        success: false,
        items: [],
        pagination: PaginationInfo(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          hasNextPage: false,
          hasPrevPage: false,
        ),
      );
    }
  }

  /// Get videos specifically
  static Future<MediaResponse> getVideos({
    int page = 1,
    int limit = 10,
  }) async {
    return getCombinedMedia(type: 'video', page: page, limit: limit);
  }

  /// Get images specifically
  static Future<MediaResponse> getImages({
    int page = 1,
    int limit = 10,
  }) async {
    return getCombinedMedia(type: 'image', page: page, limit: limit);
  }

  /// Search media by title
  static Future<MediaResponse> searchMedia({
    required String query,
    String? type,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$baseUrl/media/search').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return MediaResponse.fromJson(jsonResponse);
      } else {
        return MediaResponse(
          success: false,
          items: [],
          pagination: PaginationInfo(
            currentPage: 1,
            totalPages: 1,
            totalItems: 0,
            hasNextPage: false,
            hasPrevPage: false,
          ),
        );
      }
    } catch (e) {
      return MediaResponse(
        success: false,
        items: [],
        pagination: PaginationInfo(
          currentPage: 1,
          totalPages: 1,
          totalItems: 0,
          hasNextPage: false,
          hasPrevPage: false,
        ),
      );
    }
  }
}
