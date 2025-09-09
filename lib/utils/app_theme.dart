import 'package:flutter/material.dart';

class AppTheme {
  // RGRAM Brand Colors - Religious beige and brown theme
  static const Color primaryColor = Color(0xFF8B4513); // Saddle Brown - Main brand color
  static const Color secondaryColor = Color(0xFFA0522D); // Sienna - Secondary brand color
  static const Color accentColor = Color(0xFFD2691E); // Chocolate - Accent color
  static const Color backgroundColor = Color(0xFFFDF5E6); // Old Lace - Warm beige background
  static const Color surfaceColor = Color(0xFFFFF8DC); // Cornsilk - Light beige surface
  static const Color cardColor = Color(0xFFF5E6D3); // Warm beige for cards
  static const Color textPrimary = Color(0xFF3E2723); // Dark brown for primary text
  static const Color textSecondary = Color(0xFF5D4037); // Medium brown for secondary text
  static const Color textLight = Color(0xFF8D6E63); // Light brown for light text
  static const Color successColor = Color(0xFF4CAF50); // Green for success (keeping for functionality)
  static const Color warningColor = Color(0xFFFF9800); // Orange for warnings (keeping for functionality)
  static const Color errorColor = Color(0xFFD32F2F); // Red for errors (keeping for functionality)
  static const Color borderColor = Color(0xFFD7CCC8); // Light beige border color
  
  // Gradient colors for backgrounds - Religious beige and brown theme
  static const List<Color> primaryGradient = [
    Color(0xFF8B4513), // Saddle Brown
    Color(0xFFA0522D), // Sienna
    Color(0xFFD2691E), // Chocolate
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFFFDF5E6), // Old Lace
    Color(0xFFF5E6D3), // Warm beige
    Color(0xFFFFF8DC), // Cornsilk
  ];
  
  static const List<Color> splashGradient = [
    Color(0xFF3E2723), // Dark brown
    Color(0xFF5D4037), // Medium brown
    Color(0xFF8B4513), // Saddle Brown
  ];
  
  static const List<Color> cardGradient = [
    Color(0xFFFFF8DC), // Cornsilk
    Color(0xFFF5E6D3), // Warm beige
  ];
  
  static const List<Color> buttonGradient = [
    Color(0xFF8B4513), // Saddle Brown
    Color(0xFFA0522D), // Sienna
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
      primarySwatch: MaterialColor(0xFF8B4513, {
        50: Color(0xFFF3E5D1),
        100: Color(0xFFE6D1B8),
        200: Color(0xFFD4B896),
        300: Color(0xFFC29E74),
        400: Color(0xFFB58A5A),
        500: Color(0xFF8B4513),
        600: Color(0xFF7A3D11),
        700: Color(0xFF69350F),
        800: Color(0xFF582D0D),
        900: Color(0xFF47250B),
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
