import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthForgotPasswordService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/auth';

  /// Send forgot password request
  static Future<Map<String, dynamic>> sendForgotPasswordRequest({
    required String email,
  }) async {
    try {
      print('AuthForgotPasswordService: Starting forgot password request for email: $email');
      
      if (email.isEmpty) {
        return {
          'success': false,
          'message': 'Email is required',
          'error': 'Missing Email',
        };
      }

      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
          'error': 'Invalid Email Format',
        };
      }

      final url = '$baseUrl/forgot-password';
      print('AuthForgotPasswordService: Request URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      print('AuthForgotPasswordService: Response status: ${response.statusCode}');
      print('AuthForgotPasswordService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          print('AuthForgotPasswordService: Forgot password request successful');
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Password reset link sent successfully',
          };
        } else {
          print('AuthForgotPasswordService: Forgot password request failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to send password reset link',
            'error': 'Request Failed',
          };
        }
      } else if (response.statusCode == 400) {
        print('AuthForgotPasswordService: Bad request - invalid email or user not found');
        return {
          'success': false,
          'message': 'Invalid email address or user not found',
          'error': 'Bad Request',
        };
      } else if (response.statusCode == 429) {
        print('AuthForgotPasswordService: Too many requests');
        return {
          'success': false,
          'message': 'Too many requests. Please try again later.',
          'error': 'Rate Limited',
        };
      } else {
        print('AuthForgotPasswordService: Request failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to send password reset link. Please try again later.',
          'error': 'Server Error',
        };
      }
    } catch (e) {
      print('AuthForgotPasswordService: Error: $e');
      return {
        'success': false,
        'message': 'An error occurred while sending the password reset link: ${e.toString()}',
        'error': 'Network Error',
      };
    }
  }

  /// Test API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('AuthForgotPasswordService: Testing API connection');
      
      final url = Uri.parse('$baseUrl/test');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection test timed out');
        },
      );

      print('AuthForgotPasswordService: Test response status: ${response.statusCode}');
      
      return {
        'success': response.statusCode == 200,
        'message': response.statusCode == 200 
            ? 'API connection successful' 
            : 'API connection failed with status ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('AuthForgotPasswordService: Connection test error: $e');
      return {
        'success': false,
        'message': 'API connection test failed: ${e.toString()}',
        'error': 'Connection Error',
      };
    }
  }
}



