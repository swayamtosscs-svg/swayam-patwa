import 'package:flutter/material.dart';

/// Comprehensive font theme configuration for R-Gram app
/// Based on Instagram's font system with additional spiritual-themed styles
class FontTheme {
  // Font Family Constants - Using system fonts as fallbacks
  static const String roboto = 'Roboto'; // System font
  static const String instagramSans = 'Roboto'; // Fallback to Roboto
  static const String classic = 'Roboto'; // Fallback to Roboto
  static const String modern = 'Roboto'; // Fallback to Roboto
  static const String neon = 'Roboto'; // Fallback to Roboto
  static const String typewriter = 'Courier New'; // System monospace font
  static const String strong = 'Roboto'; // Fallback to Roboto
  static const String elegant = 'Times New Roman'; // System serif font
  static const String literature = 'Times New Roman'; // System serif font
  static const String directional = 'Roboto'; // Fallback to Roboto
  static const String bubble = 'Roboto'; // Fallback to Roboto
  static const String poster = 'Roboto'; // Fallback to Roboto
  static const String editor = 'Times New Roman'; // System serif font

  // Font Weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;

  // UI Text Styles (Roboto)
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: roboto,
    fontSize: 20,
    fontWeight: semiBold,
    color: Colors.black87,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: medium,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: roboto,
    fontSize: 14,
    fontWeight: regular,
    color: Colors.black54,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: regular,
    color: Colors.black87,
  );

  static const TextStyle profileName = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: semiBold,
    color: Colors.black87,
  );

  static const TextStyle commentText = TextStyle(
    fontFamily: roboto,
    fontSize: 14,
    fontWeight: regular,
    color: Colors.black87,
  );

  static const TextStyle menuText = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: regular,
    color: Colors.black87,
  );

  static const TextStyle inputText = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: regular,
    color: Colors.black87,
  );

  static const TextStyle labelText = TextStyle(
    fontFamily: roboto,
    fontSize: 14,
    fontWeight: medium,
    color: Colors.black54,
  );

  static const TextStyle errorText = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    fontWeight: regular,
    color: Colors.red,
  );

  static const TextStyle successText = TextStyle(
    fontFamily: roboto,
    fontSize: 12,
    fontWeight: regular,
    color: Colors.green,
  );

  // Branding Text Styles (Instagram Sans)
  static const TextStyle brandTitle = TextStyle(
    fontFamily: instagramSans,
    fontSize: 32,
    fontWeight: bold,
    color: Colors.black87,
  );

  static const TextStyle brandSubtitle = TextStyle(
    fontFamily: instagramSans,
    fontSize: 24,
    fontWeight: semiBold,
    color: Colors.black87,
  );

  static const TextStyle brandCaption = TextStyle(
    fontFamily: instagramSans,
    fontSize: 18,
    fontWeight: medium,
    color: Colors.black54,
  );

  static const TextStyle promotionalText = TextStyle(
    fontFamily: instagramSans,
    fontSize: 20,
    fontWeight: semiBold,
    color: Colors.black87,
  );

  // Stories/Reels Text Styles
  static const TextStyle classicText = TextStyle(
    fontFamily: classic,
    fontSize: 24,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle modernText = TextStyle(
    fontFamily: modern,
    fontSize: 24,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle modernBoldText = TextStyle(
    fontFamily: modern,
    fontSize: 24,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle neonText = TextStyle(
    fontFamily: neon,
    fontSize: 24,
    fontWeight: regular,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.cyan,
        blurRadius: 10,
        offset: Offset(0, 0),
      ),
    ],
  );

  static const TextStyle neonBoldText = TextStyle(
    fontFamily: neon,
    fontSize: 24,
    fontWeight: bold,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.cyan,
        blurRadius: 15,
        offset: Offset(0, 0),
      ),
    ],
  );

  static const TextStyle typewriterText = TextStyle(
    fontFamily: typewriter,
    fontSize: 20,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle typewriterBoldText = TextStyle(
    fontFamily: typewriter,
    fontSize: 20,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle strongText = TextStyle(
    fontFamily: strong,
    fontSize: 28,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle strongBoldText = TextStyle(
    fontFamily: strong,
    fontSize: 28,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle elegantText = TextStyle(
    fontFamily: elegant,
    fontSize: 22,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle elegantBoldText = TextStyle(
    fontFamily: elegant,
    fontSize: 22,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle literatureText = TextStyle(
    fontFamily: literature,
    fontSize: 20,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle literatureBoldText = TextStyle(
    fontFamily: literature,
    fontSize: 20,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle directionalText = TextStyle(
    fontFamily: directional,
    fontSize: 24,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle directionalBoldText = TextStyle(
    fontFamily: directional,
    fontSize: 24,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle bubbleText = TextStyle(
    fontFamily: bubble,
    fontSize: 24,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle bubbleBoldText = TextStyle(
    fontFamily: bubble,
    fontSize: 24,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle posterText = TextStyle(
    fontFamily: poster,
    fontSize: 26,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle posterBoldText = TextStyle(
    fontFamily: poster,
    fontSize: 26,
    fontWeight: bold,
    color: Colors.white,
  );

  static const TextStyle editorText = TextStyle(
    fontFamily: editor,
    fontSize: 20,
    fontWeight: regular,
    color: Colors.white,
  );

  static const TextStyle editorBoldText = TextStyle(
    fontFamily: editor,
    fontSize: 20,
    fontWeight: bold,
    color: Colors.white,
  );

  // Spiritual-themed text styles for R-Gram
  static const TextStyle spiritualTitle = TextStyle(
    fontFamily: elegant,
    fontSize: 28,
    fontWeight: bold,
    color: Color(0xFFD29650), // Logo text color
  );

  static const TextStyle spiritualSubtitle = TextStyle(
    fontFamily: literature,
    fontSize: 20,
    fontWeight: medium,
    color: Color(0xFFD29650),
  );

  static const TextStyle spiritualCaption = TextStyle(
    fontFamily: roboto,
    fontSize: 16,
    fontWeight: regular,
    color: Color(0xFFD29650),
  );

  // Helper method to get text style by name
  static TextStyle getTextStyle(String styleName, {Color? color, double? fontSize}) {
    TextStyle baseStyle;
    
    switch (styleName.toLowerCase()) {
      case 'classic':
        baseStyle = classicText;
        break;
      case 'modern':
        baseStyle = modernText;
        break;
      case 'neon':
        baseStyle = neonText;
        break;
      case 'typewriter':
        baseStyle = typewriterText;
        break;
      case 'strong':
        baseStyle = strongText;
        break;
      case 'elegant':
        baseStyle = elegantText;
        break;
      case 'literature':
        baseStyle = literatureText;
        break;
      case 'directional':
        baseStyle = directionalText;
        break;
      case 'bubble':
        baseStyle = bubbleText;
        break;
      case 'poster':
        baseStyle = posterText;
        break;
      case 'editor':
        baseStyle = editorText;
        break;
      default:
        baseStyle = classicText;
    }

    return baseStyle.copyWith(
      color: color ?? baseStyle.color,
      fontSize: fontSize ?? baseStyle.fontSize,
    );
  }

  // Available text styles for Stories/Reels
  static const List<String> availableTextStyles = [
    'classic',
    'modern',
    'neon',
    'typewriter',
    'strong',
    'elegant',
    'literature',
    'directional',
    'bubble',
    'poster',
    'editor',
  ];

  // Helper method to get bold text style by name
  static TextStyle getBoldTextStyle(String styleName, {Color? color, double? fontSize}) {
    TextStyle baseStyle;
    
    switch (styleName.toLowerCase()) {
      case 'modern':
        baseStyle = modernBoldText;
        break;
      case 'neon':
        baseStyle = neonBoldText;
        break;
      case 'typewriter':
        baseStyle = typewriterBoldText;
        break;
      case 'strong':
        baseStyle = strongBoldText;
        break;
      case 'elegant':
        baseStyle = elegantBoldText;
        break;
      case 'literature':
        baseStyle = literatureBoldText;
        break;
      case 'directional':
        baseStyle = directionalBoldText;
        break;
      case 'bubble':
        baseStyle = bubbleBoldText;
        break;
      case 'poster':
        baseStyle = posterBoldText;
        break;
      case 'editor':
        baseStyle = editorBoldText;
        break;
      default:
        baseStyle = strongBoldText;
    }

    return baseStyle.copyWith(
      color: color ?? baseStyle.color,
      fontSize: fontSize ?? baseStyle.fontSize,
    );
  }
}
