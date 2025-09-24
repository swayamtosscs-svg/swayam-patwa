import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../utils/app_theme.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';

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
            
            // Navigate to home screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
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
            
            // Navigate to home screen
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
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
      });
      return;
    }

    if (_selectedReligion == null) {
      setState(() {
        _error = 'Please select a religion';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
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
            _successMessage = 'User successfully registered!';
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created! Logging you in...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // Wait a moment to show success message, then auto-login
            await Future.delayed(const Duration(seconds: 1));
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
                                      'Welcome to RGRAM',
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
                    
                                    // Full Name Field
                                    TextFormField(
                                      controller: _nameController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                      style: const TextStyle(
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Full name',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as in image
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
                                    
                                    // Username Field
                                    TextFormField(
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
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Username',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as in image
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
                                    
                                    // Email Field
                                    TextFormField(
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
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Email address',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as in image
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
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
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
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as in image
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
                                    
                                    // Confirm Password Field
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: !_isConfirmPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        return null;
                                      },
                                      style: const TextStyle(
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Confirm Password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9), // Same opacity as in image
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
                                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                            color: Colors.grey[600],
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Bio Field
                                    TextFormField(
                                      controller: _bioController,
                                      maxLines: 3,
                                      style: const TextStyle(
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Bio (optional)',
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
                                    
                                    // Religion Selection
                                    DropdownButtonFormField<String>(
                                      value: _selectedReligion,
                                      style: const TextStyle(
                                        color: Color(0xFF4A2C2A), // Dark brown
                                        fontSize: 16,
                                        fontFamily: 'Poppins',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Select Religion',
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
                                    const SizedBox(height: 20),
                                    
                                    // Remember me checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              _agreeToTerms = value ?? false;
                                            });
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
                                                    'Sign Up',
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
                                    
                                    // Sign Up Link
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(context, '/login');
                                      },
                                      child: RichText(
                                        text: const TextSpan(
                                          text: "Already have an account? ",
                                          style: TextStyle(
                                            color: Color(0xFF4A2C2A),
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Log in',
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
}
