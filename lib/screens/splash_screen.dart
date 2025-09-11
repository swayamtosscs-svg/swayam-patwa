import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_loader.dart';
import 'login_screen.dart';
import 'home_screen.dart';

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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final religion = themeService.userReligion.toLowerCase();
        List<Color> gradientColors;
        
        switch (religion) {
          case 'hinduism':
          case 'hindu':
            gradientColors = [ThemeService.hinduSaffronOrange, ThemeService.hinduWarmOrange, ThemeService.hinduWhite, ThemeService.hinduMaroon];
            break;
          case 'islam':
          case 'muslim':
            gradientColors = [ThemeService.islamDarkGreen, ThemeService.islamFreshGreen, ThemeService.islamCream, ThemeService.islamWhite];
            break;
          case 'christianity':
          case 'christian':
            gradientColors = [ThemeService.christianDeepBlue, ThemeService.christianLightBlue, ThemeService.christianWhite, ThemeService.christianGold];
            break;
          case 'jainism':
          case 'jain':
            gradientColors = [ThemeService.jainDeepRed, ThemeService.jainSaffron, ThemeService.jainWhite, ThemeService.jainDeepRed];
            break;
          case 'buddhism':
          case 'buddhist':
            gradientColors = [ThemeService.buddhistMonkOrange, ThemeService.buddhistGoldenYellow, ThemeService.buddhistPaleGold, ThemeService.buddhistWhite];
            break;
          case 'sikhism':
          case 'sikh':
            gradientColors = [ThemeService.sikhSaffron, ThemeService.sikhDeepOrange, ThemeService.sikhWhite, ThemeService.sikhNavyBlue];
            break;
          case 'judaism':
          case 'jewish':
            gradientColors = [ThemeService.jewishDeepBlue, ThemeService.jewishLightBlue, ThemeService.jewishSilver, ThemeService.jewishWhite];
            break;
          case 'bahai':
          case 'baha\'i':
            gradientColors = [ThemeService.bahaiWarmOrange, ThemeService.bahaiViolet, ThemeService.bahaiJadeGreen, ThemeService.bahaiWhite];
            break;
          case 'taoism':
          case 'daoism':
            gradientColors = [ThemeService.taoBlack, ThemeService.taoCharcoal, ThemeService.taoJadeGreen, ThemeService.taoOffWhite];
            break;
          case 'indigenous':
          case 'earth_spiritual':
            gradientColors = [ThemeService.indigenousEarthBrown, ThemeService.indigenousClayBrown, ThemeService.indigenousForestGreen, ThemeService.indigenousWhite];
            break;
          default:
            gradientColors = [const Color(0xFF8B4513), const Color(0xFFD2691E), const Color(0xFFF5DEB3), const Color(0xFFD2691E)];
        }
        
        return Scaffold(
          backgroundColor: gradientColors.first,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
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
                      // Religious decorative elements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildReligiousIcon(Icons.self_improvement, themeService),
                          const SizedBox(width: 20),
                          _buildReligiousIcon(Icons.favorite, themeService),
                          const SizedBox(width: 20),
                          _buildReligiousIcon(Icons.star, themeService),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // RGRAM Logo with enhanced religious styling
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppTheme.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: AppTheme.goldColor.withOpacity(0.3),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/RGRAM logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Enhanced fallback with religious symbols
                                return Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: AppTheme.primaryGradient,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.self_improvement,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'RGRAM',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // App Name with religious styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.buttonGradient,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          'RGRAM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Enhanced tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.goldColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Spiritual Connection Platform',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Enhanced loading indicator
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: _getLoadingIndicatorColor(religion).withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: CircularProgressIndicator(
                              color: _getLoadingIndicatorColor(religion),
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Connecting to Divine...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
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
      },
    );
  }
  
  Color _getLoadingIndicatorColor(String religion) {
    switch (religion) {
      case 'hinduism':
      case 'hindu':
        return ThemeService.hinduWarmOrange;
      case 'islam':
      case 'muslim':
        return ThemeService.islamFreshGreen;
      case 'christianity':
      case 'christian':
        return ThemeService.christianGold;
      case 'jainism':
      case 'jain':
        return ThemeService.jainSaffron;
      case 'buddhism':
      case 'buddhist':
        return ThemeService.buddhistPaleGold;
      default:
        return const Color(0xFFD2691E);
    }
  }

  Widget _buildReligiousIcon(IconData icon, ThemeService themeService) {
    final religion = themeService.userReligion.toLowerCase();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: _getLoadingIndicatorColor(religion).withOpacity(0.6),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        color: _getLoadingIndicatorColor(religion),
        size: 24,
      ),
    );
  }
}
