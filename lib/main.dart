import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/live_stream_provider.dart';
import 'services/theme_service.dart';
import 'models/baba_page_model.dart';
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
import 'screens/video_test_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/host_page.dart';
import 'screens/viewer_page.dart';
import 'screens/admin_login_screen.dart';
import 'screens/super_admin_create_screen.dart';
import 'screens/admin_create_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/verification_request_screen.dart';
import 'screens/admin_verification_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/create_live_stream_screen.dart';
import 'screens/live_stream_viewer_screen.dart';
import 'screens/baba_page_detail_screen.dart';
import 'screens/baba_profile_ui_demo.dart';
import 'screens/baba_pages_screen.dart';
import 'screens/discover_users_screen.dart';
import 'widgets/global_navigation_wrapper.dart';

// import 'services/custom_http_client.dart';
// import 'services/memory_optimization_service.dart';
// Cloudinary dependency removed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize media_kit with error handling
  try {
    MediaKit.ensureInitialized();
    print('MediaKit initialized successfully');
  } catch (e) {
    print('MediaKit initialization failed: $e');
    // Continue app initialization even if MediaKit fails
  }
  
  // Memory optimization: Set image cache size
  try {
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  } catch (e) {
    print('Image cache configuration failed: $e');
  }
  
  runApp(const DivineConnectApp());
}

class DivineConnectApp extends StatelessWidget {
  const DivineConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => LiveStreamProvider()),
        ChangeNotifierProvider(create: (context) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'RGRAM - Spiritual Connection Platform',
            theme: themeService.currentTheme,
            debugShowCheckedModeBanner: false,
            debugShowMaterialGrid: false,
            showSemanticsDebugger: false,
            home: const AuthWrapper(), // Use AuthWrapper as home instead of routes
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/interests': (context) => const InterestSelectionScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const GlobalNavigationWrapper(
                child: HomeScreen(),
                initialIndex: 0,
              ),
              '/dashboard': (context) => const GlobalNavigationWrapper(
                child: HomeScreen(),
                initialIndex: 0,
              ),
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
              '/video-test': (context) => const VideoTestScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/host-live': (context) => const HostPage(),
              '/viewer-live': (context) => const ViewerPage(),
              '/admin/login': (context) => const AdminLoginScreen(),
              '/admin/create-super-admin': (context) => const SuperAdminCreateScreen(),
              '/admin/create-admin': (context) => const AdminCreateScreen(),
              '/admin/dashboard': (context) => const AdminDashboardScreen(),
              '/admin/verification': (context) => const AdminVerificationScreen(),
              '/verification-request': (context) => const VerificationRequestScreen(),
              '/reels': (context) => const ReelsScreen(),
              '/create-live-stream': (context) => const CreateLiveStreamScreen(),
              '/live-stream-viewer': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
                return LiveStreamViewerScreen(
                  room: args?['room'],
                  authToken: args?['authToken'],
                );
              },
              '/baba-page-detail': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
                
                // Create a BabaPage object from the arguments
                final babaPage = BabaPage(
                  id: args?['babaPageId'] ?? '',
                  name: args?['babaPageName'] ?? 'Baba Ji',
                  description: args?['description'] ?? '',
                  avatar: args?['avatar'] ?? '',
                  coverImage: args?['coverImage'] ?? '',
                  location: args?['location'] ?? '',
                  religion: args?['religion'] ?? '',
                  website: args?['website'] ?? '',
                  creatorId: args?['creatorId'] ?? '',
                  followersCount: args?['followersCount'] ?? 0,
                  postsCount: args?['postsCount'] ?? 0,
                  videosCount: args?['videosCount'] ?? 0,
                  storiesCount: args?['storiesCount'] ?? 0,
                  isActive: args?['isActive'] ?? true,
                  isFollowing: args?['isFollowing'] ?? false,
                  createdAt: args?['createdAt'] != null 
                      ? DateTime.parse(args!['createdAt']) 
                      : DateTime.now(),
                  updatedAt: args?['updatedAt'] != null 
                      ? DateTime.parse(args!['updatedAt']) 
                      : DateTime.now(),
                );
                
                // Validate that we have at least the basic required data
                if (babaPage.id.isEmpty) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Error'),
                      backgroundColor: Colors.red,
                    ),
                    body: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Baba Ji Profile Not Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The Baba Ji profile you are looking for could not be found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Navigate to BabaProfileUiDemoScreen to show Posts/Videos/Stories/Events tabs
                return BabaProfileUiDemoScreen(
                  babaPage: babaPage,
                );
              },
              '/discover-users': (context) => const DiscoverUsersScreen(),
              '/baba-pages': (context) => const GlobalNavigationWrapper(
                child: BabaPagesScreen(),
                initialIndex: 3,
              ),
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
    try {
      // Clear image caches to free memory
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Force garbage collection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // This will trigger garbage collection on the next frame
      });
    } catch (e) {
      print('Error clearing memory caches: $e');
    }
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
          print('AuthWrapper: User is authenticated, showing home screen with global navigation');
          return const GlobalNavigationWrapper(
            child: HomeScreen(),
            initialIndex: 0,
          );
        } else {
          print('AuthWrapper: User not authenticated, showing login screen');
          // Show login screen when user is not authenticated (first time or after logout)
          return const LoginScreen();
        }
      },
    );
  }
}