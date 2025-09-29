import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(LikeButtonTestApp());
}

class LikeButtonTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Like Button Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LikeButtonTestScreen(),
    );
  }
}

class LikeButtonTestScreen extends StatefulWidget {
  @override
  _LikeButtonTestScreenState createState() => _LikeButtonTestScreenState();
}

class _LikeButtonTestScreenState extends State<LikeButtonTestScreen> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;

  // Test data from your working API
  final String testBabaPageId = '68da2be0cffda6e29eb5332f';
  final String testReelId = '68da64cd8cee67f3b8fbe189';
  final String testUserId = '68da2be0cffda6e29eb5332f';

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    try {
      final url = 'http://103.14.120.163:8081/api/baba-pages/$testBabaPageId/like?contentId=$testReelId&contentType=video&userId=$testUserId';
      
      print('🔄 Loading like status from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      print('🔄 Response status: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _isLiked = data['data']['isLiked'] ?? false;
            _likeCount = data['data']['likesCount'] ?? 0;
          });
          print('✅ Like status loaded: isLiked=$_isLiked, count=$_likeCount');
        }
      }
    } catch (e) {
      print('❌ Error loading like status: $e');
    }
  }

  Future<void> _handleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = 'http://103.14.120.163:8081/api/baba-pages/$testBabaPageId/like';
      
      print('🔥 Calling like API: $url');
      print('🔥 Action: ${_isLiked ? "unlike" : "like"}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contentId': testReelId,
          'contentType': 'video',
          'userId': testUserId,
          'action': _isLiked ? 'unlike' : 'like',
        }),
      );

      print('🔥 Response status: ${response.statusCode}');
      print('🔥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _isLiked = data['data']['isLiked'] ?? false;
            _likeCount = data['data']['likesCount'] ?? 0;
          });
          print('✅ Like action successful: isLiked=$_isLiked, count=$_likeCount');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLiked ? 'Liked! ❤️' : 'Unliked! 💔'),
              backgroundColor: _isLiked ? Colors.red : Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ API call failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like/unlike'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Like Button Test'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Video placeholder
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Video content placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Baba Ji Video',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          'Reel ID: $testReelId',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  
                  // Like button (similar to video player)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        // Like button
                        GestureDetector(
                          onTap: _handleLike,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    _isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: _isLiked ? Colors.red : Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                        SizedBox(height: 8),
                        // Like count
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _likeCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Status info
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Like Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Is Liked: $_isLiked'),
                    Text('Like Count: $_likeCount'),
                    Text('Loading: $_isLoading'),
                    SizedBox(height: 16),
                    Text('Test Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Baba Page ID: $testBabaPageId'),
                    Text('Reel ID: $testReelId'),
                    Text('User ID: $testUserId'),
                  ],
                ),
              ),
            ),
            
            // Manual test button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLike,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLiked ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: Text(_isLoading ? 'Loading...' : (_isLiked ? 'Unlike' : 'Like')),
            ),
          ],
        ),
      ),
    );
  }
}
