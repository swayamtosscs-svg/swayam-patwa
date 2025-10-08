import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _adminToken;
  Admin? _currentAdmin;
  AdminUser? _currentAdminUser;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get adminToken => _adminToken;
  Admin? get currentAdmin => _currentAdmin;
  AdminUser? get currentAdminUser => _currentAdminUser;

  AdminProvider() {
    _initializeAdminAuth();
  }

  Future<void> _initializeAdminAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadAdminToken();
    } catch (e) {
      print('AdminProvider: Error during initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAdminToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('admin_token');
      
      if (storedToken != null && storedToken.isNotEmpty) {
        print('AdminProvider: Found stored admin token');
        _adminToken = storedToken;
        _isAuthenticated = true;
        // Note: We don't load admin profile here as we don't have a profile endpoint
        // The admin data will be loaded during login
      } else {
        print('AdminProvider: No stored admin token found');
        _adminToken = null;
        _isAuthenticated = false;
      }
      
      notifyListeners();
    } catch (e) {
      print('AdminProvider: Error loading admin token: $e');
      _adminToken = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<void> _saveAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_token', token);
    _adminToken = token;
  }

  Future<void> _clearAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    _adminToken = null;
    _currentAdmin = null;
    _currentAdminUser = null;
    _isAuthenticated = false;
  }

  /// Handle successful admin login
  Future<void> handleSuccessfulLogin(Map<String, dynamic> loginData) async {
    try {
      final token = loginData['token'];
      final userData = loginData['user'];
      final adminData = loginData['admin'];
      
      await _saveAdminToken(token);
      
      // Create admin user from login data
      _currentAdminUser = AdminUser.fromJson(userData);
      
      // Create admin object from admin data
      if (adminData != null) {
        _currentAdmin = Admin.fromJson(adminData);
      } else {
        // Create basic admin object if admin data is not separate
        _currentAdmin = Admin(
          id: userData['_id'] ?? userData['id'] ?? '',
          user: _currentAdminUser!,
          role: userData['role'] ?? 'admin',
          permissions: AdminPermissions(
            canManageUsers: userData['role'] == 'super_admin',
            canDeleteContent: true,
            canBlockUsers: true,
            canViewAnalytics: true,
            canModerateContent: true,
            canManageReports: true,
          ),
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      _isAuthenticated = true;
      _error = null;
      
      print('AdminProvider: Admin login successful for: ${_currentAdminUser?.username}');
      notifyListeners();
    } catch (e) {
      print('AdminProvider: Error handling successful login: $e');
      _error = 'Error saving login data: $e';
      notifyListeners();
    }
  }

  /// Create Super Admin
  Future<void> createSuperAdmin({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String secretKey,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final request = SuperAdminCreateRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        secretKey: secretKey,
      );

      final response = await AdminService.createSuperAdmin(request: request);
      
      if (response.success) {
        print('AdminProvider: Super admin created successfully');
        // Optionally auto-login after creation
        // await login(username: username, password: password);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Error creating super admin: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Create Admin (requires super admin token)
  Future<void> createAdmin({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (_adminToken == null) {
      _error = 'Admin authentication required';
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final request = AdminCreateRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );

      final response = await AdminService.createAdmin(
        request: request,
        token: _adminToken!,
      );
      
      if (response.success) {
        print('AdminProvider: Admin created successfully');
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Error creating admin: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Admin Login
  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final request = AdminLoginRequest(
        username: username,
        password: password,
      );

      final response = await AdminService.login(request: request);
      
      if (response.success && response.data != null) {
        await handleSuccessfulLogin({
          'token': response.data!.token,
          'user': response.data!.user.toJson(),
          'admin': response.data!.admin.toJson(),
          'expiresIn': response.data!.expiresIn,
        });
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Error during login: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    print('AdminProvider: Logging out admin');
    await _clearAdminToken();
    notifyListeners();
  }

  /// Test admin API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      return await AdminService.testConnection();
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection test failed: $e',
      };
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
