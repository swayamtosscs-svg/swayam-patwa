import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/highlight_model.dart';
import 'custom_http_client.dart';

class HighlightService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Create a new highlight
  static Future<HighlightResponse> createHighlight({
    required String name,
    required String description,
    required List<String> storyIds,
    required bool isPublic,
    required String token,
  }) async {
    try {
      print('HighlightService: Creating highlight: $name');
      print('HighlightService: Story IDs received: $storyIds');
      
      // Filter out empty or invalid story IDs
      final validStoryIds = storyIds.where((id) => id.isNotEmpty && id != 'null').toList();
      print('HighlightService: Valid story IDs: $validStoryIds');
      
      if (validStoryIds.isEmpty) {
        return HighlightResponse(
          success: false,
          message: 'No valid story IDs provided',
        );
      }
      
      final request = HighlightCreateRequest(
        name: name,
        description: description,
        storyIds: validStoryIds,
        isPublic: isPublic,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/highlights'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('HighlightService: Create highlight response status: ${response.statusCode}');
      print('HighlightService: Create highlight response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightResponse(
          success: false,
          message: 'Failed to create highlight. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('HighlightService: Error creating highlight: $e');
      return HighlightResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Get highlights with pagination
  static Future<HighlightsListResponse> getHighlights({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('HighlightService: Fetching highlights page $page, limit $limit');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/highlights?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('HighlightService: Get highlights response status: ${response.statusCode}');
      print('HighlightService: Get highlights response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightsListResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightsListResponse(
          success: false,
          message: 'Failed to fetch highlights. Status: ${response.statusCode}',
          highlights: [],
        );
      }
    } catch (e) {
      print('HighlightService: Error fetching highlights: $e');
      return HighlightsListResponse(
        success: false,
        message: 'Network error: $e',
        highlights: [],
      );
    }
  }

  /// Add a story to a highlight
  static Future<HighlightResponse> addStoryToHighlight({
    required String highlightId,
    required String storyId,
    required String token,
  }) async {
    try {
      print('HighlightService: Adding story $storyId to highlight $highlightId');
      
      final request = HighlightAddStoryRequest(storyId: storyId);

      final response = await http.post(
        Uri.parse('$_baseUrl/highlights/$highlightId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('HighlightService: Add story response status: ${response.statusCode}');
      print('HighlightService: Add story response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightResponse(
          success: false,
          message: 'Failed to add story to highlight. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('HighlightService: Error adding story to highlight: $e');
      return HighlightResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Remove a story from a highlight
  static Future<HighlightResponse> removeStoryFromHighlight({
    required String highlightId,
    required String storyId,
    required String token,
  }) async {
    try {
      print('HighlightService: Removing story $storyId from highlight $highlightId');
      
      final request = HighlightRemoveStoryRequest(storyId: storyId);

      final response = await http.delete(
        Uri.parse('$_baseUrl/highlights/$highlightId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('HighlightService: Remove story response status: ${response.statusCode}');
      print('HighlightService: Remove story response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightResponse(
          success: false,
          message: 'Failed to remove story from highlight. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('HighlightService: Error removing story from highlight: $e');
      return HighlightResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Update a highlight
  static Future<HighlightResponse> updateHighlight({
    required String highlightId,
    String? name,
    String? description,
    required String token,
  }) async {
    try {
      print('HighlightService: Updating highlight $highlightId');
      
      final request = HighlightUpdateRequest(
        name: name,
        description: description,
      );

      final response = await http.put(
        Uri.parse('$_baseUrl/highlights/$highlightId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('HighlightService: Update highlight response status: ${response.statusCode}');
      print('HighlightService: Update highlight response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightResponse(
          success: false,
          message: 'Failed to update highlight. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('HighlightService: Error updating highlight: $e');
      return HighlightResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Delete a highlight
  static Future<HighlightResponse> deleteHighlight({
    required String highlightId,
    required String token,
  }) async {
    try {
      print('HighlightService: Deleting highlight $highlightId');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/highlights/$highlightId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('HighlightService: Delete highlight response status: ${response.statusCode}');
      print('HighlightService: Delete highlight response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightResponse(
          success: false,
          message: 'Failed to delete highlight. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('HighlightService: Error deleting highlight: $e');
      return HighlightResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Get a specific highlight by ID
  static Future<HighlightResponse> getHighlight({
    required String highlightId,
    required String token,
  }) async {
    try {
      print('HighlightService: Fetching highlight $highlightId');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/highlights/$highlightId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('HighlightService: Get highlight response status: ${response.statusCode}');
      print('HighlightService: Get highlight response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return HighlightResponse.fromJson(jsonResponse);
      } else {
        print('HighlightService: Error response (${response.statusCode}): ${response.body}');
        return HighlightResponse(
          success: false,
          message: 'Failed to fetch highlight. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('HighlightService: Error fetching highlight: $e');
      return HighlightResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Check if a story is already in a highlight
  static Future<bool> isStoryInHighlight({
    required String highlightId,
    required String storyId,
    required String token,
  }) async {
    try {
      final response = await getHighlight(highlightId: highlightId, token: token);
      if (response.success && response.highlight != null) {
        return response.highlight!.stories.any((story) => story.id == storyId);
      }
      return false;
    } catch (e) {
      print('HighlightService: Error checking if story is in highlight: $e');
      return false;
    }
  }

  /// Get highlights that contain a specific story
  static Future<List<Highlight>> getHighlightsContainingStory({
    required String storyId,
    required String token,
  }) async {
    try {
      final response = await getHighlights(token: token, page: 1, limit: 100);
      if (response.success) {
        return response.highlights.where((highlight) {
          return highlight.stories.any((story) => story.id == storyId);
        }).toList();
      }
      return [];
    } catch (e) {
      print('HighlightService: Error getting highlights containing story: $e');
      return [];
    }
  }
}


