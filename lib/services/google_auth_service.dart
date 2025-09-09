import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleUser {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String? avatar;
  final String? token;

  GoogleUser({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.avatar,
    this.token,
  });

  factory GoogleUser.fromJson(Map<String, dynamic> json) {
    return GoogleUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatar: json['avatar'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
      'token': token,
    };
  }
}

class GoogleAuthService {
  static const String baseUrl = 'https://api-rgram1.vercel.app/api';

  /// Initialize Google OAuth flow
  static Future<String?> initGoogleAuth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/google/init'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data']['authUrl'];
        }
      }
      return null;
    } catch (error) {
      debugPrint('Google Auth Init Error: $error');
      return null;
    }
  }

  /// Complete Google OAuth flow with callback
  static Future<GoogleUser?> completeGoogleAuth({
    required String code,
    String state = 'test_state',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/callback?test=true&format=json'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          return GoogleUser.fromJson(jsonResponse['user']..['token'] = jsonResponse['token']);
        }
      }
      return null;
    } catch (error) {
      debugPrint('Google Auth Callback Error: $error');
      return null;
    }
  }

  /// Mock Google authentication for testing (since we can't open browser in Flutter)
  static Future<GoogleUser?> mockGoogleAuth() async {
    try {
      // Simulate the OAuth flow with mock data
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      
      // Return mock user data based on the API response
      return GoogleUser(
        id: "689c463f3b52aad73e878d1f",
        email: "mock_user@example.com",
        username: "mock_user896",
        fullName: "Mock User",
        avatar: "https://via.placeholder.com/150",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2ODljNDYzZjNiNTJhYWQ3M2U4NzhkMWYiLCJpYXQiOjE3NTUwNzcxMTEsImV4cCI6MTc1NzY2OTExMX0.qx_UQlfotuOkmXCLM9-KkiVK1ssvLnyoWyxxZJSiI38",
      );
    } catch (error) {
      debugPrint('Mock Google Auth Error: $error');
      return null;
    }
  }

  /// Sign out (clear local data)
  static Future<void> signOut() async {
    // In a real app, you would clear tokens and user data
    debugPrint('User signed out');
  }

  /// Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    // In a real app, you would check if tokens exist and are valid
    return false;
  }

  /// Get current user if signed in
  static Future<GoogleUser?> getCurrentUser() async {
    // In a real app, you would return the stored user data
    return null;
  }
}
