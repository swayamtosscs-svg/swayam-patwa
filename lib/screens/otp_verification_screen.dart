import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_theme.dart';
import '../services/otp_service.dart';
import '../services/theme_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose;
  final Map<String, dynamic> userData;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
    required this.userData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  String? _successMessage;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        
        if (_resendCountdown <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final response = await OtpService.verifyOtp(
        email: widget.email,
        code: _otpController.text.trim(),
        purpose: widget.purpose,
      );

      if (response.success) {
        setState(() {
          _successMessage = response.message;
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to the next screen based on purpose
        if (widget.purpose == 'signup') {
          // For signup, complete the registration process
          await _completeSignup();
        } else {
          // For other purposes, go back to previous screen
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error verifying OTP: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      final response = await OtpService.sendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (response.success) {
        setState(() {
          _successMessage = 'OTP sent successfully to ${widget.email}';
          _isResending = false;
        });

        // Start countdown again
        _startResendCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _error = response.message;
          _isResending = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error resending OTP: $e';
        _isResending = false;
      });
    }
  }

  Future<void> _completeSignup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Call the R-Gram signup API
      final response = await http.post(
        Uri.parse('https://api-rgram1.vercel.app/api/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.userData['email'],
          'password': widget.userData['password'],
          'fullName': widget.userData['name'],
          'username': widget.userData['username'],
          'religion': widget.userData['religion'],
          'isPrivate': widget.userData['isPrivate'] ?? false,
        }),
      );

      print('Signup response status: ${response.statusCode}');
      print('Signup response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Account created successfully, navigate to login page
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! Please log in to continue.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
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
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 24),
                        
                        // Title
                        const Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Text(
                          'We sent a verification code to',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Email
                        Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // OTP Input Field
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the OTP';
                            }
                            if (value.length != 6) {
                              return 'OTP must be 6 digits';
                            }
                            return null;
                          },
                          decoration: AppTheme.inputDecoration('Enter 6-digit OTP').copyWith(
                            counterText: '',
                            hintText: '000000',
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Success Message
                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.successColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Error Message
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: AppTheme.primaryButtonStyle.copyWith(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _verifyOtp,
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
                                    'Verify OTP',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Resend OTP Button
                        if (_resendCountdown > 0) ...[
                          Text(
                            'Resend OTP in ${_resendCountdown}s',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ] else ...[
                          TextButton(
                            onPressed: _isResending ? null : _resendOtp,
                            child: _isResending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                    ),
                                  )
                                : const Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Back Button
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Sign Up',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
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
