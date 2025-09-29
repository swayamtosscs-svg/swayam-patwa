import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to delete the Dhani Mata page
/// This will test the creator access control

void main() async {
  const String baseUrl = 'http://103.14.120.163:8081/api';
  const String pageId = '68da2f62cffda6e29eb53387'; // Dhani Mata page ID
  const String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGQxM2I0ZGE1NjRlY2RkYTA2NjhhMDMiLCJpYXQiOjE3NTkxMjY1MTAsImV4cCI6MTc2MTcxODUxMH0.krjnQr7CtN9tbKSBl4WkBG6PEbVOnjNg6ZMZghYynuE';

  print('🧪 Testing deletion of Dhani Mata page...');
  print('Page ID: $pageId');
  
  // First, let's check the page details
  print('\n1. Fetching page details...');
  try {
    final getResponse = await http.get(
      Uri.parse('$baseUrl/baba-pages/$pageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Status: ${getResponse.statusCode}');
    print('Response: ${getResponse.body}');
    
    if (getResponse.statusCode == 200) {
      final pageData = jsonDecode(getResponse.body);
      final createdBy = pageData['data']['createdBy'];
      print('Page created by: $createdBy');
      
      // Extract user ID from token
      final parts = token.split('.');
      final payload = parts[1];
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Url.decode(paddedPayload));
      final payloadJson = jsonDecode(decoded);
      final userId = payloadJson['userId'];
      print('Current user ID: $userId');
      
      if (createdBy == userId) {
        print('✅ User is the creator - deletion should work');
      } else {
        print('❌ User is not the creator - deletion should fail');
      }
    }
  } catch (e) {
    print('Error fetching page: $e');
  }

  // Now try to delete the page
  print('\n2. Attempting to delete the page...');
  try {
    final deleteResponse = await http.delete(
      Uri.parse('$baseUrl/baba-pages/$pageId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Status: ${deleteResponse.statusCode}');
    print('Response: ${deleteResponse.body}');
    
    if (deleteResponse.statusCode == 200) {
      print('✅ Page deleted successfully!');
    } else {
      print('❌ Failed to delete page');
    }
  } catch (e) {
    print('Error deleting page: $e');
  }
}
