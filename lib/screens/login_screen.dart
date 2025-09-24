import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
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
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        
                        // App Logo/Icon (Top Center) - Small square rounded icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/icons/Peaceful Sunburst Icon Design.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // RGRAM text below logo
                        const Text(
                          'RGRAM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A2C2A),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Main Content Card - Semi-transparent white card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08), // More transparent so background shows through
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    // Title
                                    const Text(
                                      'Welcome Back to RGRAM',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Tagline
                                    const Text(
                                      'Connecting Hearts, Spreading Harmony Worldwide',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontFamily: 'Poppins',
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Username or Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your username or email';
                                        }
                                        return null;
                                      },
                                      style: const TextStyle(
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Username or Email',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as other fields
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2), // Sky blue
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Password Field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                      style: const TextStyle(
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as other fields
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFF87CEEB), width: 2), // Sky blue
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Remember me checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: false,
                                          onChanged: (bool? value) {
                                            // Handle remember me logic here
                                          },
                                          activeColor: const Color(0xFF87CEEB), // Sky blue
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const Text(
                                          'Remember me',
                                          style: TextStyle(
                                            color: Color(0xFF4A2C2A),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Log In Button with Dove Icon
                                    Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF87CEEB), Color(0xFF4682B4)], // Sky blue gradient
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF87CEEB).withOpacity(0.3),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.volunteer_activism, // Dove-like icon
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Log In',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Forgot Password Link
                                    Center(
                                      child: TextButton(
                                        onPressed: _isForgotPasswordLoading ? null : _forgotPassword,
                                        child: _isForgotPasswordLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF87CEEB)),
                                                ),
                                              )
                                            : const Text(
                                                'Forgotten password?',
                                                style: TextStyle(
                                                  color: Color(0xFF000000), // Sky blue
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    if (_error != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
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
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Sign Up Link
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/signup');
                                      },
                                      child: RichText(
                                        text: const TextSpan(
                                          text: "Don't have an account? ",
                                          style: TextStyle(
                                            color: Color(0xFF4A2C2A),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Sign Up',
                                              style: TextStyle(
                                                color: Color(0xFF000000), // Sky blue
                                                fontWeight: FontWeight.w600,
                                               
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
