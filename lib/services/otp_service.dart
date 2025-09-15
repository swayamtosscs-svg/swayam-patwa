import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/otp_models.dart';

class OtpService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/auth';

  /// Send OTP to email for verification
  static Future<OtpSendResponse> sendOtp({
    required String email,
    required String purpose,
  }) async {
    try {
      print('OtpService: Sending OTP to $email for $purpose');
      
      final request = OtpSendRequest(
        email: email,
        purpose: purpose,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/otp/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('OtpService: Send OTP response status: ${response.statusCode}');
      print('OtpService: Send OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return OtpSendResponse.fromJson(jsonResponse);
        } catch (e) {
          print('OtpService: Error parsing send OTP response: $e');
          return OtpSendResponse(
            success: false,
            message: 'Error parsing response: $e',
          );
        }
      } else {
        try {
          final jsonResponse = jsonDecode(response.body);
          return OtpSendResponse(
            success: false,
            message: jsonResponse['message'] ?? 'Failed to send OTP: ${response.statusCode}',
          );
        } catch (e) {
          return OtpSendResponse(
            success: false,
            message: 'Failed to send OTP: HTTP ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('OtpService: Error sending OTP: $e');
      return OtpSendResponse(
        success: false,
        message: 'Error sending OTP: $e',
      );
    }
  }

  /// Verify OTP code
  static Future<OtpVerifyResponse> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    try {
      print('OtpService: Verifying OTP for $email with code $code for $purpose');
      
      final request = OtpVerifyRequest(
        email: email,
        code: code,
        purpose: purpose,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/otp/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('OtpService: Verify OTP response status: ${response.statusCode}');
      print('OtpService: Verify OTP response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return OtpVerifyResponse.fromJson(jsonResponse);
        } catch (e) {
          print('OtpService: Error parsing verify OTP response: $e');
          return OtpVerifyResponse(
            success: false,
            message: 'Error parsing response: $e',
          );
        }
      } else {
        try {
          final jsonResponse = jsonDecode(response.body);
          return OtpVerifyResponse(
            success: false,
            message: jsonResponse['message'] ?? 'Failed to verify OTP: ${response.statusCode}',
          );
        } catch (e) {
          return OtpVerifyResponse(
            success: false,
            message: 'Failed to verify OTP: HTTP ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('OtpService: Error verifying OTP: $e');
      return OtpVerifyResponse(
        success: false,
        message: 'Error verifying OTP: $e',
      );
    }
  }
}
