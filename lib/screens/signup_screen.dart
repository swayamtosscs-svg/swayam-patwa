import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../widgets/global_navigation_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  String? _selectedReligion;
  bool _isPrivate = false;
  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final List<Map<String, dynamic>> _religions = [
    {'name': 'hinduism', 'displayName': '🕉 Hinduism'},
    {'name': 'islam', 'displayName': '🌙 Islam'},
    {'name': 'christianity', 'displayName': '✝ Christianity'},
    {'name': 'jainism', 'displayName': '🕊 Jainism'},
    {'name': 'buddhism', 'displayName': '☸ Buddhism'},
    {'name': 'sikhism', 'displayName': '⚔ Sikhism'},
    {'name': 'judaism', 'displayName': '✡ Judaism'},
    {'name': 'other', 'displayName': '🕉 Other'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Auto-login method after successful signup
  Future<void> _autoLogin() async {
    try {
      print('Attempting auto-login after signup...');
      
      // Try login with email first
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      print('Auto-login response status: ${response.statusCode}');
      print('Auto-login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final token = data['data']?['token'];
          final user = data['data']?['user'];
          
          if (token != null && user != null) {
            // Auto-login successful
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.handleSuccessfulLogin(token, user);
            
            // Show success message
            final userName = user['fullName'] ?? user['username'] ?? 'User';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome to RGRAM, $userName!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Navigate to home screen with global navigation
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const GlobalNavigationWrapper(
                  child: HomeScreen(),
                  initialIndex: 0,
                )),
              );
            }
            return;
          }
        }
      }
      
      // If email login fails, try username login
      print('Email login failed, trying username login...');
      final usernameResponse = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      print('Username login response status: ${usernameResponse.statusCode}');
      print('Username login response body: ${usernameResponse.body}');
      
      if (usernameResponse.statusCode == 200) {
        final data = jsonDecode(usernameResponse.body);
        
        if (data['success'] == true) {
          final token = data['data']?['token'];
          final user = data['data']?['user'];
          
          if (token != null && user != null) {
            // Username login successful
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.handleSuccessfulLogin(token, user);
            
            // Show success message
            final userName = user['fullName'] ?? user['username'] ?? 'User';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome to RGRAM, $userName!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Navigate to home screen with global navigation
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const GlobalNavigationWrapper(
                  child: HomeScreen(),
                  initialIndex: 0,
                )),
              );
            }
            return;
          }
        }
      }
      
      // If both login attempts fail, redirect to login page
      print('Auto-login failed, redirecting to login page...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      
    } catch (e) {
      print('Auto-login error: $e');
      // If auto-login fails, redirect to login page
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
        _successMessage = null;
      });
      return;
    }

    if (_selectedReligion == null) {
      setState(() {
        _error = 'Please select a religion';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      // Call the R-Gram signup API directly
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'fullName': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'religion': _selectedReligion!,
          'isPrivate': _isPrivate,
        }),
      );

      print('Signup response status: ${response.statusCode}');
      print('Signup response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Account created successfully, show success message and auto-login
          setState(() {
            _successMessage = 'Successfully signed up! Welcome to RGRAM!';
            _isLoading = false;
          });
          
          if (mounted) {
            // Show success message on screen for 3 seconds before auto-login
            await Future.delayed(const Duration(seconds: 3));
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logging you in...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            await _autoLogin();
          }
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to create account';
            _isLoading = false;
          });
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            _error = errorData['message'] ?? 'Failed to create account: ${response.statusCode}';
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _error = 'Failed to create account: HTTP ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error creating account: $e';
        _isLoading = false;
      });
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
                 image: AssetImage('assets/images/Signup page bg.jpg'),
                 fit: BoxFit.cover,
               ),
             ),
             child: Column(
               children: [
                 Expanded(
                   child: SafeArea(
                     child: SingleChildScrollView(
                       child: Padding(
                         padding: ResponsiveUtils.getResponsivePadding(context, horizontal: 4.0),
                         child: Form(
                           key: _formKey,
                           child: Column(
                             children: [
                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.0)),
                        
                        // App Logo/Icon (Top Center) - Large icon like login screen
                        Image.asset(
                          'assets/images/Peaceful Sunburst Icon Design.png',
                          width: 250,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                        
                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 1.0)),
                        
                        // Main Content Card - Semi-transparent white card with message screen styling
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1), // Match message screen opacity
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
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
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    // Title - Centered
                                    Center(
                                      child: Text(
                                        'Welcome',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'Poppins',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 1.0)),
                                    
                                    // Tagline - Message screen style
                                    Center(
                                      child: Text(
                                        'Connecting Hearts, Spreading Harmony Worldwide',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
                                          color: Colors.black.withOpacity(0.8),
                                          fontFamily: 'Poppins',
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 5.0)),
                    
                                    // Full Name Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _nameController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Full name',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.5)),
                                    
                                    // Username Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _usernameController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a username';
                                          }
                                          if (value.length < 3) {
                                            return 'Username must be at least 3 characters';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Username',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.5)),
                                    
                                    // Email Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _emailController,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Enter a valid email';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Email address',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.5)),
                                    
                                    // Password Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
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
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Password',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.5)),
                                    
                                    // Confirm Password Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: !_isConfirmPasswordVisible,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          return null;
                                        },
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Confirm Password',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                              color: Colors.black.withOpacity(0.7),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.5)),
                                    
                                    // Bio Field - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _bioController,
                                        maxLines: 3,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Bio (optional)',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.5)),
                                    
                                    // Religion Selection - Message screen style
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedReligion,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Select Religion',
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
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
                                            borderSide: BorderSide(
                                              color: Colors.white.withOpacity(0.4),
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                        items: _religions.map((religion) {
                                          return DropdownMenuItem<String>(
                                            value: religion['name'],
                                            child: Text(religion['displayName']),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedReligion = newValue;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a religion';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Success Message Display
                                    if (_successMessage != null)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green[600],
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _successMessage!,
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Error Message Display
                                    if (_error != null)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error,
                                              color: Colors.red[600],
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: TextStyle(
                                                  color: Colors.red[700],
                                                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Sign Up Button - Message screen style
                                    Container(
                                      width: double.infinity,
                                      height: ResponsiveUtils.getResponsiveHeight(context, 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _signup,
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
                                                    size: 24,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Sign Up',
                                                    style: TextStyle(
                                                      color: Colors.black,
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
                                    
                                    // Sign Up Link - Message screen style
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(context, '/login');
                                        },
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "Already have an account? ",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Log in',
                                                style: TextStyle(
                                                  color: Colors.black.withOpacity(0.8),
                                                  fontSize: 16,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Add extra bottom padding to prevent overflow
                                    SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 2.0)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                         // Add extra bottom spacing
                         SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 3.0)),
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
        );
      },
    );
  }
} 