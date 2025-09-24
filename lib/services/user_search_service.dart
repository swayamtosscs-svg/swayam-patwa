import 'dart:convert';
import 'package:http/http.dart' as http;

class UserSearchResult {
  final String id;
  final String username;
  final String fullName;
  final String? profileImageUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool isFollowedByCurrentUser;
  final String? bio;

  UserSearchResult({
    required this.id,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isVerified,
    required this.isFollowedByCurrentUser,
    this.bio,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['user_id']?.toString() ?? '',
      username: json['username'] ?? json['user_name'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? json['name'] ?? '',
      profileImageUrl: json['avatar'] ?? json['profile_image'] ?? json['profile_picture'] ?? json['profileImageUrl'],
      followersCount: int.tryParse(json['followersCount']?.toString() ?? json['followers_count']?.toString() ?? '0') ?? 0,
      followingCount: int.tryParse(json['followingCount']?.toString() ?? json['following_count']?.toString() ?? '0') ?? 0,
      postsCount: int.tryParse(json['postsCount']?.toString() ?? json['posts_count']?.toString() ?? '0') ?? 0,
      isVerified: json['isVerified'] == true || json['is_verified'] == true || json['verified'] == true,
      isFollowedByCurrentUser: json['isFollowedByCurrentUser'] == true || json['is_followed'] == true,
      bio: json['bio'] ?? json['description'],
    );
  }
}

class UserSearchService {
  static const String baseUrl = 'http://103.14.120.163:8081';
  
  static Map<String, String> _authHeaders(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Search for users using the main search API
  static Future<List<UserSearchResult>> searchUsers({
    required String query,
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('Searching users with query: $query');
      
      // Try the main search API first
      final response = await http.get(
        Uri.parse('$baseUrl/api/search?q=$query&type=users&page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      print('Search API response status: ${response.statusCode}');
      print('Search API response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true || data['status'] == 'success') {
          List<dynamic> usersData = [];
          
          // Handle different response structures
          if (data['data'] != null) {
            if (data['data']['users'] != null) {
              usersData = data['data']['users'];
            } else if (data['data'] is List) {
              usersData = data['data'];
            } else if (data['data']['data'] != null) {
              usersData = data['data']['data'];
            }
          } else if (data['users'] != null) {
            usersData = data['users'];
          } else if (data['results'] != null) {
            usersData = data['results'];
          }

          print('Found ${usersData.length} users in response');
          
          List<UserSearchResult> users = [];
          for (final userData in usersData) {
            try {
              final user = UserSearchResult.fromJson(userData);
              users.add(user);
              print('Added user: ${user.username}');
            } catch (e) {
              print('Error parsing user data: $e');
              print('User data: $userData');
            }
          }
          
          return users;
        } else {
          print('API returned error: ${data['message'] ?? data['error']}');
          return [];
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in searchUsers: $e');
      return [];
    }
  }

  /// Search for users using the alternative search API
  static Future<List<UserSearchResult>> searchUsersAlternative({
    required String query,
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('Searching users with alternative API: $query');
      
      final response = await http.get(
        Uri.parse('$baseUrl/search-users.php?q=$query&page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      print('Alternative API response status: ${response.statusCode}');
      print('Alternative API response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true || data['status'] == 'success') {
          List<dynamic> usersData = [];
          
          // Handle different response structures
          if (data['data'] != null) {
            if (data['data']['users'] != null) {
              usersData = data['data']['users'];
            } else if (data['data'] is List) {
              usersData = data['data'];
            }
          } else if (data['users'] != null) {
            usersData = data['users'];
          }

          print('Found ${usersData.length} users in alternative response');
          
          List<UserSearchResult> users = [];
          for (final userData in usersData) {
            try {
              final user = UserSearchResult.fromJson(userData);
              users.add(user);
            } catch (e) {
              print('Error parsing user data in alternative API: $e');
            }
          }
          
          return users;
        } else {
          print('Alternative API returned error: ${data['message'] ?? data['error']}');
          return [];
        }
      } else {
        print('Alternative API HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error in searchUsersAlternative: $e');
      return [];
    }
  }

  /// Search for users with fallback to both APIs
  static Future<List<UserSearchResult>> searchUsersWithFallback({
    required String query,
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    // Try main API first
    List<UserSearchResult> users = await searchUsers(
      query: query,
      token: token,
      page: page,
      limit: limit,
    );

    // If no results, try alternative API
    if (users.isEmpty) {
      print('No results from main API, trying alternative API');
      users = await searchUsersAlternative(
        query: query,
        token: token,
        page: page,
        limit: limit,
      );
    }

    // Return empty list if no real users found (no mock users)
    if (users.isEmpty) {
      print('No real users found for query: $query');
    }

    return users;
  }

}
