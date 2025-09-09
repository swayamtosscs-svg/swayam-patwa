import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePictureService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/local-storage';

  /// Upload profile picture using new local storage API
  static Future<Map<String, dynamic>> uploadProfilePicture({
    required File imageFile,
    required String userId,
    required String token,
  }) async {
    try {
      print('ProfilePictureService: Starting upload for user $userId');
      print('ProfilePictureService: Image file path: ${imageFile.path}');
      
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
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        return {
          'success': false,
          'message': 'Unsupported image format. Please use JPG, PNG, GIF, or WEBP.',
        };
      }

      print('ProfilePictureService: File validation passed');
      print('ProfilePictureService: File size: $fileSize bytes');
      print('ProfilePictureService: File extension: $extension');

      // Create multipart request
      final url = '$baseUrl/upload?userId=$userId';
      print('ProfilePictureService: Request URL: $url');
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      print('ProfilePictureService: Request headers: ${request.headers}');
      
      // Add the image file
      final multipartFile = await http.MultipartFile.fromPath(
        'file', // Use 'file' as the field name as per API spec
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      print('ProfilePictureService: Added file: ${multipartFile.field} - ${multipartFile.filename}');
      print('ProfilePictureService: File field name: ${multipartFile.field}');
      print('ProfilePictureService: Total files in request: ${request.files.length}');
      print('ProfilePictureService: File length: ${multipartFile.length}');
      print('ProfilePictureService: File path: ${imageFile.path}');
      print('ProfilePictureService: File exists: ${await imageFile.exists()}');
      print('ProfilePictureService: File size: ${await imageFile.length()}');
      print('ProfilePictureService: Request fields: ${request.fields}');
      print('ProfilePictureService: Request files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}');
      
      // Send the request
      print('ProfilePictureService: Sending request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      print('ProfilePictureService: Response status: ${response.statusCode}');
      print('ProfilePictureService: Response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('ProfilePictureService: Failed to parse JSON response: $e');
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
            
            // Construct full avatar URL
            final avatar = 'http://103.14.120.163:8081$publicUrl';
            
            print('ProfilePictureService: Upload successful');
            print('ProfilePictureService: Avatar URL: $avatar');
            print('ProfilePictureService: File name: $fileName');
            print('ProfilePictureService: Original name: $originalName');
            print('ProfilePictureService: Size: $size bytes');
            print('ProfilePictureService: MIME type: $mimetype');
            
            return {
              'success': true,
              'message': 'Profile picture uploaded successfully',
              'data': {
                'avatar': avatar,
                'publicId': fileName, // Use fileName as publicId for compatibility
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
        print('ProfilePictureService: Upload failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to upload profile picture',
          'error': 'Upload Failed',
        };
      }
    } catch (e) {
      print('ProfilePictureService: Upload error: $e');
      return {
        'success': false,
        'message': 'An error occurred while uploading the profile picture: ${e.toString()}',
        'error': 'Upload Error',
      };
    }
  }

  /// Retrieve profile picture using new local storage API
  static Future<Map<String, dynamic>> retrieveProfilePicture({
    required String userId,
    required String token,
  }) async {
    try {
      print('ProfilePictureService: Retrieving profile picture for user $userId');
      
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
      print('ProfilePictureService: Retrieving from URL: $url');
      
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

      print('ProfilePictureService: Retrieve response status: ${response.statusCode}');
      print('ProfilePictureService: Retrieve response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
        } catch (e) {
          print('ProfilePictureService: Failed to parse JSON response: $e');
          return {
            'success': false,
            'message': 'Invalid response format from server',
            'error': 'JSON Parse Error',
          };
        }
        
        print('ProfilePictureService: Profile picture retrieved successfully');
        // Transform the response to match the expected format
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final files = jsonResponse['data']['files'] as List;
          if (files.isNotEmpty) {
            // Get the most recent profile picture (first in the list as it's sorted by uploadedAt desc)
            final latestFile = files.first;
            
            // Extract data from the response
            final publicUrl = latestFile['publicUrl'] as String;
            final fileName = latestFile['fileName'] as String;
            final fileType = latestFile['fileType'] as String;
            final size = latestFile['size'] as int;
            
            // Construct full avatar URL
            final avatar = 'http://103.14.120.163:8081$publicUrl';
            
            print('ProfilePictureService: Found profile picture');
            print('ProfilePictureService: Avatar URL: $avatar');
            print('ProfilePictureService: File name: $fileName');
            print('ProfilePictureService: File type: $fileType');
            print('ProfilePictureService: Size: $size bytes');
            
            return {
              'success': true,
              'message': 'Profile picture retrieved successfully',
              'data': {
                'avatar': avatar,
                'publicId': fileName, // Use fileName as publicId for compatibility
                'fileName': fileName,
                'fileType': fileType,
                'size': size,
                'publicUrl': publicUrl,
              },
            };
          }
        }
        
        // No profile pictures found
        return {
          'success': false,
          'message': 'No profile pictures found for this user.',
          'error': 'Not Found',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'error': 'Unauthorized',
        };
      } else {
        print('ProfilePictureService: Retrieve failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to retrieve profile picture',
          'error': 'Retrieve Failed',
        };
      }
    } catch (e) {
      print('ProfilePictureService: Retrieve error: $e');
      return {
        'success': false,
        'message': 'An error occurred while retrieving the profile picture: ${e.toString()}',
        'error': 'Retrieve Error',
      };
    }
  }

  /// Delete profile picture using new local storage API
  static Future<Map<String, dynamic>> deleteProfilePicture({
    required String userId,
    required String fileName,
    required String token,
  }) async {
    try {
      print('ProfilePictureService: Deleting profile picture for user $userId');
      print('ProfilePictureService: File name: $fileName');
      
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
      print('ProfilePictureService: Delete URL: $url');
      
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

      print('ProfilePictureService: Delete response status: ${response.statusCode}');
      print('ProfilePictureService: Delete response body: ${response.body}');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        print('ProfilePictureService: Failed to parse JSON response: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
          'error': 'JSON Parse Error',
        };
      }

      if (response.statusCode == 200) {
        if (jsonResponse['success'] == true) {
          print('ProfilePictureService: Profile picture deleted successfully');
          return {
            'success': true,
            'message': 'Profile picture deleted successfully',
          };
        } else {
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to delete profile picture',
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
          'message': 'Profile picture not found',
          'error': 'Not Found',
        };
      } else {
        print('ProfilePictureService: Delete failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Failed to delete profile picture',
          'error': 'Delete Failed',
        };
      }
    } catch (e) {
      print('ProfilePictureService: Delete error: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting the profile picture: ${e.toString()}',
        'error': 'Delete Error',
      };
    }
  }
}