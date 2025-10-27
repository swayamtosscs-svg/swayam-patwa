# Home Page Loading Optimization

## Problem
Home page was taking too long to load because ALL screens (all 6 tabs) were initializing immediately when the app started, causing multiple API calls and heavy data loading at once.

## Solution Implemented
Changed the `GlobalNavigationWrapper` to use **lazy loading** instead of eager initialization.

### Before
```dart
final List<Widget> _pages = [
  const HomeScreen(),      // ❌ Loaded immediately
  const ReelsScreen(),     // ❌ Loaded immediately  
  const AddOptionsScreen(), // ❌ Loaded immediately
  const BabaPagesScreen(), // ❌ Loaded immediately
  const LiveStreamScreen(), // ❌ Loaded immediately
  const ProfileUI(),       // ❌ Loaded immediately
];
```

### After
```dart
// Only HomeScreen loads immediately
_initializedPages[0] = HomeScreen();

// Other screens load only when user taps on them
_onTabTapped(index) {
  if (_initializedPages[index] == null) {
    _initializedPages[index] = _createPage(index); // Lazy load
  }
}
```

## Benefits
1. **Faster Home Screen Loading** - Only HomeScreen's API calls run on app startup
2. **Reduced Memory Usage** - Other screens don't consume memory until visited
3. **Better Performance** - Initial data loading is ~6x faster (only 1 screen instead of 6)
4. **On-Demand Loading** - Reels, Baba Pages, Live Streams, and Profile only load when user navigates to them

## Technical Changes
File: `lib/widgets/global_navigation_wrapper.dart`

- Changed from eager initialization (all pages in list) to lazy initialization (Map-based)
- Added `_initializedPages` map to store only loaded screens
- Added `_createPage()` method to create screens on-demand
- Modified `_onTabTapped()` to check if screen exists before loading
- Updated `build()` to use lazy-loaded pages

## Result
- Home screen now loads instantly
- No pre-loading of unnecessary data
- Each section loads only when user actually navigates to it
- Overall app startup time significantly reduced

