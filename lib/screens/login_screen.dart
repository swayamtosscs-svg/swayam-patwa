import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
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
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isForgotPasswordLoading = true;
    });

    try {
      final response = await AuthForgotPasswordService.sendForgotPasswordRequest(
        email: _emailController.text.trim(),
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password reset link sent successfully'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send password reset link'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE1), // Custom background color
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // RGram Logo with Neumorphic Design
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F5DC), // Light beige background
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: -5,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // RGRAM Logo with Square Background (Instagram-style)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), // Square with rounded corners
                          color: const Color(0xFFF0EBE1), // Light beige background
                          border: Border.all(
                            color: const Color(0xFFE0D5C7), // Subtle border
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12), // Match container border radius
                          child: Image.asset(
                            'assets/icons/Peaceful Sunburst Icon Design.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Username/Email Field (Instagram style)
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _isUsernameLogin 
                          ? 'Please enter your username' 
                          : 'Please enter your email';
                    }
                    if (!_isUsernameLogin && !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    if (_isUsernameLogin && value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                  style: const TextStyle(
                    color: Color(0xFF4A2C2A), // Deep Brown
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: _isUsernameLogin 
                        ? 'Username' 
                        : 'Username, email address or mobile number',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8), // Light background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2E5D4F), width: 1), // Deep Green
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Password Field (Instagram style)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  style: const TextStyle(
                    color: Color(0xFF4A2C2A), // Deep Brown
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8), // Light background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2E5D4F), width: 1), // Deep Green
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Login Button (same style as Create Account)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _login,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1), // Muted Gold border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF4A2C2A),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log in',
                            style: TextStyle(
                              color: Color(0xFF4A2C2A), // Deep Brown
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Forgot Password Link (Instagram style)
                Center(
                  child: TextButton(
                    onPressed: _isForgotPasswordLoading ? null : _forgotPassword,
                    child: _isForgotPasswordLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Forgotten password?',
                            style: TextStyle(
                              color: Color(0xFFD4AF37), // Muted Gold
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                ),
                
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 40),
                
                // Create New Account Button (Instagram style)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1), // Muted Gold border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Create new account',
                      style: TextStyle(
                        color: Color(0xFF4A2C2A), // Deep Brown
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // TOSS SOLUTIONS Logo Only
                Center(
                  child: Image.asset(
                    'assets/images/Tosslogo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
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
