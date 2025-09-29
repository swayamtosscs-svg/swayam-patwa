import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify creator-only access control for Baba Ji pages
/// This script tests the updated API endpoints with creator access control

class BabaPageAPITester {
  static const String baseUrl = 'http://103.14.120.163:8081/api';
  
  // Test token (replace with actual token for testing)
  static const String testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGQxM2I0ZGE1NjRlY2RkYTA2NjhhMDMiLCJpYXQiOjE3NTkxMjY1MTAsImV4cCI6MTc2MTcxODUxMH0.krjnQr7CtN9tbKSBl4WkBG6PEbVOnjNg6ZMZghYynuE';

  /// Test 1: Create a new Baba Ji page
  static Future<Map<String, dynamic>> testCreateBabaPage() async {
    print('🧪 Testing: Create Baba Ji Page');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/baba-pages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testToken',
        },
        body: jsonEncode({
          'name': 'Test Baba Ji Page - Creator Access',
          'description': 'Testing creator-only access control',
          'location': 'Test Location',
          'religion': 'Hinduism',
          'website': 'https://test-baba.com'
        }),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': jsonResponse,
          'pageId': jsonResponse['data']?['_id'] ?? jsonResponse['data']?['id']
        };
      } else {
        return {
          'success': false,
          'error': response.body
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  /// Test 2: Create a post for the Baba Ji page (should work for creator)
  static Future<Map<String, dynamic>> testCreatePost(String pageId) async {
    print('\n🧪 Testing: Create Post for Baba Ji Page (Creator)');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/baba-pages/$pageId/posts'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $testToken',
      });

      request.fields['content'] = 'Test post by page creator - should work!';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': jsonResponse
        };
      } else {
        return {
          'success': false,
          'error': response.body
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  /// Test 3: Delete the Baba Ji page (should work for creator)
  static Future<Map<String, dynamic>> testDeleteBabaPage(String pageId) async {
    print('\n🧪 Testing: Delete Baba Ji Page (Creator)');
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/baba-pages/$pageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testToken',
        },
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return {
          'success': true,
          'data': jsonResponse
        };
      } else {
        return {
          'success': false,
          'error': response.body
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  /// Test 4: Try to create post with different user token (should fail)
  static Future<Map<String, dynamic>> testCreatePostWithDifferentUser(String pageId) async {
    print('\n🧪 Testing: Create Post with Different User Token (Should Fail)');
    
    // Using a different token (this would be from a different user)
    const String differentUserToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJkaWZmZXJlbnR1c2VyaWQiLCJpYXQiOjE3NTkxMjY1MTAsImV4cCI6MTc2MTcxODUxMH0.differentSignature';
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/baba-pages/$pageId/posts'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $differentUserToken',
      });

      request.fields['content'] = 'This should fail - not the creator!';

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      // This should fail with 403 or similar
      if (response.statusCode == 403 || response.statusCode == 401) {
        return {
          'success': true, // Test passed - access was denied as expected
          'message': 'Access correctly denied for non-creator'
        };
      } else {
        return {
          'success': false,
          'error': 'Access should have been denied but was allowed'
        };
      }
    } catch (e) {
      print('Error: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting Baba Ji Page Creator Access Tests\n');
    
    // Test 1: Create page
    final createResult = await testCreateBabaPage();
    if (!createResult['success']) {
      print('❌ Failed to create page. Stopping tests.');
      return;
    }
    
    final pageId = createResult['pageId'];
    print('✅ Page created successfully with ID: $pageId');
    
    // Test 2: Create post as creator
    final createPostResult = await testCreatePost(pageId);
    if (createPostResult['success']) {
      print('✅ Post created successfully by creator');
    } else {
      print('❌ Failed to create post as creator');
    }
    
    // Test 3: Try to create post as different user
    final differentUserResult = await testCreatePostWithDifferentUser(pageId);
    if (differentUserResult['success']) {
      print('✅ Access correctly denied for non-creator');
    } else {
      print('❌ Access control failed - non-creator was allowed');
    }
    
    // Test 4: Delete page as creator
    final deleteResult = await testDeleteBabaPage(pageId);
    if (deleteResult['success']) {
      print('✅ Page deleted successfully by creator');
    } else {
      print('❌ Failed to delete page as creator');
    }
    
    print('\n🏁 Tests completed!');
  }
}

/// Main function to run tests
void main() async {
  await BabaPageAPITester.runAllTests();
}
