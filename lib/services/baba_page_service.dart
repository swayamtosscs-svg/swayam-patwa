import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/baba_page_model.dart';

class BabaPageService {
  static const String baseUrl = 'https://api-rgram1.vercel.app/api';

  /// Create a new Baba Ji page
  static Future<BabaPageResponse> createBabaPage({
    required BabaPageRequest request,
    required String token,
  }) async {
    try {
      print('BabaPageService: Creating Baba Ji page: ${request.name}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/baba-pages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('BabaPageService: Response status: ${response.statusCode}');
      print('BabaPageService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return BabaPageResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return BabaPageResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to create Baba Ji page',
        );
      }
    } catch (e) {
      print('BabaPageService: Error creating Baba Ji page: $e');
      return BabaPageResponse(
        success: false,
        message: 'Error creating Baba Ji page: $e',
      );
    }
  }

  /// Get all Baba Ji pages with pagination
  static Future<BabaPageListResponse> getBabaPages({
    required String token,
    int page = 1,
    int limit = 10,
    String? search,
    String? religion,
  }) async {
    try {
      print('BabaPageService: Fetching Baba Ji pages');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (religion != null && religion.isNotEmpty) {
        queryParams['religion'] = religion;
      }
      
      final uri = Uri.parse('$baseUrl/baba-pages').replace(
        queryParameters: queryParams,
      );
      
      print('BabaPageService: Request URL: $uri');
      
      final response = await http.get(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPageService: Response status: ${response.statusCode}');
      print('BabaPageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return BabaPageListResponse.fromJson(jsonResponse);
        }
      }
      
      return BabaPageListResponse(
        success: false,
        message: 'Failed to fetch Baba Ji pages',
        pages: [],
        pagination: null,
      );
    } catch (e) {
      print('BabaPageService: Error fetching Baba Ji pages: $e');
      return BabaPageListResponse(
        success: false,
        message: 'Error fetching Baba Ji pages: $e',
        pages: [],
        pagination: null,
      );
    }
  }

  /// Get a specific Baba Ji page by ID
  static Future<BabaPageResponse> getBabaPageById({
    required String pageId,
    required String token,
  }) async {
    try {
      print('BabaPageService: Fetching Baba Ji page: $pageId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/baba-pages/$pageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPageService: Response status: ${response.statusCode}');
      print('BabaPageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return BabaPageResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return BabaPageResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to fetch Baba Ji page',
        );
      }
    } catch (e) {
      print('BabaPageService: Error fetching Baba Ji page: $e');
      return BabaPageResponse(
        success: false,
        message: 'Error fetching Baba Ji page: $e',
      );
    }
  }

  /// Update a Baba Ji page
  static Future<BabaPageResponse> updateBabaPage({
    required String pageId,
    required BabaPageRequest request,
    required String token,
  }) async {
    try {
      print('BabaPageService: Updating Baba Ji page: $pageId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/baba-pages/$pageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('BabaPageService: Response status: ${response.statusCode}');
      print('BabaPageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return BabaPageResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return BabaPageResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to update Baba Ji page',
        );
      }
    } catch (e) {
      print('BabaPageService: Error updating Baba Ji page: $e');
      return BabaPageResponse(
        success: false,
        message: 'Error updating Baba Ji page: $e',
      );
    }
  }

  /// Delete a Baba Ji page
  static Future<BabaPageResponse> deleteBabaPage({
    required String pageId,
    required String token,
  }) async {
    try {
      print('BabaPageService: Deleting Baba Ji page: $pageId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/baba-pages/$pageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPageService: Response status: ${response.statusCode}');
      print('BabaPageService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return BabaPageResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return BabaPageResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to delete Baba Ji page',
        );
      }
    } catch (e) {
      print('BabaPageService: Error deleting Baba Ji page: $e');
      return BabaPageResponse(
        success: false,
        message: 'Error deleting Baba Ji page: $e',
      );
    }
  }
}
