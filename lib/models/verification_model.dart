// Verification Request Models
class VerificationRequest {
  final String id;
  final String userId;
  final String type;
  final String status;
  final PersonalInfo personalInfo;
  final List<SocialMediaProfile> socialMediaProfiles;
  final String reason;
  final String additionalInfo;
  final String priority;
  final Documents documents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.personalInfo,
    required this.socialMediaProfiles,
    required this.reason,
    required this.additionalInfo,
    required this.priority,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    // Handle both user object and userId string
    String userId = '';
    if (json['user'] is Map<String, dynamic>) {
      userId = json['user']['_id'] ?? json['user']['id'] ?? '';
    } else if (json['user'] is String) {
      userId = json['user'];
    } else {
      userId = json['userId'] ?? '';
    }

    return VerificationRequest(
      id: json['_id'] ?? json['id'] ?? '',
      userId: userId,
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] ?? {}),
      socialMediaProfiles: (json['socialMediaProfiles'] as List<dynamic>?)
          ?.map((profile) => SocialMediaProfile.fromJson(profile))
          .toList() ?? [],
      reason: json['reason'] ?? '',
      additionalInfo: json['additionalInfo'] ?? '',
      priority: json['priority'] ?? '',
      documents: Documents.fromJson(json['documents'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      reviewedBy: json['reviewedBy'],
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.tryParse(json['reviewedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'status': status,
      'personalInfo': personalInfo.toJson(),
      'socialMediaProfiles': socialMediaProfiles.map((profile) => profile.toJson()).toList(),
      'reason': reason,
      'additionalInfo': additionalInfo,
      'priority': priority,
      'documents': documents.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }
}

class PersonalInfo {
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String address;

  PersonalInfo({
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.address,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: json['fullName'] ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] ?? '') ?? DateTime.now(),
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}

class SocialMediaProfile {
  final String id;
  final String platform;
  final String username;
  final int followers;
  final bool verified;

  SocialMediaProfile({
    required this.id,
    required this.platform,
    required this.username,
    required this.followers,
    required this.verified,
  });

  factory SocialMediaProfile.fromJson(Map<String, dynamic> json) {
    return SocialMediaProfile(
      id: json['_id'] ?? json['id'] ?? '',
      platform: json['platform'] ?? '',
      username: json['username'] ?? '',
      followers: json['followers'] ?? 0,
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'username': username,
      'followers': followers,
      'verified': verified,
    };
  }
}

class Documents {
  final List<String> additionalDocuments;

  Documents({
    required this.additionalDocuments,
  });

  factory Documents.fromJson(Map<String, dynamic> json) {
    return Documents(
      additionalDocuments: List<String>.from(json['additionalDocuments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'additionalDocuments': additionalDocuments,
    };
  }
}

// Verification Request Creation Models
class VerificationRequestCreateRequest {
  final String type;
  final PersonalInfo personalInfo;
  final String reason;
  final List<SocialMediaProfile> socialMediaProfiles;
  final String additionalInfo;

  VerificationRequestCreateRequest({
    required this.type,
    required this.personalInfo,
    required this.reason,
    required this.socialMediaProfiles,
    required this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'personalInfo': personalInfo.toJson(),
      'reason': reason,
      'socialMediaProfiles': socialMediaProfiles.map((profile) => profile.toJson()).toList(),
      'additionalInfo': additionalInfo,
    };
  }
}

class VerificationRequestCreateResponse {
  final bool success;
  final String message;
  final VerificationRequestCreateData? data;

  VerificationRequestCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory VerificationRequestCreateResponse.fromJson(Map<String, dynamic> json) {
    return VerificationRequestCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? VerificationRequestCreateData.fromJson(json['data']) : null,
    );
  }
}

class VerificationRequestCreateData {
  final VerificationRequest request;

  VerificationRequestCreateData({
    required this.request,
  });

  factory VerificationRequestCreateData.fromJson(Map<String, dynamic> json) {
    return VerificationRequestCreateData(
      request: VerificationRequest.fromJson(json['request'] ?? {}),
    );
  }
}

// Verification List Models
class VerificationListResponse {
  final bool success;
  final VerificationListData? data;

  VerificationListResponse({
    required this.success,
    this.data,
  });

  factory VerificationListResponse.fromJson(Map<String, dynamic> json) {
    return VerificationListResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? VerificationListData.fromJson(json['data']) : null,
    );
  }
}

class VerificationListData {
  final List<VerificationRequest> requests;
  final Pagination pagination;

  VerificationListData({
    required this.requests,
    required this.pagination,
  });

  factory VerificationListData.fromJson(Map<String, dynamic> json) {
    return VerificationListData(
      requests: (json['requests'] as List<dynamic>?)
          ?.map((request) => VerificationRequest.fromJson(request))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPrevPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

// Verification Status Models
class VerificationStatusResponse {
  final bool success;
  final VerificationStatusData? data;

  VerificationStatusResponse({
    required this.success,
    this.data,
  });

  factory VerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return VerificationStatusResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? VerificationStatusData.fromJson(json['data']) : null,
    );
  }
}

class VerificationStatusData {
  final VerificationUser user;
  final VerificationBadge? currentBadge;
  final List<VerificationBadge> verificationHistory;
  final bool isVerified;
  final String? verificationType;

  VerificationStatusData({
    required this.user,
    this.currentBadge,
    required this.verificationHistory,
    required this.isVerified,
    this.verificationType,
  });

  factory VerificationStatusData.fromJson(Map<String, dynamic> json) {
    return VerificationStatusData(
      user: VerificationUser.fromJson(json['user'] ?? {}),
      currentBadge: json['currentBadge'] != null 
          ? VerificationBadge.fromJson(json['currentBadge']) 
          : null,
      verificationHistory: (json['verificationHistory'] as List<dynamic>?)
          ?.map((badge) => VerificationBadge.fromJson(badge))
          .toList() ?? [],
      isVerified: json['isVerified'] ?? false,
      verificationType: json['verificationType'],
    );
  }
}

class VerificationUser {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String avatar;
  final bool isVerified;
  final String? verificationType;

  VerificationUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.isVerified,
    this.verificationType,
  });

  factory VerificationUser.fromJson(Map<String, dynamic> json) {
    return VerificationUser(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      isVerified: json['isVerified'] ?? false,
      verificationType: json['verificationType'],
    );
  }
}

class VerificationBadge {
  final String id;
  final String userId;
  final String type;
  final String status;
  final DateTime verifiedAt;
  final String? verifiedBy;
  final DateTime expiresAt;
  final String reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  VerificationBadge({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.verifiedAt,
    this.verifiedBy,
    required this.expiresAt,
    required this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VerificationBadge.fromJson(Map<String, dynamic> json) {
    return VerificationBadge(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] ?? json['userId'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      verifiedAt: DateTime.tryParse(json['verifiedAt'] ?? '') ?? DateTime.now(),
      verifiedBy: json['verifiedBy'],
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now(),
      reason: json['reason'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// Admin Verification Action Models
class AdminVerificationActionRequest {
  final String action;
  final String requestId;
  final String badgeType;
  final String expiresAt;

  AdminVerificationActionRequest({
    required this.action,
    required this.requestId,
    required this.badgeType,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'requestId': requestId,
      'badgeType': badgeType,
      'expiresAt': expiresAt,
    };
  }
}

class AdminVerificationActionResponse {
  final bool success;
  final String message;
  final AdminVerificationActionData? data;

  AdminVerificationActionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AdminVerificationActionResponse.fromJson(Map<String, dynamic> json) {
    return AdminVerificationActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AdminVerificationActionData.fromJson(json['data']) : null,
    );
  }
}

class AdminVerificationActionData {
  final VerificationRequest request;
  final VerificationBadge badge;
  final String badgeType;

  AdminVerificationActionData({
    required this.request,
    required this.badge,
    required this.badgeType,
  });

  factory AdminVerificationActionData.fromJson(Map<String, dynamic> json) {
    return AdminVerificationActionData(
      request: VerificationRequest.fromJson(json['request'] ?? {}),
      badge: VerificationBadge.fromJson(json['badge'] ?? {}),
      badgeType: json['badgeType'] ?? '',
    );
  }
}

// Admin Verification Revoke Models
class AdminVerificationRevokeRequest {
  final String userId;
  final String reason;

  AdminVerificationRevokeRequest({
    required this.userId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'reason': reason,
    };
  }
}

class AdminVerificationRevokeResponse {
  final bool success;
  final String message;
  final AdminVerificationRevokeData? data;

  AdminVerificationRevokeResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AdminVerificationRevokeResponse.fromJson(Map<String, dynamic> json) {
    return AdminVerificationRevokeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AdminVerificationRevokeData.fromJson(json['data']) : null,
    );
  }
}

class AdminVerificationRevokeData {
  final VerificationBadge badge;

  AdminVerificationRevokeData({
    required this.badge,
  });

  factory AdminVerificationRevokeData.fromJson(Map<String, dynamic> json) {
    return AdminVerificationRevokeData(
      badge: VerificationBadge.fromJson(json['badge'] ?? {}),
    );
  }
}
