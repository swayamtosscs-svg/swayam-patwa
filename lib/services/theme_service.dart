import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/font_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _religionKey = 'user_religion';
  
  String _userReligion = 'hinduism'; // Default religion
  ThemeData _currentTheme = _getHinduTheme();
  
  String get userReligion => _userReligion;
  ThemeData get currentTheme => _currentTheme;
  
  // 🕉 Hinduism Colors
  static const Color hinduSaffronOrange = Color(0xFFFF6F00);
  static const Color hinduWarmOrange = Color(0xFFFF9A3C);
  static const Color hinduMaroon = Color(0xFF7A1535);
  static const Color hinduWhite = Color(0xFFFFFFFF);
  
  // 🌙 Islam Colors
  static const Color islamDarkGreen = Color(0xFF0F7D3B);
  static const Color islamFreshGreen = Color(0xFF3AB36F);
  static const Color islamCream = Color(0xFFF7F2E6);
  static const Color islamWhite = Color(0xFFFFFFFF);
  
  // ✝ Christianity Colors
  static const Color christianDeepBlue = Color(0xFF0B3D91);
  static const Color christianLightBlue = Color(0xFF2B60D8);
  static const Color christianGold = Color(0xFFC49A2A);
  static const Color christianWhite = Color(0xFFFFFFFF);
  
  // ☸ Buddhism Colors
  static const Color buddhistMonkOrange = Color(0xFFE85800);
  static const Color buddhistGoldenYellow = Color(0xFFF6A12B);
  static const Color buddhistPaleGold = Color(0xFFFFD966);
  static const Color buddhistWhite = Color(0xFFFFFFFF);
  
  // ⚔ Sikhism Colors
  static const Color sikhSaffron = Color(0xFFFF9933);
  static const Color sikhDeepOrange = Color(0xFFFF6A00);
  static const Color sikhNavyBlue = Color(0xFF0B2F5A);
  static const Color sikhWhite = Color(0xFFFFFFFF);
  
  // ✡ Judaism Colors
  static const Color jewishDeepBlue = Color(0xFF0A3D91);
  static const Color jewishLightBlue = Color(0xFF3A6DD8);
  static const Color jewishSilver = Color(0xFFC7D6E8);
  static const Color jewishWhite = Color(0xFFFFFFFF);
  
  // 🌈 Bahá'í Colors
  static const Color bahaiWarmOrange = Color(0xFFFFB347);
  static const Color bahaiViolet = Color(0xFF9B59B6);
  static const Color bahaiJadeGreen = Color(0xFF4DAF50);
  static const Color bahaiWhite = Color(0xFFFFFFFF);
  
  // 🕊 Jainism Colors
  static const Color jainDeepRed = Color(0xFFA41E2B);
  static const Color jainSaffron = Color(0xFFF39C12);
  static const Color jainWhite = Color(0xFFFFFFFF);
  
  // ☯ Taoism/Daoism Colors
  static const Color taoBlack = Color(0xFF0C0C0C);
  static const Color taoCharcoal = Color(0xFF2F2B2B);
  static const Color taoGold = Color(0xFFC5A600);
  static const Color taoJadeGreen = Color(0xFF2F9A76);
  static const Color taoOffWhite = Color(0xFFF2EDE6);
  
  // 🌍 Indigenous/Earth Spiritual Colors
  static const Color indigenousEarthBrown = Color(0xFF4E342E);
  static const Color indigenousClayBrown = Color(0xFF7B5E57);
  static const Color indigenousSandstone = Color(0xFFB08968);
  static const Color indigenousForestGreen = Color(0xFF2E7D32);
  static const Color indigenousWhite = Color(0xFFFFFFFF);
  
  // Default Colors (current beige/brown theme)
  static const Color defaultPrimary = Color(0xFF8B4513);
  static const Color defaultSecondary = Color(0xFFF5DEB3);
  static const Color defaultAccent = Color(0xFFD2691E);
  
  ThemeService() {
    loadUserReligion();
  }
  
  Future<void> loadUserReligion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userReligion = prefs.getString(_religionKey) ?? 'hinduism';
      _updateTheme();
    } catch (e) {
      print('ThemeService: Error loading user religion: $e');
    }
  }
  
  Future<void> setUserReligion(String religion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_religionKey, religion);
      _userReligion = religion;
      _updateTheme();
      notifyListeners();
    } catch (e) {
      print('ThemeService: Error saving user religion: $e');
    }
  }
  
  void _updateTheme() {
    switch (_userReligion.toLowerCase()) {
      case 'hinduism':
      case 'hindu':
        _currentTheme = _getHinduTheme();
        break;
      case 'islam':
      case 'muslim':
        _currentTheme = _getIslamTheme();
        break;
      case 'christianity':
      case 'christian':
        _currentTheme = _getChristianTheme();
        break;
      case 'jainism':
      case 'jain':
        _currentTheme = _getJainismTheme();
        break;
      case 'buddhism':
      case 'buddhist':
        _currentTheme = _getBuddhismTheme();
        break;
      case 'sikhism':
      case 'sikh':
        _currentTheme = _getSikhismTheme();
        break;
      case 'judaism':
      case 'jewish':
        _currentTheme = _getJudaismTheme();
        break;
      case 'bahai':
      case 'baha\'i':
        _currentTheme = _getBahaiTheme();
        break;
      case 'taoism':
      case 'daoism':
        _currentTheme = _getTaoismTheme();
        break;
      case 'indigenous':
      case 'earth_spiritual':
        _currentTheme = _getIndigenousTheme();
        break;
      default:
        _currentTheme = _getDefaultTheme();
        break;
    }
  }
  
  static ThemeData _getHinduTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: hinduSaffronOrange,
        secondary: hinduWarmOrange,
        surface: hinduWhite,
        background: hinduWhite,
        onPrimary: hinduWhite,
        onSecondary: hinduMaroon,
        onSurface: hinduMaroon,
        onBackground: hinduMaroon,
        error: hinduMaroon,
        onError: hinduWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: hinduSaffronOrange,
        foregroundColor: hinduWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: hinduWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hinduSaffronOrange,
          foregroundColor: hinduWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: hinduSaffronOrange,
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: hinduWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hinduWarmOrange, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hinduWarmOrange, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hinduSaffronOrange, width: 2),
        ),
        labelStyle: const TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: hinduWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: hinduSaffronOrange.withOpacity(0.3),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: hinduWarmOrange,
        selectedItemColor: hinduSaffronOrange,
        unselectedItemColor: hinduWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
        ),
        bodyMedium: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
        ),
        bodySmall: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
        ),
        labelLarge: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: hinduSaffronOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: hinduSaffronOrange,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: hinduSaffronOrange,
        foregroundColor: hinduWhite,
        elevation: 6,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: hinduWarmOrange,
        thickness: 1,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: hinduSaffronOrange,
        linearTrackColor: hinduWarmOrange,
        circularTrackColor: hinduWarmOrange,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return hinduSaffronOrange;
          }
          return hinduWhite;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return hinduWarmOrange;
          }
          return Colors.grey;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return hinduSaffronOrange;
          }
          return hinduWhite;
        }),
        checkColor: MaterialStateProperty.all(hinduWhite),
        side: const BorderSide(color: hinduWarmOrange, width: 2),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return hinduSaffronOrange;
          }
          return hinduWarmOrange;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: hinduSaffronOrange,
        inactiveTrackColor: hinduWarmOrange,
        thumbColor: hinduSaffronOrange,
        overlayColor: hinduSaffronOrange.withOpacity(0.2),
      ),
    );
  }
  
  static ThemeData _getIslamTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: islamDarkGreen,
        secondary: islamFreshGreen,
        surface: islamCream,
        background: islamCream,
        onPrimary: islamWhite,
        onSecondary: islamDarkGreen,
        onSurface: islamDarkGreen,
        onBackground: islamDarkGreen,
        error: islamDarkGreen,
        onError: islamWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: islamDarkGreen,
        foregroundColor: islamWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: islamWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: islamDarkGreen,
          foregroundColor: islamWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: islamDarkGreen,
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: islamWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: islamFreshGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: islamFreshGreen, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: islamDarkGreen, width: 2),
        ),
        labelStyle: const TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: islamWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: islamDarkGreen.withOpacity(0.3),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: islamFreshGreen,
        selectedItemColor: islamDarkGreen,
        unselectedItemColor: islamWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
        ),
        bodyMedium: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
        ),
        bodySmall: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
        ),
        labelLarge: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: islamDarkGreen,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: islamDarkGreen,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: islamDarkGreen,
        foregroundColor: islamWhite,
        elevation: 6,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: islamFreshGreen,
        thickness: 1,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: islamDarkGreen,
        linearTrackColor: islamFreshGreen,
        circularTrackColor: islamFreshGreen,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return islamDarkGreen;
          }
          return islamWhite;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return islamFreshGreen;
          }
          return Colors.grey;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return islamDarkGreen;
          }
          return islamWhite;
        }),
        checkColor: MaterialStateProperty.all(islamWhite),
        side: const BorderSide(color: islamFreshGreen, width: 2),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return islamDarkGreen;
          }
          return islamFreshGreen;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: islamDarkGreen,
        inactiveTrackColor: islamFreshGreen,
        thumbColor: islamDarkGreen,
        overlayColor: islamDarkGreen.withOpacity(0.2),
      ),
    );
  }
  
  static ThemeData _getChristianTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: christianDeepBlue,
        secondary: christianLightBlue,
        surface: christianWhite,
        background: christianWhite,
        onPrimary: christianWhite,
        onSecondary: christianDeepBlue,
        onSurface: christianDeepBlue,
        onBackground: christianDeepBlue,
        error: christianDeepBlue,
        onError: christianWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: christianDeepBlue,
        foregroundColor: christianWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: christianWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: christianDeepBlue,
          foregroundColor: christianWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: christianDeepBlue,
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: christianWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: christianGold, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: christianGold, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: christianDeepBlue, width: 2),
        ),
        labelStyle: const TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: christianWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: christianDeepBlue.withOpacity(0.3),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: christianGold,
        selectedItemColor: christianDeepBlue,
        unselectedItemColor: christianWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
        ),
        bodyMedium: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
        ),
        bodySmall: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
        ),
        labelLarge: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: christianDeepBlue,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: christianDeepBlue,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: christianDeepBlue,
        foregroundColor: christianWhite,
        elevation: 6,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: christianGold,
        thickness: 1,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: christianDeepBlue,
        linearTrackColor: christianGold,
        circularTrackColor: christianGold,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return christianDeepBlue;
          }
          return christianWhite;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return christianGold;
          }
          return Colors.grey;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return christianDeepBlue;
          }
          return christianWhite;
        }),
        checkColor: MaterialStateProperty.all(christianWhite),
        side: const BorderSide(color: christianGold, width: 2),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return christianDeepBlue;
          }
          return christianGold;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: christianDeepBlue,
        inactiveTrackColor: christianGold,
        thumbColor: christianDeepBlue,
        overlayColor: christianDeepBlue.withOpacity(0.2),
      ),
    );
  }
  
  static ThemeData _getJainismTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: jainDeepRed,
        secondary: jainSaffron,
        surface: jainWhite,
        background: jainWhite,
        onPrimary: jainWhite,
        onSecondary: jainDeepRed,
        onSurface: jainDeepRed,
        onBackground: jainDeepRed,
        error: jainDeepRed,
        onError: jainWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: jainDeepRed,
        foregroundColor: jainWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: jainWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: jainDeepRed,
          foregroundColor: jainWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: jainDeepRed,
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: jainWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: jainSaffron, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: jainSaffron, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: jainDeepRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: jainWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: jainDeepRed.withOpacity(0.3),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: jainSaffron,
        selectedItemColor: jainDeepRed,
        unselectedItemColor: jainWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
        ),
        bodyMedium: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
        ),
        bodySmall: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
        ),
        labelLarge: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: jainDeepRed,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: jainDeepRed,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: jainDeepRed,
        foregroundColor: jainWhite,
        elevation: 6,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: jainSaffron,
        thickness: 1,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: jainDeepRed,
        linearTrackColor: jainSaffron,
        circularTrackColor: jainSaffron,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return jainDeepRed;
          }
          return jainWhite;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return jainSaffron;
          }
          return Colors.grey;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return jainDeepRed;
          }
          return jainWhite;
        }),
        checkColor: MaterialStateProperty.all(jainWhite),
        side: const BorderSide(color: jainSaffron, width: 2),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return jainDeepRed;
          }
          return jainSaffron;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: jainDeepRed,
        inactiveTrackColor: jainSaffron,
        thumbColor: jainDeepRed,
        overlayColor: jainDeepRed.withOpacity(0.2),
      ),
    );
  }
  
  static ThemeData _getBuddhismTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: buddhistMonkOrange,
        secondary: buddhistGoldenYellow,
        surface: buddhistPaleGold,
        background: buddhistPaleGold,
        onPrimary: buddhistWhite,
        onSecondary: buddhistMonkOrange,
        onSurface: buddhistMonkOrange,
        onBackground: buddhistMonkOrange,
        error: buddhistMonkOrange,
        onError: buddhistWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: buddhistMonkOrange,
        foregroundColor: buddhistWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: buddhistWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buddhistMonkOrange,
          foregroundColor: buddhistWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: buddhistMonkOrange,
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: buddhistWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: buddhistPaleGold, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: buddhistPaleGold, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: buddhistMonkOrange, width: 2),
        ),
        labelStyle: const TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: buddhistWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: buddhistMonkOrange.withOpacity(0.3),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: buddhistPaleGold,
        selectedItemColor: buddhistMonkOrange,
        unselectedItemColor: buddhistWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
        ),
        bodyMedium: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
        ),
        bodySmall: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
        ),
        labelLarge: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: buddhistMonkOrange,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: buddhistMonkOrange,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: buddhistMonkOrange,
        foregroundColor: buddhistWhite,
        elevation: 6,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: buddhistPaleGold,
        thickness: 1,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: buddhistMonkOrange,
        linearTrackColor: buddhistPaleGold,
        circularTrackColor: buddhistPaleGold,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return buddhistMonkOrange;
          }
          return buddhistWhite;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return buddhistPaleGold;
          }
          return Colors.grey;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return buddhistMonkOrange;
          }
          return buddhistWhite;
        }),
        checkColor: MaterialStateProperty.all(buddhistWhite),
        side: const BorderSide(color: buddhistPaleGold, width: 2),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return buddhistMonkOrange;
          }
          return buddhistPaleGold;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: buddhistMonkOrange,
        inactiveTrackColor: buddhistPaleGold,
        thumbColor: buddhistMonkOrange,
        overlayColor: buddhistMonkOrange.withOpacity(0.2),
      ),
    );
  }
  
  static ThemeData _getDefaultTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: defaultPrimary,
        secondary: defaultSecondary,
        surface: defaultSecondary,
        background: defaultSecondary,
        onPrimary: defaultSecondary,
        onSecondary: defaultPrimary,
        onSurface: defaultPrimary,
        onBackground: defaultPrimary,
        error: defaultPrimary,
        onError: defaultSecondary,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: defaultPrimary,
        foregroundColor: defaultSecondary,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: defaultSecondary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultPrimary,
          foregroundColor: defaultSecondary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: defaultPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: defaultSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: defaultAccent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: defaultAccent, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: defaultPrimary, width: 2),
        ),
        labelStyle: const TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'Roboto', // System font
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: defaultSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: defaultPrimary.withOpacity(0.3),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: defaultAccent,
        selectedItemColor: defaultSecondary,
        unselectedItemColor: defaultPrimary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
        ),
        bodyMedium: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
        ),
        bodySmall: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
        ),
        labelLarge: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: defaultPrimary,
          fontFamily: 'Roboto', // System font
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: defaultPrimary,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: defaultPrimary,
        foregroundColor: defaultSecondary,
        elevation: 6,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: defaultAccent,
        thickness: 1,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: defaultPrimary,
        linearTrackColor: defaultAccent,
        circularTrackColor: defaultAccent,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return defaultPrimary;
          }
          return defaultSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return defaultAccent;
          }
          return Colors.grey;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return defaultPrimary;
          }
          return defaultSecondary;
        }),
        checkColor: MaterialStateProperty.all(defaultSecondary),
        side: const BorderSide(color: defaultAccent, width: 2),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return defaultPrimary;
          }
          return defaultAccent;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: defaultPrimary,
        inactiveTrackColor: defaultAccent,
        thumbColor: defaultPrimary,
        overlayColor: defaultPrimary.withOpacity(0.2),
      ),
    );
  }
  
  // Helper methods to get current theme colors
  Color get primaryColor => _currentTheme.colorScheme.primary;
  Color get secondaryColor => _currentTheme.colorScheme.secondary;
  Color get backgroundColor => _currentTheme.colorScheme.background;
  Color get surfaceColor => _currentTheme.colorScheme.surface;
  Color get onPrimaryColor => _currentTheme.colorScheme.onPrimary;
  Color get onSecondaryColor => _currentTheme.colorScheme.onSecondary;
  Color get onBackgroundColor => _currentTheme.colorScheme.onBackground;
  Color get onSurfaceColor => _currentTheme.colorScheme.onSurface;

  // New theme methods for additional religions
  static ThemeData _getSikhismTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: sikhSaffron,
        secondary: sikhDeepOrange,
        surface: sikhWhite,
        background: sikhWhite,
        onPrimary: sikhWhite,
        onSecondary: sikhNavyBlue,
        onSurface: sikhNavyBlue,
        onBackground: sikhNavyBlue,
        error: sikhNavyBlue,
        onError: sikhWhite,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: sikhSaffron,
        foregroundColor: sikhWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: sikhWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData _getJudaismTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: jewishDeepBlue,
        secondary: jewishLightBlue,
        surface: jewishSilver,
        background: jewishSilver,
        onPrimary: jewishWhite,
        onSecondary: jewishDeepBlue,
        onSurface: jewishDeepBlue,
        onBackground: jewishDeepBlue,
        error: jewishDeepBlue,
        onError: jewishWhite,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: jewishDeepBlue,
        foregroundColor: jewishWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: jewishWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData _getBahaiTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: bahaiWarmOrange,
        secondary: bahaiViolet,
        surface: bahaiWhite,
        background: bahaiWhite,
        onPrimary: bahaiWhite,
        onSecondary: bahaiJadeGreen,
        onSurface: bahaiJadeGreen,
        onBackground: bahaiJadeGreen,
        error: bahaiJadeGreen,
        onError: bahaiWhite,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: bahaiWarmOrange,
        foregroundColor: bahaiWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: bahaiWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData _getTaoismTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: taoBlack,
        secondary: taoCharcoal,
        surface: taoOffWhite,
        background: taoOffWhite,
        onPrimary: taoOffWhite,
        onSecondary: taoGold,
        onSurface: taoJadeGreen,
        onBackground: taoJadeGreen,
        error: taoJadeGreen,
        onError: taoOffWhite,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: taoBlack,
        foregroundColor: taoOffWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: taoOffWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData _getIndigenousTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: indigenousEarthBrown,
        secondary: indigenousClayBrown,
        surface: indigenousSandstone,
        background: indigenousSandstone,
        onPrimary: indigenousWhite,
        onSecondary: indigenousForestGreen,
        onSurface: indigenousForestGreen,
        onBackground: indigenousForestGreen,
        error: indigenousForestGreen,
        onError: indigenousWhite,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: indigenousEarthBrown,
        foregroundColor: indigenousWhite,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: indigenousWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
