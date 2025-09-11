import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/theme_service.dart';
import '../services/otp_service.dart';
import 'package:provider/provider.dart';

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
  String? _selectedReligion;
  bool _isPrivate = false;

  final List<Map<String, dynamic>> _religions = [
    {'name': 'Hindu', 'displayName': '🕉 Hinduism'},
    {'name': 'Islam', 'displayName': '🌙 Islam'},
    {'name': 'Christianity', 'displayName': '✝ Christianity'},
    {'name': 'Jainism', 'displayName': '🕊 Jainism'},
    {'name': 'Buddhism', 'displayName': '☸ Buddhism'},
    {'name': 'Sikhism', 'displayName': '⚔ Sikhism'},
    {'name': 'Judaism', 'displayName': '✡ Judaism'},
    {'name': 'Other', 'displayName': '🕉 Other'},
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
      // First, send OTP for email verification
      final otpResponse = await OtpService.sendOtp(
        email: _emailController.text.trim(),
        purpose: 'signup',
      );

      if (otpResponse.success) {
        // OTP sent successfully, navigate to verification screen
        if (mounted) {
          final userData = {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'username': _usernameController.text.trim(),
            'password': _passwordController.text,
            'bio': _bioController.text.trim(),
            'religion': _selectedReligion!,
            'isPrivate': _isPrivate,
          };

          Navigator.pushNamed(
            context,
            '/otp-verification',
            arguments: {
              'email': _emailController.text.trim(),
              'purpose': 'signup',
              'userData': userData,
            },
          );
        }
      } else {
        setState(() {
          _error = otpResponse.message;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error sending verification code: $e';
      });
    } finally {
      setState(() {
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
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 22,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      decoration: AppTheme.inputDecoration('Full name'),
                    ),
                    const SizedBox(height: 16),
                    
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
                      decoration: AppTheme.inputDecoration('Username'),
                    ),
                    const SizedBox(height: 16),
                    
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
                      decoration: AppTheme.inputDecoration('Email address'),
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
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: AppTheme.inputDecoration('Password'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        return null;
                      },
                      decoration: AppTheme.inputDecoration('Confirm Password'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: AppTheme.inputDecoration('Bio (optional)'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Religion Selection
                    DropdownButtonFormField<String>(
                      value: _selectedReligion,
                      decoration: AppTheme.inputDecoration('Select Religion'),
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
                    const SizedBox(height: 16),
                    
                    // Privacy Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPrivate ? Icons.lock : Icons.public,
                            color: _isPrivate ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPrivate ? 'Private Account' : 'Public Account',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _isPrivate 
                                      ? 'Only approved followers can see your posts'
                                      : 'Anyone can see your posts and follow you',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPrivate,
                            onChanged: (bool value) {
                              setState(() {
                                _isPrivate = value;
                              });
                            },
                            activeColor: Colors.orange,
                            inactiveThumbColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _signup,
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
                                'Sign Up',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Login Link
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Already have an account? Log in',
                        style: TextStyle(color: AppTheme.primaryColor),
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
