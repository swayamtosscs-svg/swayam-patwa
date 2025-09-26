import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
// import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../screens/home_screen.dart';
import '../services/auth_forgot_password_service.dart';
import '../services/theme_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isForgotPasswordLoading = false;
  String? _error;
  bool _isUsernameLogin = false;
  bool _isPasswordVisible = false;


  Future<void> _login() async {
    print('LoginScreen: Login method called');
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Debug: Log the request data
      final requestData = {
        if (_isUsernameLogin) 'username': _emailController.text else 'email': _emailController.text,
        'password': _passwordController.text,
      };
      print('Login request data: $requestData');
      
      // Real API call to login endpoint
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      // Debug: Log the response
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');
        
        if (data['success'] == true) {
          // Check if required data exists
          final token = data['data']?['token'];
          final user = data['data']?['user'];
          
          if (token != null && user != null) {
            // Login successful - store token and redirect to spiritual path
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.handleSuccessfulLogin(token, user);
            
            // Show success message
            final userName = user['fullName'] ?? user['username'] ?? 'User';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, $userName!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Navigate to spiritual section
            print('Navigating to spiritual section...');
            try {
              Navigator.pushReplacementNamed(context, '/home');
            } catch (e) {
              print('Named route navigation failed: $e, trying direct navigation');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else {
            // Missing required data
            setState(() {
              _error = 'Invalid response: Missing token or user data';
            });
            print('Missing data - Token: $token, User: $user');
          }
        } else {
          setState(() {
            _error = data['message'] ?? 'Login failed';
          });
        }
      } else {
        // Try to get the actual error message from the API
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            _error = errorData['message'] ?? 'Network error. Status: ${response.statusCode}';
          });
        } catch (e) {
          setState(() {
            _error = 'Network error. Status: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    // Show dialog to get email if not already entered
    String email = _emailController.text.trim();
    
    if (email.isEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Reset Password',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address to receive a password reset link:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value.trim(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (email.isNotEmpty && email.contains('@')) {
                  Navigator.of(context).pop(email);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF87CEEB),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      );
      
      if (result == null) return;
      email = result;
    }

    setState(() {
      _isForgotPasswordLoading = true;
    });

    try {
      final response = await AuthForgotPasswordService.sendForgotPasswordRequest(
        email: email,
      );

      if (response['success'] == true) {
        // Show success dialog with more information
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Email Sent!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password reset link has been sent to:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A2C2A),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please check your email and follow the instructions to reset your password.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            content: Text(
              response['message'] ?? 'Failed to send password reset link. Please try again.',
              style: const TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog for network issues
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          content: Text(
            'Unable to send password reset link. Please check your internet connection and try again.',
            style: const TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isForgotPasswordLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });

    try {
      // Call the Google OAuth initialization API
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/auth/google/init'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Google OAuth init response status: ${response.statusCode}');
      print('Google OAuth init response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data']?['authUrl'] != null) {
          final authUrl = data['data']['authUrl'];
          print('Google OAuth URL: $authUrl');
          
          // Launch the Google OAuth URL - handle mobile differently
          bool launched = false;
          
          // try {
          //   // For mobile, try to launch in the same app first
          //   launched = await launchUrl(
          //     Uri.parse(authUrl),
          //     mode: LaunchMode.inAppWebView,
          //   );
          // } catch (e) {
          //   print('ChatService: InAppWebView failed, trying external: $e');
          //   // Fallback to external browser
          //   try {
          //     launched = await launchUrl(
          //       Uri.parse(authUrl),
          //       mode: LaunchMode.externalApplication,
          //     );
          //   } catch (e2) {
          //     print('ChatService: External launch also failed: $e2');
          //     // Try without specifying mode
          //     launched = await launchUrl(Uri.parse(authUrl));
          //   }
          // }
          
          if (launched) {
            // Wait a bit for the OAuth flow to complete
            await Future.delayed(const Duration(seconds: 3));
            
            // Now call the callback API to get the user data and token
            final callbackResponse = await http.get(
              Uri.parse('http://103.14.120.163:8081/api/auth/google/callback?test=true&format=json'),
              headers: {
                'Content-Type': 'application/json',
              },
            );

            print('Google OAuth callback response status: ${callbackResponse.statusCode}');
            print('Google OAuth callback response body: ${callbackResponse.body}');

            if (callbackResponse.statusCode == 200) {
              final callbackData = jsonDecode(callbackResponse.body);
              
              if (callbackData['success'] == true && 
                  callbackData['user'] != null && 
                  callbackData['token'] != null) {
                
                final user = callbackData['user'];
                final token = callbackData['token'];
                
                // Complete the user data with default values
                final completeUserData = {
                  'id': user['id'],
                  'email': user['email'],
                  'username': user['username'],
                  'fullName': user['fullName'],
                  'avatar': user['avatar'] ?? '',
                  'bio': '',
                  'website': '',
                  'location': '',
                  'religion': '',
                  'isPrivate': false,
                  'isEmailVerified': true,
                  'isVerified': false,
                  'followersCount': 0,
                  'followingCount': 0,
                  'postsCount': 0,
                  'reelsCount': 0,
                  'createdAt': DateTime.now().toIso8601String(),
                  'lastActive': DateTime.now().toIso8601String(),
                };
                
                // Navigate to religion selection screen with real user data
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/religion-selection',
                    arguments: {
                      'googleUserData': completeUserData,
                      'authToken': token,
                    },
                  );
                }
              } else {
                throw Exception('Invalid callback response: Missing user or token data');
              }
            } else {
              throw Exception('Google OAuth callback failed: ${callbackResponse.statusCode}');
            }
          } else {
            // If launching fails, show a helpful message and offer to continue with test data
            if (mounted) {
              final shouldContinue = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Google Login'),
                  content: const Text(
                    'Unable to launch Google login in browser. Would you like to continue with a test account for now?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Continue with Test'),
                    ),
                  ],
                ),
              );
              
              if (shouldContinue == true) {
                // Simulate the OAuth flow with test data
                await _handleTestGoogleLogin();
                return;
              }
            }
            throw Exception('Failed to launch Google OAuth');
          }
        } else {
          throw Exception('Invalid response from Google OAuth API');
        }
      } else {
        throw Exception('Google OAuth API request failed: ${response.statusCode}');
      }
      
    } catch (e) {
      setState(() {
        _error = 'Google sign-in error: $e';
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: ResponsiveUtils.getResponsivePadding(context, horizontal: 4.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // App Logo/Icon (Top Center) - Smaller icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/Peaceful Sunburst Icon Design.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                        
                       
                        
                      // Main Content Card - Semi-transparent white card with message screen styling
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1), // Match message screen opacity
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                spreadRadius: 3,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Title - Centered
                                    Center(
                                      child: Text(
                                        'Welcome Back to RGRAM',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'Poppins',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 4),
                                    
                                    // Tagline - Message screen style
                                    Center(
                                      child: Text(
                                        'Connecting Hearts, Spreading Harmony Worldwide',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                                          color: Colors.black.withOpacity(0.8),
                                          fontFamily: 'Poppins',
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Username or Email Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your username or email';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Username or Email',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 15,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Password Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Password',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 15,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                              color: Colors.black.withOpacity(0.7),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Log In Button - Message screen style
                                    Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.black,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.volunteer_activism, // Dove-like icon
                                                    color: Colors.black,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Log In',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Forgot Password Link - Message screen style
                                    Center(
                                      child: TextButton(
                                        onPressed: _isForgotPasswordLoading ? null : _forgotPassword,
                                        child: _isForgotPasswordLoading
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                ),
                                              )
                                            : Text(
                                                'Forgotten password?',
                                                style: TextStyle(
                                                  color: Colors.black.withOpacity(0.8),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    if (_error != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Sign Up Link - Message screen style
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/signup');
                                        },
                                        child: Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  "Don't have an account? ",
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  color: Colors.black.withOpacity(0.8),
                                                  fontSize: 14,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle test Google login when OAuth launch fails
  Future<void> _handleTestGoogleLogin() async {
    try {
      // Simulate the OAuth flow with test data
      await Future.delayed(const Duration(seconds: 2));
      
      // Call the callback API to get the user data and token
      final callbackResponse = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/auth/google/callback?test=true&format=json'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Test Google OAuth callback response status: ${callbackResponse.statusCode}');
      print('Test Google OAuth callback response body: ${callbackResponse.body}');

      if (callbackResponse.statusCode == 200) {
        final callbackData = jsonDecode(callbackResponse.body);
        
        if (callbackData['success'] == true && 
            callbackData['user'] != null && 
            callbackData['token'] != null) {
          
          final user = callbackData['user'];
          final token = callbackData['token'];
          
          // Complete the user data with default values
          final completeUserData = {
            'id': user['id'],
            'email': user['email'],
            'username': user['username'],
            'fullName': user['fullName'],
            'avatar': user['avatar'] ?? '',
            'bio': '',
            'website': '',
            'location': '',
            'religion': '',
            'isPrivate': false,
            'isEmailVerified': true,
            'isVerified': false,
            'followersCount': 0,
            'followingCount': 0,
            'postsCount': 0,
            'reelsCount': 0,
            'createdAt': DateTime.now().toIso8601String(),
            'lastActive': DateTime.now().toIso8601String(),
          };
          
          // Navigate to religion selection screen with real user data
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/religion-selection',
              arguments: {
                'googleUserData': completeUserData,
                'authToken': token,
              },
            );
          }
        } else {
          throw Exception('Invalid callback response: Missing user or token data');
        }
      } else {
        throw Exception('Google OAuth callback failed: ${callbackResponse.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test login failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
