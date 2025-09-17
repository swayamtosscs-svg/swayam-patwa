import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../utils/font_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Navigate after animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() async {
    // Wait a bit more for the logo to be visible
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    // Load the user's religion and apply theme
    final themeService = Provider.of<ThemeService>(context, listen: false);
    await themeService.loadUserReligion();

    // The AuthWrapper will handle navigation based on authentication state
    // This method is no longer needed for navigation
    print('SplashScreen: Animation completed, AuthWrapper will handle routing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE1), // Logo box color from the image
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0EBE1), // Logo box color background
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // RGRAM Logo with Square Background (Instagram-style) - Same as Login Screen
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24), // Square with rounded corners (scaled up from login)
                          color: const Color(0xFFF0EBE1), // Light beige background
                          border: Border.all(
                            color: const Color(0xFFE0D5C7), // Subtle border
                            width: 2, // Scaled up from login
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30, // Scaled up from login
                              spreadRadius: 4, // Scaled up from login
                              offset: const Offset(0, 10), // Scaled up from login
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24), // Match container border radius
                          child: Image.asset(
                            'assets/icons/Peaceful Sunburst Icon Design.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Simple fallback
                              return Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(24)),
                                  color: Color(0xFFD29650), // Text color from logo
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.self_improvement,
                                      color: Colors.white,
                                      size: 80, // Scaled up
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'RGRAM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24, // Scaled up
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // App Name with system font branding
                      const Text(
                        'RGRAM',
                        style: TextStyle(
                          fontFamily: 'Roboto', // System font
                          color: Color(0xFFD29650), // Text color from logo
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Tagline with system font
                      const Text(
                        'Spiritual Connection Platform',
                        style: TextStyle(
                          fontFamily: 'Roboto', // System font
                          color: Color(0xFFD29650), // Text color from logo
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Simple loading indicator
                      const CircularProgressIndicator(
                        color: Color(0xFFD29650), // Text color from logo
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
