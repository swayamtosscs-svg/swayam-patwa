import 'package:flutter/material.dart';
import 'font_theme.dart';

/// Comprehensive guide for using fonts throughout the R-Gram app
/// This class provides examples and best practices for font usage
class FontUsageGuide {
  
  /// Example: App Bar Title
  static Widget appBarTitle(String title) {
    return Text(
      title,
      style: FontTheme.appBarTitle,
    );
  }

  /// Example: Button Text
  static Widget buttonText(String text) {
    return Text(
      text,
      style: FontTheme.buttonText,
    );
  }

  /// Example: Profile Name
  static Widget profileName(String name) {
    return Text(
      name,
      style: FontTheme.profileName,
    );
  }

  /// Example: Comment Text
  static Widget commentText(String comment) {
    return Text(
      comment,
      style: FontTheme.commentText,
    );
  }

  /// Example: Caption Text
  static Widget captionText(String caption) {
    return Text(
      caption,
      style: FontTheme.caption,
    );
  }

  /// Example: Body Text
  static Widget bodyText(String text) {
    return Text(
      text,
      style: FontTheme.bodyText,
    );
  }

  /// Example: Brand Title (Instagram Sans)
  static Widget brandTitle(String title) {
    return Text(
      title,
      style: FontTheme.brandTitle,
    );
  }

  /// Example: Brand Subtitle (Instagram Sans)
  static Widget brandSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: FontTheme.brandSubtitle,
    );
  }

  /// Example: Spiritual Title (Elegant font)
  static Widget spiritualTitle(String title) {
    return Text(
      title,
      style: FontTheme.spiritualTitle,
    );
  }

  /// Example: Spiritual Subtitle (Literature font)
  static Widget spiritualSubtitle(String subtitle) {
    return Text(
      subtitle,
      style: FontTheme.spiritualSubtitle,
    );
  }

  /// Example: Stories/Reels Text with Style Selection
  static Widget storiesText(String text, String styleName, {Color? color, double? fontSize}) {
    return Text(
      text,
      style: FontTheme.getTextStyle(styleName, color: color, fontSize: fontSize),
    );
  }

  /// Example: Stories/Reels Bold Text with Style Selection
  static Widget storiesBoldText(String text, String styleName, {Color? color, double? fontSize}) {
    return Text(
      text,
      style: FontTheme.getBoldTextStyle(styleName, color: color, fontSize: fontSize),
    );
  }

  /// Example: Input Field Label
  static Widget inputLabel(String label) {
    return Text(
      label,
      style: FontTheme.labelText,
    );
  }

  /// Example: Error Text
  static Widget errorText(String error) {
    return Text(
      error,
      style: FontTheme.errorText,
    );
  }

  /// Example: Success Text
  static Widget successText(String message) {
    return Text(
      message,
      style: FontTheme.successText,
    );
  }

  /// Example: Menu Item Text
  static Widget menuText(String text) {
    return Text(
      text,
      style: FontTheme.menuText,
    );
  }

  /// Example: Promotional Banner Text (Instagram Sans)
  static Widget promotionalText(String text) {
    return Text(
      text,
      style: FontTheme.promotionalText,
    );
  }

  /// Example: Brand Caption (Instagram Sans)
  static Widget brandCaption(String caption) {
    return Text(
      caption,
      style: FontTheme.brandCaption,
    );
  }

  /// Example: Spiritual Caption (Roboto with logo color)
  static Widget spiritualCaption(String caption) {
    return Text(
      caption,
      style: FontTheme.spiritualCaption,
    );
  }

  // Available Stories/Reels Text Styles
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

  /// Get a dropdown widget for text style selection
  static Widget textStyleDropdown({
    required String selectedStyle,
    required Function(String) onChanged,
  }) {
    return DropdownButton<String>(
      value: selectedStyle,
      onChanged: (String? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      items: availableTextStyles.map<DropdownMenuItem<String>>((String style) {
        return DropdownMenuItem<String>(
          value: style,
          child: Text(
            style.toUpperCase(),
            style: FontTheme.getTextStyle(style),
          ),
        );
      }).toList(),
    );
  }

  /// Example: Complete Text Style Preview Widget
  static Widget textStylePreview(String text, String styleName) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${styleName.toUpperCase()} Style:',
            style: FontTheme.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: FontTheme.getTextStyle(styleName),
          ),
          const SizedBox(height: 8),
          Text(
            '${styleName.toUpperCase()} Bold:',
            style: FontTheme.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: FontTheme.getBoldTextStyle(styleName),
          ),
        ],
      ),
    );
  }

  /// Example: Font Usage Guidelines Widget
  static Widget fontGuidelines() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roboto Usage
          brandTitle('Roboto Font Usage'),
          const SizedBox(height: 16),
          bodyText('Use Roboto for all UI text elements:'),
          const SizedBox(height: 8),
          captionText('• Menus and navigation'),
          captionText('• Captions and descriptions'),
          captionText('• Comments and user input'),
          captionText('• Profile information'),
          captionText('• Button text'),
          captionText('• Form labels and input text'),
          captionText('• Error and success messages'),
          
          const SizedBox(height: 24),
          
          // Instagram Sans Usage
          brandTitle('Instagram Sans Font Usage'),
          const SizedBox(height: 16),
          bodyText('Use Instagram Sans for branding elements:'),
          const SizedBox(height: 8),
          captionText('• App logos and titles'),
          captionText('• Marketing campaigns'),
          captionText('• Promotional banners'),
          captionText('• Brand messaging'),
          
          const SizedBox(height: 24),
          
          // Stories/Reels Text Styles
          brandTitle('Stories/Reels Text Styles'),
          const SizedBox(height: 16),
          bodyText('Available text styles for user content:'),
          const SizedBox(height: 8),
          ...availableTextStyles.map((style) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: textStylePreview('Sample Text', style),
          )).toList(),
          
          const SizedBox(height: 24),
          
          // Spiritual-themed Usage
          spiritualTitle('Spiritual-themed Text'),
          const SizedBox(height: 16),
          spiritualCaption('Use elegant and literature fonts for spiritual content'),
          const SizedBox(height: 8),
          spiritualSubtitle('Perfect for inspirational quotes and spiritual messages'),
        ],
      ),
    );
  }
}
