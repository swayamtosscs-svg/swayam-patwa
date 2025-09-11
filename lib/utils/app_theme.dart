import 'package:flutter/material.dart';

class AppTheme {
  // RGRAM Brand Colors - Based on Logo (Warm Beige and Brown)
  static const Color primaryColor = Color(0xFFD2691E); // Golden Orange from logo text
  static const Color secondaryColor = Color(0xFFFFD700); // Gold from logo glow
  static const Color accentColor = Color(0xFF8B4513); // Rich Brown from logo text
  static const Color backgroundColor = Color(0xFFFDF5E6); // Very light beige from logo background
  static const Color surfaceColor = Color(0xFFFFF3E0); // Light cream from logo disc
  static const Color cardColor = Color(0xFFFFFDE7); // Very light cream for cards
  static const Color textPrimary = Color(0xFF8B4513); // Rich Brown for primary text
  static const Color textSecondary = Color(0xFFD2691E); // Golden Orange for secondary text
  static const Color textLight = Color(0xFFDAA520); // Goldenrod for light text
  static const Color successColor = Color(0xFF228B22); // Forest Green for success
  static const Color warningColor = Color(0xFFFF8C00); // Dark Orange for warnings
  static const Color errorColor = Color(0xFFDC143C); // Crimson for errors
  static const Color borderColor = Color(0xFFFFD700); // Gold border color
  
  // Religious Theme Colors - Beige and Brown Palette
  static const Color saffronColor = Color(0xFFD2691E); // Golden Orange
  static const Color goldColor = Color(0xFFDAA520); // Goldenrod
  static const Color crimsonColor = Color(0xFF8B4513); // Rich Brown
  static const Color maroonColor = Color(0xFF654321); // Dark Brown
  static const Color creamColor = Color(0xFFFDF5E6); // Old Lace
  
  // Gradient colors for backgrounds - Based on Logo
  static const List<Color> primaryGradient = [
    Color(0xFFD2691E), // Golden Orange from logo text
    Color(0xFFFFD700), // Gold from logo glow
    Color(0xFF8B4513), // Rich Brown from logo text
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFFDF5E6), // Very light beige from logo background
    Color(0xFFFFF3E0), // Light cream from logo disc
    Color(0xFFFFFDE7), // Very light cream
  ];
  
  static const List<Color> splashGradient = [
    Color(0xFF8B4513), // Rich Brown
    Color(0xFFD2691E), // Golden Orange
    Color(0xFFFFD700), // Gold
    Color(0xFFDAA520), // Goldenrod
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFFFFFDE7), // Very light cream
    Color(0xFFFFF3E0), // Light cream
  ];
  
  static const List<Color> buttonGradient = [
    Color(0xFF8B4513), // Rich Brown
    Color(0xFFD2691E), // Golden Orange
  ];
  
  static const List<Color> religiousGradient = [
    Color(0xFF8B4513), // Rich Brown
    Color(0xFFDAA520), // Goldenrod
    Color(0xFFD2691E), // Golden Orange
    Color(0xFF654321), // Dark Brown
  ];

  // Text styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: 'Poppins',
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: 'Poppins',
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    fontFamily: 'Poppins',
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    shadowColor: primaryColor.withOpacity(0.3),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: primaryColor, width: 2),
    ),
    elevation: 0,
  );
  
  static ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    shadowColor: accentColor.withOpacity(0.3),
  );
  
  static ButtonStyle successButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  // Input decoration
  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: textLight),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // App theme
  static ThemeData get theme {
    return ThemeData(
      primarySwatch: MaterialColor(0xFFFF6B35, {
        50: Color(0xFFFFF3E0),
        100: Color(0xFFFFE0B2),
        200: Color(0xFFFFCC80),
        300: Color(0xFFFFB74D),
        400: Color(0xFFFFA726),
        500: Color(0xFFFF6B35),
        600: Color(0xFFFF5722),
        700: Color(0xFFE64A19),
        800: Color(0xFFD84315),
        900: Color(0xFFBF360C),
      }),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
