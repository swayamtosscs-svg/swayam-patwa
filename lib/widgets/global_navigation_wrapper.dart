import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../screens/home_screen.dart';
import '../screens/live_stream_screen.dart';
import '../screens/reels_screen.dart';
import '../screens/add_options_screen.dart';
import '../screens/baba_pages_screen.dart';
import '../profile_ui.dart';

class GlobalNavigationWrapper extends StatefulWidget {
  final Widget child;
  final int? initialIndex;

  const GlobalNavigationWrapper({
    super.key,
    required this.child,
    this.initialIndex,
  });

  @override
  State<GlobalNavigationWrapper> createState() => _GlobalNavigationWrapperState();
}

class _GlobalNavigationWrapperState extends State<GlobalNavigationWrapper> {
  int _currentIndex = 0;
  // Lazy load pages - only create them when needed
  final Map<int, Widget> _initializedPages = {};
  
  // Store initial index to load only that screen first
  int get _initialScreenIndex => widget.initialIndex ?? 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialScreenIndex;
    
    // Only initialize the initial screen immediately
    if (_initializedPages[_initialScreenIndex] == null) {
      _initializedPages[_initialScreenIndex] = _createPage(_initialScreenIndex);
      print('GlobalNavigation: Initialized only screen $_initialScreenIndex');
    }
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ReelsScreen();
      case 2:
        return const AddOptionsScreen();
      case 3:
        return const BabaPagesScreen();
      case 4:
        return const LiveStreamScreen();
      case 5:
        return const ProfileUI();
      default:
        return const HomeScreen();
    }
  }

  void _onTabTapped(int index) {
    // Only initialize the page if it hasn't been initialized yet
    if (_initializedPages[index] == null) {
      print('GlobalNavigation: Lazy loading screen $index');
      _initializedPages[index] = _createPage(index);
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(6, (index) {
              // Return the initialized page, or empty container if not loaded yet
              return _initializedPages[index] ?? Container();
            }),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: themeService.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home,
                      label: 'Home',
                      index: 0,
                      isSelected: _currentIndex == 0,
                    ),
                    _buildNavItem(
                      icon: Icons.video_library,
                      label: 'Reels',
                      index: 1,
                      isSelected: _currentIndex == 1,
                    ),
                    _buildNavItem(
                      icon: Icons.add,
                      label: 'Add',
                      index: 2,
                      isSelected: _currentIndex == 2,
                    ),
                    _buildNavItem(
                      icon: Icons.self_improvement,
                      label: 'Baba Ji',
                      index: 3,
                      isSelected: _currentIndex == 3,
                    ),
                    _buildNavItem(
                      icon: Icons.live_tv,
                      label: 'Live Dars...',
                      index: 4,
                      isSelected: _currentIndex == 4,
                    ),
                    _buildNavItem(
                      icon: Icons.person,
                      label: 'Account',
                      index: 5,
                      isSelected: _currentIndex == 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: () => _onTabTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected 
                    ? themeService.primaryColor 
                    : themeService.onSurfaceColor.withOpacity(0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                      ? themeService.primaryColor 
                      : themeService.onSurfaceColor.withOpacity(0.6),
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
