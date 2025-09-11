import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class BabaPageReelService {
  static const String baseUrl = 'https://api-rgram1.vercel.app/api/baba-pages';

  /// Upload reel/video for Baba Ji page
  static Future<Map<String, dynamic>> uploadBabaPageReel({
    required File videoFile,
    required File thumbnailFile,
    required String babaPageId,
    required String title,
    required String description,
    required String token,
    String category = 'video',
  }) async {
    try {
      print('BabaPageReelService: Starting Baba Ji page reel upload for page $babaPageId');
      
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
          'error': 'Missing Token',
        };
      }

      if (babaPageId.isEmpty) {
        return {
          'success': false,
          'message': 'Baba Ji page ID is required',
          'error': 'Missing Page ID',
        };
      }

      if (title.isEmpty) {
        return {
          'success': false,
          'message': 'Title is required',
          'error': 'Missing Title',
        };
      }

      if (description.isEmpty) {
        return {
          'success': false,
          'message': 'Description is required',
          'error': 'Missing Description',
        };
      }

      // Validate video file
      if (!await videoFile.exists()) {
        return {
          'success': false,
          'message': 'Video file does not exist',
          'error': 'File Not Found',
        };
      }

      // Validate thumbnail file
      if (!await thumbnailFile.exists()) {
        return {
          'success': false,
          'message': 'Thumbnail file does not exist',
          'error': 'Thumbnail Not Found',
        };
      }

      // Check file sizes
      final videoFileSize = await videoFile.length();
      final thumbnailFileSize = await thumbnailFile.length();
      
      print('BabaPageReelService: Video file size: $videoFileSize bytes');
      print('BabaPageReelService: Thumbnail file size: $thumbnailFileSize bytes');

      // Validate video file size (max 100MB)
      if (videoFileSize > 100 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Video file is too large. Maximum size is 100MB.',
          'error': 'File Too Large',
        };
      }

      // Validate thumbnail file size (max 10MB)
      if (thumbnailFileSize > 10 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Thumbnail file is too large. Maximum size is 10MB.',
          'error': 'Thumbnail Too Large',
        };
      }

      // Get file extensions
      final videoFileName = videoFile.path.split('/').last;
      final thumbnailFileName = thumbnailFile.path.split('/').last;
      final videoExtension = videoFileName.split('.').last.toLowerCase();
      final thumbnailExtension = thumbnailFileName.split('.').last.toLowerCase();
      
      print('BabaPageReelService: Video file: $videoFileName');
      print('BabaPageReelService: Thumbnail file: $thumbnailFileName');
      print('BabaPageReelService: Video extension: $videoExtension');
      print('BabaPageReelService: Thumbnail extension: $thumbnailExtension');

      // Validate video file type
      final validVideoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'];
      if (!validVideoExtensions.contains(videoExtension)) {
        return {
          'success': false,
          'message': 'Unsupported video format. Please use MP4, MOV, AVI, MKV, WebM, or M4V.',
          'error': 'Invalid Video Format',
        };
      }

      // Validate thumbnail file type
      final validThumbnailExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'avif'];
      if (!validThumbnailExtensions.contains(thumbnailExtension)) {
        return {
          'success': false,
          'message': 'Unsupported thumbnail format. Please use JPG, PNG, GIF, WebP, or AVIF.',
          'error': 'Invalid Thumbnail Format',
        };
      }

      // Determine MIME types
      String videoMimeType = 'video/mp4'; // default
      switch (videoExtension) {
        case 'mp4': videoMimeType = 'video/mp4'; break;
        case 'mov': videoMimeType = 'video/quicktime'; break;
        case 'avi': videoMimeType = 'video/x-msvideo'; break;
        case 'mkv': videoMimeType = 'video/x-matroska'; break;
        case 'webm': videoMimeType = 'video/webm'; break;
        case 'm4v': videoMimeType = 'video/x-m4v'; break;
      }

      String thumbnailMimeType = 'image/jpeg'; // default
      switch (thumbnailExtension) {
        case 'jpg': case 'jpeg': thumbnailMimeType = 'image/jpeg'; break;
        case 'png': thumbnailMimeType = 'image/png'; break;
        case 'gif': thumbnailMimeType = 'image/gif'; break;
        case 'webp': thumbnailMimeType = 'image/webp'; break;
        case 'avif': thumbnailMimeType = 'image/avif'; break;
      }

      print('BabaPageReelService: Video MIME type: $videoMimeType');
      print('BabaPageReelService: Thumbnail MIME type: $thumbnailMimeType');

      final url = '$baseUrl/$babaPageId/videos';
      print('BabaPageReelService: Upload URL: $url');
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      // Add video file
      final videoMultipartFile = await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        contentType: MediaType('video', videoExtension),
      );
      request.files.add(videoMultipartFile);
      
      // Add thumbnail file
      final thumbnailMultipartFile = await http.MultipartFile.fromPath(
        'thumbnail',
        thumbnailFile.path,
        contentType: MediaType('image', thumbnailExtension),
      );
      request.files.add(thumbnailMultipartFile);
      
      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['babaPageId'] = babaPageId;

      print('BabaPageReelService: Request fields: ${request.fields}');
      print('BabaPageReelService: Request files count: ${request.files.length}');
      
      print('BabaPageReelService: Sending request...');
      final response = await request.send().timeout(
        const Duration(minutes: 5), // 5 minutes timeout for video upload
        onTimeout: () {
          throw TimeoutException('Video upload request timed out');
        },
      );

      final responseBody = await response.stream.bytesToString();
      print('BabaPageReelService: Response status: ${response.statusCode}');
      print('BabaPageReelService: Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(responseBody);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          print('BabaPageReelService: Upload successful');
          print('BabaPageReelService: Video URL: ${data['video']['url']}');
          print('BabaPageReelService: Thumbnail URL: ${data['thumbnail']['url']}');
          print('BabaPageReelService: Video ID: ${data['id']}');
          
          return {
            'success': true,
            'message': 'Reel uploaded successfully',
            'data': {
              'id': data['id'],
              'babaPageId': data['babaPageId'],
              'title': data['title'],
              'description': data['description'],
              'videoUrl': data['video']['url'],
              'thumbnailUrl': data['thumbnail']['url'],
              'category': data['category'],
              'viewsCount': data['viewsCount'],
              'likesCount': data['likesCount'],
              'commentsCount': data['commentsCount'],
              'sharesCount': data['sharesCount'],
              'isActive': data['isActive'],
              'createdAt': data['createdAt'],
            },
          };
        } else {
          print('BabaPageReelService: Upload failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to upload reel',
            'error': 'Upload Failed',
          };
        }
      } else if (response.statusCode == 401) {
        print('BabaPageReelService: Unauthorized - invalid token');
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
          'error': 'Unauthorized',
        };
      } else if (response.statusCode == 403) {
        print('BabaPageReelService: Forbidden - insufficient permissions');
        return {
          'success': false,
          'message': 'You do not have permission to upload reels to this Baba Ji page',
          'error': 'Forbidden',
        };
      } else if (response.statusCode == 413) {
        print('BabaPageReelService: File too large');
        return {
          'success': false,
          'message': 'File is too large. Please choose a smaller video file.',
          'error': 'File Too Large',
        };
      } else {
        print('BabaPageReelService: Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to upload reel. Server error: ${response.statusCode}',
          'error': 'Server Error',
        };
      }
    } catch (e) {
      print('BabaPageReelService: Upload error: $e');
      return {
        'success': false,
        'message': 'An error occurred while uploading the reel: ${e.toString()}',
        'error': 'Upload Error',
      };
    }
  }

  /// Retrieve reels/videos for Baba Ji page
  static Future<Map<String, dynamic>> getBabaPageReels({
    required String babaPageId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('BabaPageReelService: Starting Baba Ji page reels retrieve for page $babaPageId');
      
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
          'error': 'Missing Token',
        };
      }

      if (babaPageId.isEmpty) {
        return {
          'success': false,
          'message': 'Baba Ji page ID is required',
          'error': 'Missing Page ID',
        };
      }

      final url = '$baseUrl/$babaPageId/videos?page=$page&limit=$limit';
      print('BabaPageReelService: Retrieve URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Retrieve request timed out');
        },
      );

      print('BabaPageReelService: Retrieve response status: ${response.statusCode}');
      print('BabaPageReelService: Retrieve response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          final videos = data['videos'] as List<dynamic>;
          final pagination = data['pagination'];
          
          print('BabaPageReelService: Retrieve successful');
          print('BabaPageReelService: Found ${videos.length} videos');
          print('BabaPageReelService: Pagination: $pagination');
          
          return {
            'success': true,
            'message': 'Reels retrieved successfully',
            'data': {
              'videos': videos,
              'pagination': pagination,
            },
          };
        } else {
          print('BabaPageReelService: Retrieve failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to retrieve reels',
            'error': 'Retrieve Failed',
          };
        }
      } else if (response.statusCode == 401) {
        print('BabaPageReelService: Unauthorized - invalid token');
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
          'error': 'Unauthorized',
        };
      } else if (response.statusCode == 403) {
        print('BabaPageReelService: Forbidden - insufficient permissions');
        return {
          'success': false,
          'message': 'You do not have permission to view reels from this Baba Ji page',
          'error': 'Forbidden',
        };
      } else if (response.statusCode == 404) {
        print('BabaPageReelService: Baba Ji page not found');
        return {
          'success': false,
          'message': 'Baba Ji page not found',
          'error': 'Not Found',
        };
      } else {
        print('BabaPageReelService: Retrieve failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to retrieve reels. Server error: ${response.statusCode}',
          'error': 'Server Error',
        };
      }
    } catch (e) {
      print('BabaPageReelService: Retrieve error: $e');
      return {
        'success': false,
        'message': 'An error occurred while retrieving reels: ${e.toString()}',
        'error': 'Retrieve Error',
      };
    }
  }

  /// Test API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('BabaPageReelService: Testing API connection');
      
      final url = Uri.parse('$baseUrl/test');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection test timed out');
        },
      );

      print('BabaPageReelService: Test response status: ${response.statusCode}');
      print('BabaPageReelService: Test response body: ${response.body}');

      return {
        'success': response.statusCode == 200,
        'message': response.statusCode == 200 
            ? 'API connection successful' 
            : 'API connection failed with status ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('BabaPageReelService: Connection test error: $e');
      return {
        'success': false,
        'message': 'Baba Ji page reel API connection test failed: $e',
        'error': e.toString(),
      };
    }
  }
}
