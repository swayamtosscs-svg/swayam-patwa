import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class BabaPageDPService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/baba-pages';

  /// Upload Display Picture for Baba Ji page
  static Future<Map<String, dynamic>> uploadBabaPageDP({
    required File imageFile,
    required String babaPageId,
    required String token,
  }) async {
    try {
      print('BabaPageDPService: Starting Baba Ji page DP upload for page $babaPageId');
      print('BabaPageDPService: Image file path: ${imageFile.path}');
      
      // Validate token
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
        };
      }
      
      // Validate babaPageId
      if (babaPageId.isEmpty) {
        return {
          'success': false,
          'message': 'Baba page ID is required',
        };
      }
      
      // Validate file
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'message': 'Image file does not exist',
        };
      }
      
      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        return {
          'success': false,
          'message': 'Image file is empty',
        };
      }
      
      // Check file size (max 10MB)
      if (fileSize > 10 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Image file size must be less than 10MB',
        };
      }

      // Validate file extension
      final fileName = imageFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      print('BabaPageDPService: File extension detected: $extension');
      print('BabaPageDPService: File name: $fileName');
      
      // Check if it's a valid image extension
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!validExtensions.contains(extension)) {
        return {
          'success': false,
          'message': 'Unsupported image format. Please use JPG, PNG, GIF, or WEBP.',
        };
      }
      
      // For WebP files, ensure we're sending the correct MIME type
      String mimeType = 'image/jpeg'; // default
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }
      print('BabaPageDPService: MIME type determined: $mimeType');

      print('BabaPageDPService: File validation passed');
      print('BabaPageDPService: File size: $fileSize bytes');
      print('BabaPageDPService: File extension: $extension');

      // Create multipart request
      final url = '$baseUrl/$babaPageId/dp/upload';
      print('BabaPageDPService: Request URL: $url');
      print('BabaPageDPService: Base URL: $baseUrl');
      print('BabaPageDPService: Baba Page ID: $babaPageId');
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      // Don't set Content-Type for multipart requests - let the framework handle it
      print('BabaPageDPService: Request headers: ${request.headers}');
      print('BabaPageDPService: Token length: ${token.length}');
      print('BabaPageDPService: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      // Add the image file with correct MIME type
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', extension),
      );
      request.files.add(multipartFile);
      
      // Add any additional fields if needed
      request.fields['babaPageId'] = babaPageId;
      
      print('BabaPageDPService: Added file: ${multipartFile.field} - ${multipartFile.filename}');
      print('BabaPageDPService: Total files in request: ${request.files.length}');
      print('BabaPageDPService: Request fields: ${request.fields}');
      print('BabaPageDPService: Request files count: ${request.files.length}');
      
      // Send the request
      print('BabaPageDPService: Sending request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      print('BabaPageDPService: Response status: ${response.statusCode}');
      print('BabaPageDPService: Response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('BabaPageDPService: Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
          'error': 'JSON Parse Error',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          
          // Extract data from the response
          final avatarUrl = data['avatar'] as String;
          final publicId = data['publicId'] as String;
          final format = data['format'] as String;
          final width = data['width'] as int;
          final height = data['height'] as int;
          final size = data['size'] as int;
          
          print('BabaPageDPService: Upload successful');
          print('BabaPageDPService: Avatar URL: $avatarUrl');
          print('BabaPageDPService: Public ID: $publicId');
          print('BabaPageDPService: Format: $format');
          print('BabaPageDPService: Dimensions: ${width}x${height}');
          print('BabaPageDPService: Size: $size bytes');
          
          return {
            'success': true,
            'message': 'Baba Ji page display picture uploaded successfully',
            'data': {
              'avatarUrl': avatarUrl,
              'publicId': publicId,
              'format': format,
              'width': width,
              'height': height,
              'size': size,
            },
          };
        }
        
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Upload failed - no data returned',
          'error': 'Upload Failed',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'error': 'Unauthorized',
        };
      } else if (response.statusCode == 413) {
        return {
          'success': false,
          'message': 'File too large. Please choose a smaller image.',
          'error': 'File Too Large',
        };
      } else {
        print('BabaPageDPService: Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to upload Baba Ji page display picture',
          'error': 'Upload Failed',
        };
      }
    } catch (e) {
      print('BabaPageDPService: Upload error: $e');
      return {
        'success': false,
        'message': 'An error occurred while uploading the Baba Ji page display picture: ${e.toString()}',
        'error': 'Upload Error',
      };
    }
  }

  /// Retrieve Display Picture for Baba Ji page
  static Future<Map<String, dynamic>> retrieveBabaPageDP({
    required String babaPageId,
    required String token,
  }) async {
    try {
      print('BabaPageDPService: Starting Baba Ji page DP retrieve for page $babaPageId');
      print('BabaPageDPService: Baba Page ID: $babaPageId');
      print('BabaPageDPService: Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      // Validate token
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
        };
      }
      
      // Validate babaPageId
      if (babaPageId.isEmpty) {
        return {
          'success': false,
          'message': 'Baba page ID is required',
        };
      }

      final url = '$baseUrl/$babaPageId/dp/retrieve';
      print('BabaPageDPService: Retrieve URL: $url');
      
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

      print('BabaPageDPService: Retrieve response status: ${response.statusCode}');
      print('BabaPageDPService: Retrieve response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('BabaPageDPService: Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
          'error': 'JSON Parse Error',
        };
      }

      if (response.statusCode == 200) {
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          
          // Extract data from the response
          final pageId = data['pageId'] as String;
          final pageName = data['pageName'] as String;
          final avatar = data['avatar'] as String?;
          final hasAvatar = data['hasAvatar'] as bool? ?? false;
          final followersCount = data['followersCount'] as int? ?? 0;
          final avatarInfo = data['avatarInfo'] as Map<String, dynamic>?;
          
          print('BabaPageDPService: Retrieve successful');
          print('BabaPageDPService: Page ID: $pageId');
          print('BabaPageDPService: Page Name: $pageName');
          print('BabaPageDPService: Avatar: $avatar');
          print('BabaPageDPService: Has Avatar: $hasAvatar');
          print('BabaPageDPService: Followers Count: $followersCount');
          
          return {
            'success': true,
            'message': 'Baba Ji page display picture retrieved successfully',
            'data': {
              'pageId': pageId,
              'pageName': pageName,
              'avatar': avatar,
              'hasAvatar': hasAvatar,
              'followersCount': followersCount,
              'avatarInfo': avatarInfo,
            },
          };
        }
        
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Retrieve failed - no data returned',
          'error': 'Retrieve Failed',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'error': 'Unauthorized',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Baba Ji page not found or no display picture available.',
          'error': 'Not Found',
        };
      } else {
        print('BabaPageDPService: Retrieve failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to retrieve Baba Ji page display picture',
          'error': 'Retrieve Failed',
        };
      }
    } catch (e) {
      print('BabaPageDPService: Retrieve error: $e');
      return {
        'success': false,
        'message': 'An error occurred while retrieving the Baba Ji page display picture: ${e.toString()}',
        'error': 'Retrieve Error',
      };
    }
  }

  /// Test API connection for Baba Ji page DP
  static Future<Map<String, dynamic>> testConnection({
    required String babaPageId,
    required String token,
  }) async {
    try {
      print('BabaPageDPService: Testing Baba Ji page DP API connection');
      print('BabaPageDPService: Baba Page ID: $babaPageId');
      print('BabaPageDPService: Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final url = '$baseUrl/$babaPageId';
      print('BabaPageDPService: Test URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Test request timed out');
        },
      );

      print('BabaPageDPService: Test response status: ${response.statusCode}');
      print('BabaPageDPService: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Baba Ji page DP API connection successful',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Baba Ji page DP API connection failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('BabaPageDPService: Test connection error: $e');
      return {
        'success': false,
        'message': 'Baba Ji page DP API connection test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Delete Baba Ji page display picture
  static Future<Map<String, dynamic>> deleteBabaPageDP({
    required String babaPageId,
    required String token,
  }) async {
    try {
      print('BabaPageDPService: Starting Baba Ji page DP delete for page $babaPageId');
      
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

      final url = '$baseUrl/$babaPageId/dp/delete';
      print('BabaPageDPService: Delete URL: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Delete request timed out');
        },
      );

      print('BabaPageDPService: Delete response status: ${response.statusCode}');
      print('BabaPageDPService: Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          print('BabaPageDPService: Delete successful');
          print('BabaPageDPService: Deleted Public ID: ${data['deletedPublicId']}');
          print('BabaPageDPService: Cloudinary Result: ${data['cloudinaryResult']}');
          print('BabaPageDPService: Database Updated: ${data['databaseUpdated']}');
          
          return {
            'success': true,
            'message': 'Baba Ji page display picture deleted successfully',
            'data': {
              'deletedPublicId': data['deletedPublicId'],
              'cloudinaryResult': data['cloudinaryResult'],
              'cloudinarySuccess': data['cloudinarySuccess'],
              'databaseUpdated': data['databaseUpdated'],
            },
          };
        } else {
          print('BabaPageDPService: Delete failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to delete display picture',
            'error': 'Delete Failed',
          };
        }
      } else if (response.statusCode == 404) {
        print('BabaPageDPService: DP not found for page $babaPageId');
        return {
          'success': false,
          'message': 'Display picture not found for this Baba Ji page',
          'error': 'Not Found',
        };
      } else if (response.statusCode == 401) {
        print('BabaPageDPService: Unauthorized - invalid token');
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
          'error': 'Unauthorized',
        };
      } else if (response.statusCode == 403) {
        print('BabaPageDPService: Forbidden - insufficient permissions');
        return {
          'success': false,
          'message': 'You do not have permission to delete this display picture',
          'error': 'Forbidden',
        };
      } else {
        print('BabaPageDPService: Delete failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to delete display picture. Server error: ${response.statusCode}',
          'error': 'Server Error',
        };
      }
    } catch (e) {
      print('BabaPageDPService: Delete error: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting the Baba Ji page display picture: ${e.toString()}',
        'error': 'Delete Error',
      };
    }
  }
}
