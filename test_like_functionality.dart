import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Like Functionality...\n');
  
  // Test data
  const String testPostId = '68d284718aee8df0e4c8e03f';
  const String testUserId = '68c98967a921a001da9787b3';
  const String testToken = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Replace with actual token
  
  // Test endpoints
  final endpoints = [
    'http://103.14.120.163:8081/api/feed/like/$testPostId',
  ];
  
  print('📋 Testing Like Endpoints:');
  for (int i = 0; i < endpoints.length; i++) {
    final endpoint = endpoints[i];
    print('\n${i + 1}. Testing: $endpoint');
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': testToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': testPostId,
          'contentType': 'post',
          'userId': testUserId,
          'action': 'like',
        }),
      );
      
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('   ✅ SUCCESS! This endpoint works.');
        break;
      } else if (response.statusCode == 404) {
        print('   ❌ 404 - Endpoint not found');
      } else {
        print('   ⚠️  ${response.statusCode} - Other error');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n📋 Testing Unlike Endpoints:');
  for (int i = 0; i < endpoints.length; i++) {
    final endpoint = endpoints[i];
    print('\n${i + 1}. Testing: $endpoint');
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': testToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': testPostId,
          'contentType': 'post',
          'userId': testUserId,
          'action': 'unlike',
        }),
      );
      
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('   ✅ SUCCESS! This endpoint works.');
        break;
      } else if (response.statusCode == 404) {
        print('   ❌ 404 - Endpoint not found');
      } else {
        print('   ⚠️  ${response.statusCode} - Other error');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
  
  print('\n🎯 Test completed!');
}
