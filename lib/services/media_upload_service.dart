import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MediaUploadResponse {
  final bool success;
  final MediaData? data;
  final String? message;

  MediaUploadResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? MediaData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class MediaData {
  final String mediaId;
  final String publicId;
  final String secureUrl;
  final String folderPath;
  final String fileName;
  final String fileType;
  final int fileSize;
  final Map<String, dynamic> dimensions;
  final double? duration;
  final String uploadedBy;
  final String username;
  final DateTime uploadedAt;

  MediaData({
    required this.mediaId,
    required this.publicId,
    required this.secureUrl,
    required this.folderPath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.dimensions,
    this.duration,
    required this.uploadedBy,
    required this.username,
    required this.uploadedAt,
  });

  factory MediaData.fromJson(Map<String, dynamic> json) {
    // Debug: Log the incoming JSON
    print('MediaData.fromJson: Parsing JSON: $json');
    
    // Handle the new API response structure
    String mediaId = '';
    String publicId = '';
    String secureUrl = '';
    String folderPath = '';
    String fileName = '';
    String fileType = '';
    int fileSize = 0;
    Map<String, dynamic> dimensions = {};
    double? duration;
    String uploadedBy = '';
    String username = '';
    DateTime uploadedAt = DateTime.now();
    
    // Extract mediaId
    if (json['_id'] != null) {
      mediaId = json['_id'];
    }
    
    // Extract publicId
    if (json['publicId'] != null) {
      publicId = json['publicId'];
      // Extract folder path from publicId (e.g., "users/johndoe12/videos" from "users/johndoe12/videos/johndoe12_1755941984304")
      final parts = publicId.split('/');
      if (parts.length >= 3) {
        folderPath = parts.take(3).join('/');
        fileName = parts.last;
      }
    }
    
    // Extract secureUrl
    if (json['secureUrl'] != null) {
      secureUrl = json['secureUrl'];
    } else if (json['url'] != null) {
      secureUrl = json['url'];
    } else if (json['publicUrl'] != null) {
      // Handle the new API format that uses publicUrl
      secureUrl = 'http://103.14.120.163:8081${json['publicUrl']}';
    }
    
    // Extract fileType
    if (json['resourceType'] != null) {
      fileType = json['resourceType'];
    } else if (json['fileType'] != null) {
      fileType = json['fileType'];
    } else if (json['type'] != null) {
      fileType = json['type'];
    } else {
      // Try to infer from URL or other fields
      if (json['secureUrl'] != null) {
        final url = json['secureUrl'] as String;
        if (url.contains('.mp4') || url.contains('.mov') || url.contains('.avi')) {
          fileType = 'video';
        } else if (url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('.gif')) {
          fileType = 'image';
        }
      }
    }
    
    // Extract dimensions
    if (json['width'] != null && json['height'] != null) {
      dimensions = {
        'width': json['width'],
        'height': json['height'],
      };
    }
    
    // Extract duration
    if (json['duration'] != null) {
      duration = json['duration'].toDouble();
    }
    
    // Extract uploadedBy and username from uploadedBy object
    if (json['uploadedBy'] != null && json['uploadedBy'] is Map<String, dynamic>) {
      final uploadedByData = json['uploadedBy'] as Map<String, dynamic>;
      uploadedBy = uploadedByData['_id'] ?? '';
      username = uploadedByData['username'] ?? '';
    }
    
    // Extract uploadedAt
    if (json['createdAt'] != null) {
      uploadedAt = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    }
    
    final mediaData = MediaData(
      mediaId: mediaId,
      publicId: publicId,
      secureUrl: secureUrl,
      folderPath: folderPath,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      dimensions: dimensions,
      duration: duration,
      uploadedBy: uploadedBy,
      username: username,
      uploadedAt: uploadedAt,
    );
    
    // Debug: Log the parsed result
    print('MediaData.fromJson: Parsed result - mediaId: ${mediaData.mediaId}, fileType: ${mediaData.fileType}, secureUrl: ${mediaData.secureUrl}, username: ${mediaData.username}');
    print('MediaData.fromJson: Original JSON had resourceType: ${json['resourceType']}, fileType: ${json['fileType']}, type: ${json['type']}');
    
    return mediaData;
  }

  // Legacy support for old API format
  String get id => mediaId;
  String get url => secureUrl;
  String get resourceType => fileType;
  int get width => dimensions['width'] ?? 0;
  int get height => dimensions['height'] ?? 0;
  List<String> get tags => [];
  DateTime get createdAt => uploadedAt;
  DateTime get updatedAt => uploadedAt;
}

class MediaRetrieveResponse {
  final bool success;
  final List<MediaData> data;
  final Map<String, dynamic>? pagination;

  MediaRetrieveResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory MediaRetrieveResponse.fromJson(Map<String, dynamic> json) {
    print('MediaRetrieveResponse.fromJson: Parsing response: $json');
    
    List<MediaData> mediaList = [];
    
    // Handle the new API response structure where media is nested under data.media
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      
      if (data['media'] != null && data['media'] is List<dynamic>) {
        final mediaArray = data['media'] as List<dynamic>;
        print('MediaRetrieveResponse: Found ${mediaArray.length} media items in data.media');
        
        mediaList = mediaArray
            .map((item) => MediaData.fromJson(item))
            .toList();
      } else {
        print('MediaRetrieveResponse: No media array found in data');
      }
    } else if (json['data'] != null && json['data'] is List<dynamic>) {
      // Handle legacy format where data is directly a list
      final dataArray = json['data'] as List<dynamic>;
      print('MediaRetrieveResponse: Found ${dataArray.length} media items in legacy data format');
      
      mediaList = dataArray
          .map((item) => MediaData.fromJson(item))
          .toList();
    }
    
    print('MediaRetrieveResponse: Parsed ${mediaList.length} media items');
    
    return MediaRetrieveResponse(
      success: json['success'] ?? false,
      data: mediaList,
      pagination: json['data']?['pagination'],
    );
  }
}

