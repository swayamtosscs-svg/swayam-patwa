class OtpSendRequest {
  final String email;
  final String purpose;

  OtpSendRequest({
    required this.email,
    required this.purpose,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'purpose': purpose,
    };
  }
}

class OtpSendResponse {
  final bool success;
  final String message;
  final OtpSendData? data;

  OtpSendResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OtpSendResponse.fromJson(Map<String, dynamic> json) {
    return OtpSendResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? OtpSendData.fromJson(json['data']) : null,
    );
  }
}

class OtpSendData {
  final String email;
  final String purpose;
  final String expiresAt;
  final String expiresIn;

  OtpSendData({
    required this.email,
    required this.purpose,
    required this.expiresAt,
    required this.expiresIn,
  });

  factory OtpSendData.fromJson(Map<String, dynamic> json) {
    return OtpSendData(
      email: json['email'] ?? '',
      purpose: json['purpose'] ?? '',
      expiresAt: json['expiresAt'] ?? '',
      expiresIn: json['expiresIn'] ?? '',
    );
  }
}

class OtpVerifyRequest {
  final String email;
  final String code;
  final String purpose;

  OtpVerifyRequest({
    required this.email,
    required this.code,
    required this.purpose,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      'purpose': purpose,
    };
  }
}

class OtpVerifyResponse {
  final bool success;
  final String message;
  final OtpVerifyData? data;

  OtpVerifyResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? OtpVerifyData.fromJson(json['data']) : null,
    );
  }
}

class OtpVerifyData {
  final String email;
  final bool verified;
  final String purpose;

  OtpVerifyData({
    required this.email,
    required this.verified,
    required this.purpose,
  });

  factory OtpVerifyData.fromJson(Map<String, dynamic> json) {
    return OtpVerifyData(
      email: json['email'] ?? '',
      verified: json['verified'] ?? false,
      purpose: json['purpose'] ?? '',
    );
  }
}
