import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/interest_selection_screen.dart';
import 'screens/video_feed_screen.dart';
import 'screens/instagram_feed_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reel_upload_screen.dart';
import 'screens/demo_media_screen.dart';
import 'screens/google_signin_screen.dart';
import 'screens/religion_selection_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/otp_verification_screen.dart';

// import 'services/custom_http_client.dart';
// import 'services/memory_optimization_service.dart';
// Cloudinary dependency removed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Memory optimization: Set image cache size
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  
  runApp(const DivineConnectApp());
}

class DivineConnectApp extends StatelessWidget {
  const DivineConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'RGRAM - Spiritual Connection Platform',
            theme: themeService.currentTheme,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(), // Use AuthWrapper as home instead of routes
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/interests': (context) => const InterestSelectionScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/dashboard': (context) => const HomeScreen(),
              '/video-feed': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as String?;
                return VideoFeedScreen(selectedReligion: args ?? 'Spiritual');
              },
              '/instagram-feed': (context) => const InstagramFeedScreen(),
              '/reel-upload': (context) => const ReelUploadScreen(),
              '/demo-media': (context) => const DemoMediaScreen(),
              '/google-signin': (context) => const GoogleSignInScreen(),
              '/religion-selection': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
                return ReligionSelectionScreen(
                  googleUserData: args?['googleUserData'] ?? {},
                  authToken: args?['authToken'] ?? '',
                );
              },
              '/otp-verification': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
                return OtpVerificationScreen(
                  email: args?['email'] ?? '',
                  purpose: args?['purpose'] ?? 'signup',
                  userData: args?['userData'] ?? {},
                );
              },
              '/notifications': (context) => const NotificationsScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Memory optimization: Clear caches when app goes to background
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _clearMemoryCaches();
        break;
      case AppLifecycleState.resumed:
        // Optionally restore caches when app resumes
        break;
      default:
        break;
    }
  }

  void _clearMemoryCaches() {
    // Clear image caches to free memory
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Force garbage collection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will trigger garbage collection on the next frame
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Debug logging
        print('AuthWrapper: isLoading=${authProvider.isLoading}, isAuthenticated=${authProvider.isAuthenticated}, authToken=${authProvider.authToken != null ? "exists" : "null"}');
        
        if (authProvider.isLoading) {
          // Show splash screen while loading
          return const SplashScreen();
        }

        // Check if user is authenticated
        if (authProvider.isAuthenticated && authProvider.authToken != null) {
          print('AuthWrapper: User is authenticated, showing home screen');
          return const HomeScreen();
        } else {
          print('AuthWrapper: User not authenticated, showing signup screen as requested');
          // Show signup screen instead of login when user is not authenticated
          return const SignupScreen();
        }
      },
    );
  }
}
