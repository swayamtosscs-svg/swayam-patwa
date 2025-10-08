import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_model.dart';

class AdminService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/admin';

  // Headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Create Super Admin
  static Future<SuperAdminCreateResponse> createSuperAdmin({
    required SuperAdminCreateRequest request,
  }) async {
    try {
      print('AdminService: Creating super admin: ${request.username}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/create-super-admin'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('AdminService: Super admin creation response status: ${response.statusCode}');
      print('AdminService: Super admin creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return SuperAdminCreateResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return SuperAdminCreateResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to create super admin',
        );
      }
    } catch (e) {
      print('AdminService: Error creating super admin: $e');
      return SuperAdminCreateResponse(
        success: false,
        message: 'Error creating super admin: $e',
      );
    }
  }

  /// Create Admin (requires super admin token)
  static Future<AdminCreateResponse> createAdmin({
    required AdminCreateRequest request,
    required String token,
  }) async {
    try {
      print('AdminService: Creating admin: ${request.username}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: _authHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      print('AdminService: Admin creation response status: ${response.statusCode}');
      print('AdminService: Admin creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AdminCreateResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return AdminCreateResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to create admin',
        );
      }
    } catch (e) {
      print('AdminService: Error creating admin: $e');
      return AdminCreateResponse(
        success: false,
        message: 'Error creating admin: $e',
      );
    }
  }

  /// Admin Login
  static Future<AdminLoginResponse> login({
    required AdminLoginRequest request,
  }) async {
    try {
      print('AdminService: Admin login attempt for: ${request.username}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('AdminService: Admin login response status: ${response.statusCode}');
      print('AdminService: Admin login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AdminLoginResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return AdminLoginResponse(
          success: false,
          message: errorResponse['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      print('AdminService: Error during admin login: $e');
      return AdminLoginResponse(
        success: false,
        message: 'Error during login: $e',
      );
    }
  }

  /// Test admin API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('AdminService: Testing admin API connection');
      
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('AdminService: Test response status: ${response.statusCode}');
      print('AdminService: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Admin API connection successful',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Admin API connection failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('AdminService: Test connection error: $e');
      return {
        'success': false,
        'message': 'Admin API connection test failed: $e',
        'error': e.toString(),
      };
    }
  }
}
