import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Baba Ji Reel Like Functionality...\n');
  
  // Test data for Baba Ji reels
  const String testReelId = '68d284718aee8df0e4c8e03f'; // Replace with actual reel ID
  const String testBabaPageId = '68c98967a921a001da9787b3'; // Replace with actual Baba page ID
  const String testUserId = '68c98967a921a001da9787b3'; // Replace with actual user ID
  
  // Test Baba Ji reel like endpoint
  const String babaReelLikeEndpoint = 'http://103.14.120.163:8081/api/baba-pages/$testBabaPageId/like';
  
  print('📋 Testing Baba Ji Reel Like Endpoint:');
  print('Endpoint: $babaReelLikeEndpoint');
  print('Reel ID: $testReelId');
  print('Baba Page ID: $testBabaPageId');
  print('User ID: $testUserId\n');
  
  // Test Like Action
  print('1. Testing LIKE action:');
  try {
    final likeResponse = await http.post(
      Uri.parse(babaReelLikeEndpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contentId': '68da64cd8cee67f3b8fbe189', // Clean reel ID without baba_reel_ prefix
        'contentType': 'video', // Using video contentType for reels
        'userId': testUserId,
        'action': 'like',
      }),
    );
    
    print('   Status: ${likeResponse.statusCode}');
    print('   Response: ${likeResponse.body}');
    
    if (likeResponse.statusCode == 200 || likeResponse.statusCode == 201) {
      print('   ✅ SUCCESS! Like action works.');
      
      // Parse response to get like count
      try {
        final responseData = jsonDecode(likeResponse.body);
        if (responseData['data'] != null && responseData['data']['likesCount'] != null) {
          print('   📊 Like count: ${responseData['data']['likesCount']}');
        }
      } catch (e) {
        print('   ⚠️  Could not parse like count from response');
      }
    } else if (likeResponse.statusCode == 404) {
      print('   ❌ 404 - Reel or Baba page not found');
    } else {
      print('   ⚠️  ${likeResponse.statusCode} - Other error');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  print('\n2. Testing UNLIKE action:');
  try {
    final unlikeResponse = await http.post(
      Uri.parse(babaReelLikeEndpoint),
      headers: {
        'Content-Type': 'application/json',
      },
        body: jsonEncode({
          'contentId': testReelId,
          'contentType': 'video', // Using video contentType for reels
          'userId': testUserId,
          'action': 'unlike',
        }),
    );
    
    print('   Status: ${unlikeResponse.statusCode}');
    print('   Response: ${unlikeResponse.body}');
    
    if (unlikeResponse.statusCode == 200 || unlikeResponse.statusCode == 201) {
      print('   ✅ SUCCESS! Unlike action works.');
      
      // Parse response to get like count
      try {
        final responseData = jsonDecode(unlikeResponse.body);
        if (responseData['data'] != null && responseData['data']['likesCount'] != null) {
          print('   📊 Like count: ${responseData['data']['likesCount']}');
        }
      } catch (e) {
        print('   ⚠️  Could not parse like count from response');
      }
    } else if (unlikeResponse.statusCode == 404) {
      print('   ❌ 404 - Reel or Baba page not found');
    } else {
      print('   ⚠️  ${unlikeResponse.statusCode} - Other error');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  print('\n3. Testing GET like status:');
  try {
    final statusResponse = await http.get(
      Uri.parse('$babaReelLikeEndpoint?contentId=$testReelId&contentType=video&userId=$testUserId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    
    print('   Status: ${statusResponse.statusCode}');
    print('   Response: ${statusResponse.body}');
    
    if (statusResponse.statusCode == 200) {
      print('   ✅ SUCCESS! Get like status works.');
      
      // Parse response to get like status
      try {
        final responseData = jsonDecode(statusResponse.body);
        if (responseData['data'] != null) {
          print('   📊 Liked: ${responseData['data']['liked']}');
          print('   📊 Like count: ${responseData['data']['likesCount']}');
        }
      } catch (e) {
        print('   ⚠️  Could not parse like status from response');
      }
    } else if (statusResponse.statusCode == 404) {
      print('   ❌ 404 - Reel or Baba page not found');
    } else {
      print('   ⚠️  ${statusResponse.statusCode} - Other error');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }
  
  print('\n🎯 Baba Ji Reel Like Test completed!');
  print('\n📝 Note: Make sure to replace the test IDs with actual reel IDs and Baba page IDs from your database.');
  print('📝 You can find these IDs by checking the Baba Ji pages and their reels in your app.');
}
