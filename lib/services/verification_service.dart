import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/verification_model.dart';

class VerificationService {
  static const String baseUrl = 'http://103.14.120.163:8081/api';
  static const String adminBaseUrl = 'http://103.14.120.163:8081/api/admin';

  // Headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Create verification request (User)
  static Future<VerificationRequestCreateResponse> createVerificationRequest({
    required VerificationRequestCreateRequest request,
    required String token,
  }) async {
    try {
      print('VerificationService: Creating verification request');
      
      final response = await http.post(
        Uri.parse('$baseUrl/verification/request'),
        headers: _authHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      print('VerificationService: Create request response status: ${response.statusCode}');
      print('VerificationService: Create request response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return VerificationRequestCreateResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return VerificationRequestCreateResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to create verification request',
        );
      }
    } catch (e) {
      print('VerificationService: Error creating verification request: $e');
      return VerificationRequestCreateResponse(
        success: false,
        message: 'Error creating verification request: $e',
      );
    }
  }

  /// Get verification requests list (Admin)
  static Future<VerificationListResponse> getVerificationRequests({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('VerificationService: Fetching verification requests - page: $page, limit: $limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/verification/request?page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      print('VerificationService: Get requests response status: ${response.statusCode}');
      print('VerificationService: Get requests response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return VerificationListResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return VerificationListResponse(
          success: false,
        );
      }
    } catch (e) {
      print('VerificationService: Error fetching verification requests: $e');
      return VerificationListResponse(
        success: false,
      );
    }
  }

  /// Get verification status (User)
  static Future<VerificationStatusResponse> getVerificationStatus({
    required String userId,
    required String token,
  }) async {
    try {
      print('VerificationService: Fetching verification status for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/verification/status?userId=$userId'),
        headers: _authHeaders(token),
      );

      print('VerificationService: Get status response status: ${response.statusCode}');
      print('VerificationService: Get status response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return VerificationStatusResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return VerificationStatusResponse(
          success: false,
        );
      }
    } catch (e) {
      print('VerificationService: Error fetching verification status: $e');
      return VerificationStatusResponse(
        success: false,
      );
    }
  }

  /// Approve verification request (Admin)
  static Future<AdminVerificationActionResponse> approveVerification({
    required String requestId,
    required String badgeType,
    required String expiresAt,
    required String token,
  }) async {
    try {
      print('VerificationService: Approving verification request: $requestId');
      
      final request = AdminVerificationActionRequest(
        action: 'approve',
        requestId: requestId,
        badgeType: badgeType,
        expiresAt: expiresAt,
      );
      
      final response = await http.post(
        Uri.parse('$adminBaseUrl/verification'),
        headers: _authHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      print('VerificationService: Approve response status: ${response.statusCode}');
      print('VerificationService: Approve response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AdminVerificationActionResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return AdminVerificationActionResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to approve verification',
        );
      }
    } catch (e) {
      print('VerificationService: Error approving verification: $e');
      return AdminVerificationActionResponse(
        success: false,
        message: 'Error approving verification: $e',
      );
    }
  }

  /// Reject verification request (Admin)
  static Future<AdminVerificationActionResponse> rejectVerification({
    required String requestId,
    required String reason,
    required String token,
  }) async {
    try {
      print('VerificationService: Rejecting verification request: $requestId');
      
      final request = AdminVerificationActionRequest(
        action: 'reject',
        requestId: requestId,
        badgeType: '',
        expiresAt: '',
      );
      
      final response = await http.post(
        Uri.parse('$adminBaseUrl/verification'),
        headers: _authHeaders(token),
        body: jsonEncode({
          ...request.toJson(),
          'reason': reason,
        }),
      );

      print('VerificationService: Reject response status: ${response.statusCode}');
      print('VerificationService: Reject response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AdminVerificationActionResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return AdminVerificationActionResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to reject verification',
        );
      }
    } catch (e) {
      print('VerificationService: Error rejecting verification: $e');
      return AdminVerificationActionResponse(
        success: false,
        message: 'Error rejecting verification: $e',
      );
    }
  }

  /// Revoke verification badge (Admin)
  static Future<AdminVerificationRevokeResponse> revokeVerification({
    required String userId,
    required String reason,
    required String token,
  }) async {
    try {
      print('VerificationService: Revoking verification for user: $userId');
      
      final request = AdminVerificationRevokeRequest(
        userId: userId,
        reason: reason,
      );
      
      final response = await http.delete(
        Uri.parse('$adminBaseUrl/verification'),
        headers: _authHeaders(token),
        body: jsonEncode(request.toJson()),
      );

      print('VerificationService: Revoke response status: ${response.statusCode}');
      print('VerificationService: Revoke response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return AdminVerificationRevokeResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = jsonDecode(response.body);
        return AdminVerificationRevokeResponse(
          success: false,
          message: errorResponse['message'] ?? 'Failed to revoke verification',
        );
      }
    } catch (e) {
      print('VerificationService: Error revoking verification: $e');
      return AdminVerificationRevokeResponse(
        success: false,
        message: 'Error revoking verification: $e',
      );
    }
  }

  /// Test verification API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('VerificationService: Testing verification API connection');
      
      final response = await http.get(
        Uri.parse('$baseUrl/verification/test'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('VerificationService: Test response status: ${response.statusCode}');
      print('VerificationService: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Verification API connection successful',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Verification API connection failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('VerificationService: Test connection error: $e');
      return {
        'success': false,
        'message': 'Verification API connection test failed: $e',
        'error': e.toString(),
      };
    }
  }
}
