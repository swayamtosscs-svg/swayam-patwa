import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DPService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/local-storage';

  /// Test API connection
  static Future<Map<String, dynamic>> testConnection({
    required String userId,
    required String token,
  }) async {
    try {
      print('DPService: Testing API connection');
      print('DPService: User ID: $userId');
      print('DPService: Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      final url = '$baseUrl/list?userId=$userId';
      print('DPService: Test URL: $url');
      
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

      print('DPService: Test response status: ${response.statusCode}');
      print('DPService: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'API connection successful',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'API connection failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('DPService: Test connection error: $e');
      return {
        'success': false,
        'message': 'API connection test failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Upload Display Picture using local storage API
  static Future<Map<String, dynamic>> uploadDP({
    required File imageFile,
    required String userId,
    required String token,
  }) async {
    try {
      print('DPService: Starting DP upload for user $userId');
      print('DPService: Image file path: ${imageFile.path}');
      
      // Validate token
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
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
      print('DPService: File extension detected: $extension');
      print('DPService: File name: $fileName');
      
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
      print('DPService: MIME type determined: $mimeType');

      print('DPService: File validation passed');
      print('DPService: File size: $fileSize bytes');
      print('DPService: File extension: $extension');

      // Create multipart request
      final url = '$baseUrl/upload?userId=$userId';
      print('DPService: Request URL: $url');
      print('DPService: Base URL: $baseUrl');
      print('DPService: User ID: $userId');
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      // Don't set Content-Type for multipart requests - let the framework handle it
      print('DPService: Request headers: ${request.headers}');
      print('DPService: Token length: ${token.length}');
      print('DPService: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      
      // Add the image file with correct MIME type
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', extension),
      );
      request.files.add(multipartFile);
      
      // Add any additional fields if needed
      request.fields['userId'] = userId;
      
      print('DPService: Added file: ${multipartFile.field} - ${multipartFile.filename}');
      print('DPService: Total files in request: ${request.files.length}');
      print('DPService: Request fields: ${request.fields}');
      print('DPService: Request files count: ${request.files.length}');
      
      // Send the request
      print('DPService: Sending request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      print('DPService: Response status: ${response.statusCode}');
      print('DPService: Response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('DPService: Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
          'error': 'JSON Parse Error',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final uploadedFiles = jsonResponse['data']['uploadedFiles'] as List;
          if (uploadedFiles.isNotEmpty) {
            final uploadedFile = uploadedFiles.first;
            
            // Extract data from the response
            final publicUrl = uploadedFile['publicUrl'] as String;
            final fileName = uploadedFile['fileName'] as String;
            final originalName = uploadedFile['originalName'] as String;
            final size = uploadedFile['size'] as int;
            final mimetype = uploadedFile['mimetype'] as String;
            
            // Construct full DP URL
            final dpUrl = 'http://103.14.120.163:8081$publicUrl';
            
            print('DPService: Upload successful');
            print('DPService: DP URL: $dpUrl');
            print('DPService: File name: $fileName');
            print('DPService: Original name: $originalName');
            print('DPService: Size: $size bytes');
            print('DPService: MIME type: $mimetype');
            
            return {
              'success': true,
              'message': 'Display picture uploaded successfully',
              'data': {
                'dpUrl': dpUrl,
                'fileName': fileName,
                'originalName': originalName,
                'size': size,
                'mimetype': mimetype,
                'publicUrl': publicUrl,
              },
            };
          }
        }
        
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Upload failed - no files uploaded',
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
        print('DPService: Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to upload display picture',
          'error': 'Upload Failed',
        };
      }
    } catch (e) {
      print('DPService: Upload error: $e');
      return {
        'success': false,
        'message': 'An error occurred while uploading the display picture: ${e.toString()}',
        'error': 'Upload Error',
      };
    }
  }

  /// Retrieve Display Picture using local storage API
  static Future<Map<String, dynamic>> retrieveDP({
    required String userId,
    required String token,
  }) async {
    try {
      print('DPService: Retrieving DP for user $userId');
      
      // Validate token
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
        };
      }
      
      // Validate userId
      if (userId.isEmpty) {
        return {
          'success': false,
          'message': 'User ID is required',
        };
      }
      
      final url = '$baseUrl/list?userId=$userId';
      print('DPService: Retrieving from URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Retrieve request timed out');
        },
      );

      print('DPService: Retrieve response status: ${response.statusCode}');
      print('DPService: Retrieve response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
        } catch (e) {
          print('DPService: Failed to parse JSON response: $e');
          return {
            'success': false,
            'message': 'Invalid response format from server',
            'error': 'JSON Parse Error',
          };
        }
        
        print('DPService: DP retrieved successfully');
        // Transform the response to match the expected format
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final files = jsonResponse['data']['files'] as List;
          if (files.isNotEmpty) {
            // Get the most recent DP (first in the list as it's sorted by uploadedAt desc)
            final latestFile = files.first;
            
            // Extract data from the response
            final publicUrl = latestFile['publicUrl'] as String;
            final fileName = latestFile['fileName'] as String;
            final fileType = latestFile['fileType'] as String;
            final size = latestFile['size'] as int;
            
            // Construct full DP URL
            final dpUrl = 'http://103.14.120.163:8081$publicUrl';
            
            print('DPService: Found DP');
            print('DPService: DP URL: $dpUrl');
            print('DPService: File name: $fileName');
            print('DPService: File type: $fileType');
            print('DPService: Size: $size bytes');
            
            return {
              'success': true,
              'message': 'Display picture retrieved successfully',
              'data': {
                'dpUrl': dpUrl,
                'fileName': fileName,
                'fileType': fileType,
                'size': size,
                'publicUrl': publicUrl,
              },
            };
          }
        }
        
        // No DP found
        return {
          'success': false,
          'message': 'No display picture found for this user.',
          'error': 'Not Found',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'error': 'Unauthorized',
        };
      } else {
        print('DPService: Retrieve failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to retrieve display picture',
          'error': 'Retrieve Failed',
        };
      }
    } catch (e) {
      print('DPService: Retrieve error: $e');
      return {
        'success': false,
        'message': 'An error occurred while retrieving the display picture: ${e.toString()}',
        'error': 'Retrieve Error',
      };
    }
  }

  /// Delete Display Picture using local storage API
  static Future<Map<String, dynamic>> deleteDP({
    required String userId,
    required String fileName,
    required String token,
  }) async {
    try {
      print('DPService: Deleting DP for user $userId');
      print('DPService: File name: $fileName');
      
      // Validate token
      if (token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication token is required',
        };
      }
      
      // Validate userId and fileName
      if (userId.isEmpty || fileName.isEmpty) {
        return {
          'success': false,
          'message': 'User ID and file name are required',
        };
      }
      
      final url = '$baseUrl/delete?userId=$userId&fileName=$fileName';
      print('DPService: Delete URL: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Delete request timed out');
        },
      );

      print('DPService: Delete response status: ${response.statusCode}');
      print('DPService: Delete response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('DPService: Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
          'error': 'JSON Parse Error',
        };
      }

      if (response.statusCode == 200) {
        if (jsonResponse['success'] == true) {
          print('DPService: DP deleted successfully');
          return {
            'success': true,
            'message': 'Display picture deleted successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to delete display picture',
            'error': 'Delete Failed',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'error': 'Unauthorized',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Display picture not found',
          'error': 'Not Found',
        };
      } else {
        print('DPService: Delete failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to delete display picture',
          'error': 'Delete Failed',
        };
      }
    } catch (e) {
      print('DPService: Delete error: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting the display picture: ${e.toString()}',
        'error': 'Delete Error',
      };
    }
  }
}
