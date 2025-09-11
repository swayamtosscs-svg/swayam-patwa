import 'dart:convert';
import 'package:http/http.dart' as http;

class BabaPagePostDebugService {
  static const String baseUrl = 'https://api-rgram1.vercel.app/api';

  /// Debug method to test the API response structure
  static Future<void> debugApiResponse({
    required String babaPageId,
    required String token,
  }) async {
    try {
      print('BabaPagePostDebugService: Testing API response for page: $babaPageId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/baba-pages/$babaPageId/posts?page=1&limit=10'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPagePostDebugService: Response status: ${response.statusCode}');
      print('BabaPagePostDebugService: Response headers: ${response.headers}');
      print('BabaPagePostDebugService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('BabaPagePostDebugService: Parsed JSON: $jsonResponse');
          
          // Check the structure
          if (jsonResponse is Map<String, dynamic>) {
            print('BabaPagePostDebugService: Root is Map');
            print('BabaPagePostDebugService: Keys: ${jsonResponse.keys.toList()}');
            
            if (jsonResponse['data'] != null) {
              print('BabaPagePostDebugService: Data exists');
              print('BabaPagePostDebugService: Data type: ${jsonResponse['data'].runtimeType}');
              
              if (jsonResponse['data'] is Map<String, dynamic>) {
                final data = jsonResponse['data'] as Map<String, dynamic>;
                print('BabaPagePostDebugService: Data keys: ${data.keys.toList()}');
                
                if (data['posts'] != null) {
                  print('BabaPagePostDebugService: Posts exists');
                  print('BabaPagePostDebugService: Posts type: ${data['posts'].runtimeType}');
                  
                  if (data['posts'] is List) {
                    final posts = data['posts'] as List;
                    print('BabaPagePostDebugService: Posts count: ${posts.length}');
                    if (posts.isNotEmpty) {
                      print('BabaPagePostDebugService: First post: ${posts.first}');
                    }
                  }
                }
              } else if (jsonResponse['data'] is List) {
                final data = jsonResponse['data'] as List;
                print('BabaPagePostDebugService: Data is List with ${data.length} items');
                if (data.isNotEmpty) {
                  print('BabaPagePostDebugService: First item: ${data.first}');
                }
              }
            }
          }
        } catch (e) {
          print('BabaPagePostDebugService: Error parsing JSON: $e');
        }
      }
    } catch (e) {
      print('BabaPagePostDebugService: Error making request: $e');
    }
  }
}
