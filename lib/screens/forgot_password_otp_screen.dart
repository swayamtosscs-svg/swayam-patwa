import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/otp_service.dart';
import '../utils/responsive_utils.dart';
import '../services/theme_service.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  const ForgotPasswordOTPScreen({super.key});

  @override
  State<ForgotPasswordOTPScreen> createState() => _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  String? _error;
  String? _successMessage;

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await OtpService.sendOtp(
        email: _emailController.text.trim(),
        purpose: 'password_reset',
      );

      if (result.success) {
        setState(() {
          _isOtpSent = true;
          _successMessage = result.message ?? 'OTP sent successfully to your email';
          _error = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _error = result.message ?? 'Failed to send OTP';
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTPAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
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
      // First verify OTP
      final verifyResult = await OtpService.verifyOtp(
        email: _emailController.text.trim(),
        code: _otpController.text.trim(),
        purpose: 'password_reset',
      );

      if (verifyResult.success) {
        // OTP verified, now reset password
        // You would call a reset password API here
        setState(() {
          _isOtpVerified = true;
          _successMessage = 'Password reset successfully! You can now login with your new password.';
          _error = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Navigate back to login after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      } else {
        setState(() {
          _error = verifyResult.message ?? 'Invalid OTP';
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
        _successMessage = null;
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
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.getResponsivePadding(context, horizontal: 4.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 
                              MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // App Logo/Icon
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
                          
                          const SizedBox(height: 20),
                          
                          // Main Content Card
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
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
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Title
                                        Center(
                                          child: Text(
                                            'Reset Password with OTP',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Description
                                        Center(
                                          child: Text(
                                            'Enter your email to receive an OTP for password reset',
                                            style: TextStyle(
                                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                                              color: Colors.black.withOpacity(0.8),
                                              fontFamily: 'Poppins',
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Email Field
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
                                            keyboardType: TextInputType.emailAddress,
                                            enabled: !_isOtpSent,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your email address';
                                              }
                                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                                return 'Please enter a valid email address';
                                              }
                                              return null;
                                            },
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: 'Poppins',
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your email address',
                                              hintStyle: TextStyle(
                                                color: Colors.black.withOpacity(0.7),
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                              ),
                                              prefixIcon: Icon(
                                                Icons.email_outlined,
                                                color: Colors.black.withOpacity(0.7),
                                                size: 20,
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
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                        // OTP Field (shown after OTP is sent)
                                        if (_isOtpSent) ...[
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
                                              controller: _otpController,
                                              keyboardType: TextInputType.number,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter the OTP';
                                                }
                                                if (value.length != 6) {
                                                  return 'OTP must be 6 digits';
                                                }
                                                return null;
                                              },
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Enter 6-digit OTP',
                                                hintStyle: TextStyle(
                                                  color: Colors.black.withOpacity(0.7),
                                                  fontSize: 15,
                                                  fontFamily: 'Poppins',
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.security,
                                                  color: Colors.black.withOpacity(0.7),
                                                  size: 20,
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
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // New Password Field
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
                                              controller: _newPasswordController,
                                              obscureText: true,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter new password';
                                                }
                                                if (value.length < 6) {
                                                  return 'Password must be at least 6 characters';
                                                }
                                                return null;
                                              },
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Enter new password',
                                                hintStyle: TextStyle(
                                                  color: Colors.black.withOpacity(0.7),
                                                  fontSize: 15,
                                                  fontFamily: 'Poppins',
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.lock_outline,
                                                  color: Colors.black.withOpacity(0.7),
                                                  size: 20,
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
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Confirm Password Field
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
                                              controller: _confirmPasswordController,
                                              obscureText: true,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please confirm new password';
                                                }
                                                if (value != _newPasswordController.text) {
                                                  return 'Passwords do not match';
                                                }
                                                return null;
                                              },
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Confirm new password',
                                                hintStyle: TextStyle(
                                                  color: Colors.black.withOpacity(0.7),
                                                  fontSize: 15,
                                                  fontFamily: 'Poppins',
                                                ),
                                                prefixIcon: Icon(
                                                  Icons.lock_outline,
                                                  color: Colors.black.withOpacity(0.7),
                                                  size: 20,
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
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        
                                        // Send OTP Button
                                        if (!_isOtpSent) ...[
                                          Container(
                                            width: double.infinity,
                                            height: 48,
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
                                              onPressed: _isLoading ? null : _sendOTP,
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
                                                          Icons.email_outlined,
                                                          color: Colors.black,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Send OTP',
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
                                        ],
                                        
                                        // Reset Password Button (shown after OTP is sent)
                                        if (_isOtpSent && !_isOtpVerified) ...[
                                          Container(
                                            width: double.infinity,
                                            height: 48,
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
                                              onPressed: _isLoading ? null : _verifyOTPAndResetPassword,
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
                                                          Icons.security,
                                                          color: Colors.black,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Reset Password',
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
                                        ],
                                        
                                        // Error Message
                                        if (_error != null) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _error!,
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.w500,
                                                      fontFamily: 'Poppins',
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        
                                        // Success Message
                                        if (_successMessage != null) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.green.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _successMessage!,
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w500,
                                                      fontFamily: 'Poppins',
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        
                                        const SizedBox(height: 24),
                                        
                                        // Back to Login Link
                                        Center(
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.arrow_back,
                                                  color: Colors.black,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Back to Login',
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
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