class MediaUploadService {
  static const String baseUrl = 'http://103.14.120.163:8081/api';

  /// Upload media file (image or video) with userId and title
  static Future<MediaUploadResponse> uploadMedia({
    required dynamic file, // Use dynamic to support both File and web file types
    required String type, // 'image' or 'video'
    required String userId, // Use userId as API expects
    String? title,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/media/upload'),
      );

      // Add file
      String contentType = type == 'image' ? 'image/jpeg' : 'video/mp4';
      String extension = type == 'image' ? 'jpg' : 'mp4';
      
      if (kIsWeb) {
        // For web, we need to handle the file differently
        try {
          // On web, the file object has a different structure
          if (file is XFile) {
            final bytes = await file.readAsBytes();
            request.files.add(
              http.MultipartFile(
                'file',
                Stream.value(bytes),
                bytes.length,
                filename: 'media.${extension}',
                contentType: MediaType.parse(contentType),
              ),
            );
          } else {
            return MediaUploadResponse(
              success: false,
              message: 'Web file type not supported: ${file.runtimeType}',
            );
          }
        } catch (e) {
          print('Web file handling error: $e');
          return MediaUploadResponse(
            success: false,
            message: 'Web file handling error: $e',
          );
        }
      } else {
        // For mobile platforms
        if (file is File) {
          request.files.add(
            http.MultipartFile(
              'file',
              file.readAsBytes().asStream(),
              file.lengthSync(),
              filename: 'media.${extension}',
              contentType: MediaType.parse(contentType),
            ),
          );
        } else {
          return MediaUploadResponse(
            success: false,
            message: 'Mobile file type not supported: ${file.runtimeType}',
          );
        }
      }

      // Add required fields
      request.fields['userId'] = userId;
      request.fields['type'] = type;
      
      // Add optional title if provided
      if (title != null && title.isNotEmpty) {
        request.fields['title'] = title;
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return MediaUploadResponse.fromJson(jsonResponse);
      } else {
        return MediaUploadResponse(
          success: false,
          message: 'Upload failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return MediaUploadResponse(
        success: false,
        message: 'Upload error: $e',
      );
    }
  }

  /// Retrieve media by ID
  static Future<MediaRetrieveResponse> retrieveMedia({
    required String mediaId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/media/retrieve?id=$mediaId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return MediaRetrieveResponse.fromJson(jsonResponse);
      } else {
        return MediaRetrieveResponse(
          success: false,
          data: [],
        );
      }
    } catch (e) {
      return MediaRetrieveResponse(
        success: false,
        data: [],
      );
    }
  }

  /// Retrieve media by userId (for user-specific media)
  static Future<MediaRetrieveResponse> retrieveMediaByUserId({
    required String userId,
  }) async {
    try {
      print('MediaUploadService: Retrieving media for userId: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/media/upload?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('MediaUploadService: Response status: ${response.statusCode}');
      print('MediaUploadService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('MediaUploadService: Success response received');
        print('MediaUploadService: Response body: ${response.body}');
        
        try {
          final jsonResponse = jsonDecode(response.body);
          print('MediaUploadService: Parsed JSON: $jsonResponse');
          
          // Debug: Check the structure of the response
          if (jsonResponse['data'] != null) {
            print('MediaUploadService: Data field exists');
            if (jsonResponse['data'] is Map<String, dynamic>) {
              final data = jsonResponse['data'] as Map<String, dynamic>;
              print('MediaUploadService: Data is a Map with keys: ${data.keys.toList()}');
              if (data['media'] != null) {
                print('MediaUploadService: Media field exists with ${data['media'].length} items');
                if (data['media'] is List && data['media'].isNotEmpty) {
                  print('MediaUploadService: First media item: ${data['media'][0]}');
                }
              }
            } else if (jsonResponse['data'] is List<dynamic>) {
              print('MediaUploadService: Data is a List with ${jsonResponse['data'].length} items');
              if (jsonResponse['data'].isNotEmpty) {
                print('MediaUploadService: First data item: ${jsonResponse['data'][0]}');
              }
            }
          } else {
            print('MediaUploadService: No data field found in response');
          }
          
          return MediaRetrieveResponse.fromJson(jsonResponse);
        } catch (parseError) {
          print('MediaUploadService: JSON parsing error: $parseError');
          return MediaRetrieveResponse(
            success: false,
            data: [],
          );
        }
      } else {
        print('MediaUploadService: Failed to retrieve media: ${response.statusCode}');
        print('MediaUploadService: Error response body: ${response.body}');
        return MediaRetrieveResponse(
          success: false,
          data: [],
        );
      }
    } catch (e) {
      print('MediaUploadService: Error retrieving media by userId: $e');
      return MediaRetrieveResponse(
        success: false,
        data: [],
      );
    }
  }

  /// Upload image specifically
  static Future<MediaUploadResponse> uploadImage(dynamic imageFile, String userId, {String? title}) {
    return uploadMedia(file: imageFile, type: 'image', userId: userId, title: title);
  }

  /// Upload video specifically
  static Future<MediaUploadResponse> uploadVideo(dynamic videoFile, String userId, {String? title}) {
    return uploadMedia(file: videoFile, type: 'video', userId: userId, title: title);
  }
}
