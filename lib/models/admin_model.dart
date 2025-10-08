class AdminPermissions {
  final bool canManageUsers;
  final bool canDeleteContent;
  final bool canBlockUsers;
  final bool canViewAnalytics;
  final bool canModerateContent;
  final bool canManageReports;

  AdminPermissions({
    required this.canManageUsers,
    required this.canDeleteContent,
    required this.canBlockUsers,
    required this.canViewAnalytics,
    required this.canModerateContent,
    required this.canManageReports,
  });

  factory AdminPermissions.fromJson(Map<String, dynamic> json) {
    return AdminPermissions(
      canManageUsers: json['canManageUsers'] ?? false,
      canDeleteContent: json['canDeleteContent'] ?? false,
      canBlockUsers: json['canBlockUsers'] ?? false,
      canViewAnalytics: json['canViewAnalytics'] ?? false,
      canModerateContent: json['canModerateContent'] ?? false,
      canManageReports: json['canManageReports'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canManageUsers': canManageUsers,
      'canDeleteContent': canDeleteContent,
      'canBlockUsers': canBlockUsers,
      'canViewAnalytics': canViewAnalytics,
      'canModerateContent': canModerateContent,
      'canManageReports': canManageReports,
    };
  }
}

class AdminUser {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String avatar;

  AdminUser({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.avatar,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
    };
  }
}

class Admin {
  final String id;
  final AdminUser user;
  final String role;
  final AdminPermissions permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Admin({
    required this.id,
    required this.user,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['_id'] ?? json['id'] ?? '',
      user: AdminUser.fromJson(json['user'] ?? {}),
      role: json['role'] ?? '',
      permissions: AdminPermissions.fromJson(json['permissions'] ?? {}),
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'role': role,
      'permissions': permissions.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Super Admin Creation Models
class SuperAdminCreateRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String secretKey;

  SuperAdminCreateRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.secretKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'secretKey': secretKey,
    };
  }
}

class SuperAdminCreateResponse {
  final bool success;
  final String message;
  final SuperAdminCreateData? data;

  SuperAdminCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SuperAdminCreateResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SuperAdminCreateData.fromJson(json['data']) : null,
    );
  }
}

class SuperAdminCreateData {
  final Admin admin;
  final AdminUser user;

  SuperAdminCreateData({
    required this.admin,
    required this.user,
  });

  factory SuperAdminCreateData.fromJson(Map<String, dynamic> json) {
    return SuperAdminCreateData(
      admin: Admin.fromJson(json['admin'] ?? {}),
      user: AdminUser.fromJson(json['user'] ?? {}),
    );
  }
}

// Admin Creation Models
class AdminCreateRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String role;

  AdminCreateRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
    };
  }
}

class AdminCreateResponse {
  final bool success;
  final String message;
  final AdminCreateData? data;

  AdminCreateResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AdminCreateResponse.fromJson(Map<String, dynamic> json) {
    return AdminCreateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AdminCreateData.fromJson(json['data']) : null,
    );
  }
}

class AdminCreateData {
  final Admin admin;

  AdminCreateData({
    required this.admin,
  });

  factory AdminCreateData.fromJson(Map<String, dynamic> json) {
    return AdminCreateData(
      admin: Admin.fromJson(json['admin'] ?? {}),
    );
  }
}

// Admin Login Models
class AdminLoginRequest {
  final String username;
  final String password;

  AdminLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class AdminLoginResponse {
  final bool success;
  final String message;
  final AdminLoginData? data;

  AdminLoginResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) {
    return AdminLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AdminLoginData.fromJson(json['data']) : null,
    );
  }
}

class AdminLoginData {
  final String token;
  final AdminUser user;
  final Admin admin;
  final String expiresIn;

  AdminLoginData({
    required this.token,
    required this.user,
    required this.admin,
    required this.expiresIn,
  });

  factory AdminLoginData.fromJson(Map<String, dynamic> json) {
    return AdminLoginData(
      token: json['token'] ?? '',
      user: AdminUser.fromJson(json['user'] ?? {}),
      admin: Admin.fromJson(json['admin'] ?? {}),
      expiresIn: json['expiresIn'] ?? '',
    );
  }
}
