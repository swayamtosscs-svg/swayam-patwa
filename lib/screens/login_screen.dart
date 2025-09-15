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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeService.backgroundColor,
                  themeService.surfaceColor,
                  themeService.backgroundColor,
                ],
              ),
            ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // RGRAM Logo
                    Image.asset(
                      'assets/icons/RGRAM logo.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    const Text(
                      'RGRAM',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 22,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Login Type Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: themeService.surfaceColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isUsernameLogin = false;
                                  _error = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isUsernameLogin 
                                      ? AppTheme.primaryColor 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Email',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isUsernameLogin 
                                        ? Colors.white 
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isUsernameLogin = true;
                                  _error = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isUsernameLogin 
                                      ? AppTheme.primaryColor 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Username',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isUsernameLogin 
                                        ? Colors.white 
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email/Username Field
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
                      decoration: AppTheme.inputDecoration(
                        _isUsernameLogin ? 'Username' : 'Email address'
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      decoration: AppTheme.inputDecoration('Password'),
                    ),
                    const SizedBox(height: 8),
                    // Forgot Password Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isForgotPasswordLoading ? null : _forgotPassword,
                        child: _isForgotPasswordLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              )
                            : const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Or divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: AppTheme.secondaryButtonStyle.copyWith(
                          backgroundColor: MaterialStateProperty.all(Colors.white),
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : Image.asset(
                                'assets/images/googlelogo.png',
                                height: 24,
                              ),
                        label: Text(
                          _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                          style: const TextStyle(
                            color: Color(0xFF495C4A),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Signup prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'New to the app?',
                          style: TextStyle(color: Color(0xFF495C4A)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text('Sign up'),
                        ),
                      ],
                    ),
                  ],
                ),
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
