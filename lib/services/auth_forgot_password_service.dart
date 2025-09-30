import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthForgotPasswordService {
  static const String baseUrl = 'http://103.14.120.163:8081';
  static const String authApiUrl = 'http://103.14.120.163:8081/api/auth';

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

      // Try multiple possible endpoints for forgot password
      final endpoints = [
        '$authApiUrl/forgot-password',
        '$baseUrl/forgot-password.php',
        '$baseUrl/api/auth/forgot-password',
        '$baseUrl/reset-password.php',
        '$baseUrl/api/reset-password',
      ];

      http.Response? response;
      String? usedEndpoint;

      for (final endpoint in endpoints) {
        try {
          print('AuthForgotPasswordService: Trying endpoint: $endpoint');
          
          response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'email': email,
            }),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

          print('AuthForgotPasswordService: Response status for $endpoint: ${response.statusCode}');
          
          // If we get a valid response (not 405 Method Not Allowed), use this endpoint
          if (response.statusCode != 405) {
            usedEndpoint = endpoint;
            break;
          }
        } catch (e) {
          print('AuthForgotPasswordService: Failed endpoint $endpoint: $e');
          continue;
        }
      }

      if (response == null) {
        return {
          'success': false,
          'message': 'All forgot password endpoints are unavailable. Please try again later.',
          'error': 'No Available Endpoints',
        };
      }

      print('AuthForgotPasswordService: Using endpoint: $usedEndpoint');
      print('AuthForgotPasswordService: Final response status: ${response.statusCode}');
      print('AuthForgotPasswordService: Final response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          print('AuthForgotPasswordService: Forgot password request successful');
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Password reset link sent successfully to your email',
            'email': email,
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
          'message': 'Invalid email address or user not found. Please check your email and try again.',
          'error': 'Bad Request',
        };
      } else if (response.statusCode == 404) {
        print('AuthForgotPasswordService: User not found');
        return {
          'success': false,
          'message': 'No account found with this email address. Please check your email or sign up for a new account.',
          'error': 'User Not Found',
        };
      } else if (response.statusCode == 429) {
        print('AuthForgotPasswordService: Too many requests');
        return {
          'success': false,
          'message': 'Too many password reset requests. Please wait a few minutes before trying again.',
          'error': 'Rate Limited',
        };
      } else if (response.statusCode == 405) {
        print('AuthForgotPasswordService: Method not allowed');
        return {
          'success': false,
          'message': 'Forgot password service is not available. Please try the OTP method instead.',
          'error': 'Method Not Allowed',
        };
      } else if (response.statusCode == 500) {
        print('AuthForgotPasswordService: Server error');
        try {
          final errorResponse = json.decode(response.body);
          if (errorResponse['message']?.contains('Email service error') == true) {
            return {
              'success': false,
              'message': 'Email service is temporarily unavailable. Please try again later or contact support.',
              'error': 'Email Service Error',
            };
          }
        } catch (e) {
          // Fall through to default error message
        }
        return {
          'success': false,
          'message': 'Server is temporarily unavailable. Please try again in a few minutes.',
          'error': 'Server Error',
        };
      } else {
        print('AuthForgotPasswordService: Request failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Unable to send password reset link. Please try again later.',
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



