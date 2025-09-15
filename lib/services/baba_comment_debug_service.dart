import 'dart:convert';
import 'package:http/http.dart' as http;

class BabaCommentDebugService {
  static const String baseUrl = 'http://103.14.120.163:8081/api';

  /// Debug method to test the comment API response structure
  static Future<void> debugCommentApiResponse({
    required String postId,
    required String babaPageId,
    required String token,
  }) async {
    try {
      print('BabaCommentDebugService: Testing comment API response for post: $postId, page: $babaPageId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/baba-pages/$babaPageId/comments?contentId=$postId&contentType=post&page=1&limit=10'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaCommentDebugService: Response status: ${response.statusCode}');
      print('BabaCommentDebugService: Response headers: ${response.headers}');
      print('BabaCommentDebugService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('BabaCommentDebugService: Parsed JSON: $jsonResponse');
          
          // Check the structure
          if (jsonResponse is Map<String, dynamic>) {
            print('BabaCommentDebugService: Root is Map');
            print('BabaCommentDebugService: Keys: ${jsonResponse.keys.toList()}');
            
            if (jsonResponse['data'] != null) {
              print('BabaCommentDebugService: Data exists');
              print('BabaCommentDebugService: Data type: ${jsonResponse['data'].runtimeType}');
              
              if (jsonResponse['data'] is Map<String, dynamic>) {
                final data = jsonResponse['data'] as Map<String, dynamic>;
                print('BabaCommentDebugService: Data keys: ${data.keys.toList()}');
                
                if (data['comments'] != null) {
                  print('BabaCommentDebugService: Comments exists');
                  print('BabaCommentDebugService: Comments type: ${data['comments'].runtimeType}');
                  
                  if (data['comments'] is List) {
                    final comments = data['comments'] as List;
                    print('BabaCommentDebugService: Comments count: ${comments.length}');
                    if (comments.isNotEmpty) {
                      print('BabaCommentDebugService: First comment: ${comments.first}');
                    }
                  }
                }
              } else if (jsonResponse['data'] is List) {
                final data = jsonResponse['data'] as List;
                print('BabaCommentDebugService: Data is List with ${data.length} items');
                if (data.isNotEmpty) {
                  print('BabaCommentDebugService: First item: ${data.first}');
                }
              }
            }
          }
        } catch (e) {
          print('BabaCommentDebugService: Error parsing JSON: $e');
        }
      }
    } catch (e) {
      print('BabaCommentDebugService: Error making request: $e');
    }
  }
}
