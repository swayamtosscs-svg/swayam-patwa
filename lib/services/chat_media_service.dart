import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';

class ChatMediaResponse {
  final bool success;
  final String message;
  final ChatMediaData? data;

  ChatMediaResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ChatMediaResponse.fromJson(Map<String, dynamic> json) {
    return ChatMediaResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? ChatMediaData.fromJson(json['data']) : null,
    );
  }
}

class ChatMediaData {
  final ChatMessage message;
  final String threadId;
  final MediaInfo mediaInfo;

  ChatMediaData({
    required this.message,
    required this.threadId,
    required this.mediaInfo,
  });

  factory ChatMediaData.fromJson(Map<String, dynamic> json) {
    return ChatMediaData(
      message: ChatMessage.fromJson(json['message'] ?? {}),
      threadId: json['threadId'] ?? '',
      mediaInfo: MediaInfo.fromJson(json['mediaInfo'] ?? {}),
    );
  }
}

class ChatMessage {
  final String id;
  final String thread;
  final MessageSender sender;
  final String? recipient;
  final String content;
  final String messageType;
  final String? mediaUrl;
  final MediaInfo? mediaInfo;
  final bool isRead;
  final bool isDeleted;
  final List<dynamic> reactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.thread,
    required this.sender,
    this.recipient,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.mediaInfo,
    required this.isRead,
    required this.isDeleted,
    required this.reactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      thread: json['thread'] ?? '',
      sender: MessageSender.fromJson(json['sender'] ?? {}),
      recipient: json['recipient'],
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      mediaUrl: json['mediaUrl'],
      mediaInfo: json['mediaInfo'] != null ? MediaInfo.fromJson(json['mediaInfo']) : null,
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      reactions: List<dynamic>.from(json['reactions'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class MediaInfo {
  final String fileName;
  final String originalName;
  final String? localPath;
  final String publicUrl;
  final int size;
  final String mimetype;
  final String folder;
  final DateTime uploadedAt;

  MediaInfo({
    required this.fileName,
    required this.originalName,
    this.localPath,
    required this.publicUrl,
    required this.size,
    required this.mimetype,
    required this.folder,
    required this.uploadedAt,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      fileName: json['fileName'] ?? '',
      originalName: json['originalName'] ?? '',
      localPath: json['localPath'],
      publicUrl: json['publicUrl'] ?? '',
      size: json['size'] ?? 0,
      mimetype: json['mimetype'] ?? '',
      folder: json['folder'] ?? '',
      uploadedAt: DateTime.tryParse(json['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatMediaService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/chat';

  /// Send media (image/video) in chat message
  static Future<ChatMediaResponse> sendMedia({
    required dynamic file, // File or XFile
    required String toUserId,
    required String content,
    required String messageType, // 'image' or 'video'
    required String token,
  }) async {
    try {
      print('ChatMediaService: Sending media message to user: $toUserId');
      print('ChatMediaService: Message type: $messageType');
      print('ChatMediaService: Content: $content');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/send-media'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['toUserId'] = toUserId;
      request.fields['content'] = content;
      request.fields['messageType'] = messageType;

      // Add file
      if (kIsWeb) {
        // For web platform
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          final fileName = file.name;
          final contentType = _getContentType(fileName);
          
          request.files.add(
            http.MultipartFile(
              'file',
              Stream.value(bytes),
              bytes.length,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          );
        } else {
          return ChatMediaResponse(
            success: false,
            message: 'Web file type not supported: ${file.runtimeType}',
          );
        }
      } else {
        // For mobile platforms
        if (file is File) {
          final fileName = file.path.split('/').last;
          final contentType = _getContentType(fileName);
          
          request.files.add(
            http.MultipartFile(
              'file',
              file.readAsBytes().asStream(),
              file.lengthSync(),
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          );
        } else {
          return ChatMediaResponse(
            success: false,
            message: 'Mobile file type not supported: ${file.runtimeType}',
          );
        }
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ChatMediaService: Response status: ${response.statusCode}');
      print('ChatMediaService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return ChatMediaResponse.fromJson(jsonResponse);
      } else {
        return ChatMediaResponse(
          success: false,
          message: 'Failed to send media: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('ChatMediaService: Error sending media: $e');
      return ChatMediaResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Send image in chat message
  static Future<ChatMediaResponse> sendImage({
    required dynamic imageFile,
    required String toUserId,
    required String content,
    required String token,
  }) {
    return sendMedia(
      file: imageFile,
      toUserId: toUserId,
      content: content,
      messageType: 'image',
      token: token,
    );
  }

  /// Send video in chat message
  static Future<ChatMediaResponse> sendVideo({
    required dynamic videoFile,
    required String toUserId,
    required String content,
    required String token,
  }) {
    return sendMedia(
      file: videoFile,
      toUserId: toUserId,
      content: content,
      messageType: 'video',
      token: token,
    );
  }

  /// Get content type based on file extension
  static String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}
