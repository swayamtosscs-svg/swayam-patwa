import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify the like API connection
/// This script tests the exact API endpoint provided by the user
void main() async {
  print('Testing Like API Connection...');
  
  // Test parameters - replace with actual values
  const String baseUrl = 'http://103.14.120.163:8081/api';
  const String testPostId = 'TEST_POST_ID'; // Replace with actual post ID
  const String testToken = 'YOUR_TOKEN'; // Replace with actual token
  
  // Test the like endpoint
  await testLikeEndpoint(baseUrl, testPostId, testToken);
  
  // Test the unlike endpoint (using DELETE method)
  await testUnlikeEndpoint(baseUrl, testPostId, testToken);
}

Future<void> testLikeEndpoint(String baseUrl, String postId, String token) async {
  print('\n=== Testing LIKE Endpoint ===');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/feed/like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contentId': postId,
        'contentType': 'post',
        'userId': 'TEST_USER_ID', // Replace with actual user ID
        'action': 'like',
      }),
    );
    
    print('Like API Response Status: ${response.statusCode}');
    print('Like API Response Body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Like API is working correctly!');
      final result = jsonDecode(response.body);
      print('Response Data: $result');
    } else {
      print('❌ Like API failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Like API Error: $e');
  }
}

Future<void> testUnlikeEndpoint(String baseUrl, String postId, String token) async {
  print('\n=== Testing UNLIKE Endpoint ===');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/feed/like'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contentId': postId,
        'contentType': 'post',
        'userId': 'TEST_USER_ID', // Replace with actual user ID
        'action': 'unlike',
      }),
    );
    
    print('Unlike API Response Status: ${response.statusCode}');
    print('Unlike API Response Body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Unlike API is working correctly!');
      final result = jsonDecode(response.body);
      print('Response Data: $result');
    } else {
      print('❌ Unlike API failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Unlike API Error: $e');
  }
}

/// Example usage with actual values:
/// 
/// To test with real data:
/// 1. Replace 'TEST_POST_ID' with an actual post ID from your app
/// 2. Replace 'YOUR_TOKEN' with a valid authentication token
/// 3. Replace 'TEST_USER_ID' with an actual user ID
/// 4. Run: dart test_like_api_connection.dart
/// 
/// Expected API Response Format:
/// {
///   "success": true,
///   "message": "Content liked successfully",
///   "data": {
///     "contentId": "POST_ID",
///     "contentType": "post",
///     "isLiked": true,
///     "likesCount": 1
///   }
/// }
/// 
/// New API Structure (Fixed):
/// - Endpoint: POST http://103.14.120.163:8081/api/feed/like
/// - Request Body: {
///     "contentId": "POST_ID",
///     "contentType": "post", 
///     "userId": "USER_ID",
///     "action": "like" or "unlike"
///   }
/// - Authorization: Bearer YOUR_TOKEN
