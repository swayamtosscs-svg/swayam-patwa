# R-Gram Font System Documentation

## Overview

The R-Gram app implements a comprehensive font system based on Instagram's font architecture, with additional spiritual-themed fonts for the unique needs of our spiritual social media platform.

## Font Architecture

### 1. Roboto - UI Text Font
**Usage**: All app UI text (menus, captions, comments, profile info, buttons)

**Font Weights Available**:
- Thin (100)
- Light (300)
- Regular (400)
- Medium (500)
- SemiBold (600)
- Bold (700)
- Black (900)
- Italic variants

**Implementation**:
```dart
// App bar titles
Text('Title', style: FontTheme.appBarTitle)

// Button text
Text('Button', style: FontTheme.buttonText)

// Profile names
Text('Username', style: FontTheme.profileName)

// Comments
Text('Comment text', style: FontTheme.commentText)

// Captions
Text('Caption', style: FontTheme.caption)

// Body text
Text('Body content', style: FontTheme.bodyText)
```

### 2. Instagram Sans - Branding Font
**Usage**: Branding & marketing visuals (logos, campaigns, promotional banners)

**Font Weights Available**:
- Light (300)
- Regular (400)
- Medium (500)
- SemiBold (600)
- Bold (700)

**Implementation**:
```dart
// Brand titles
Text('RGRAM', style: FontTheme.brandTitle)

// Brand subtitles
Text('Subtitle', style: FontTheme.brandSubtitle)

// Promotional text
Text('Promo', style: FontTheme.promotionalText)

// Brand captions
Text('Brand message', style: FontTheme.brandCaption)
```

### 3. Stories/Reels Text Styles
**Usage**: User-selectable text styles in Stories and Reels editor

**Available Styles**:
- **Classic**: Default plain text style
- **Modern**: Clean sans-serif style
- **Neon**: Bright glowing script style
- **Typewriter**: Monospaced serif typewriter look
- **Strong**: Bold block lettering
- **Elegant**: Sophisticated serif style
- **Literature**: Book-style serif font
- **Directional**: Dynamic directional style
- **Bubble**: Playful bubble text
- **Poster**: Bold poster-style text
- **Editor**: Editorial-style serif

**Implementation**:
```dart
// Regular text style
Text('Sample', style: FontTheme.getTextStyle('modern'))

// Bold text style
Text('Sample', style: FontTheme.getBoldTextStyle('modern'))

// With custom color and size
Text('Sample', style: FontTheme.getTextStyle('neon', color: Colors.cyan, fontSize: 24))
```

## File Structure

```
lib/
├── utils/
│   ├── font_theme.dart          # Main font configuration
│   └── font_usage_guide.dart    # Usage examples and guidelines
├── widgets/
│   └── text_style_selector.dart # Stories/Reels text style widgets
└── services/
    └── theme_service.dart       # Updated with Roboto fonts
```

## Font Files Required

Add these font files to `assets/fonts/`:

### Roboto Fonts
- Roboto-Regular.ttf
- Roboto-Medium.ttf
- Roboto-SemiBold.ttf
- Roboto-Bold.ttf
- Roboto-Light.ttf
- Roboto-Thin.ttf
- Roboto-Black.ttf
- Roboto-Italic.ttf
- Roboto-MediumItalic.ttf
- Roboto-BoldItalic.ttf

### Instagram Sans Fonts
- InstagramSans-Regular.ttf
- InstagramSans-Medium.ttf
- InstagramSans-SemiBold.ttf
- InstagramSans-Bold.ttf
- InstagramSans-Light.ttf

### Stories/Reels Text Style Fonts
- Classic-Regular.ttf
- Modern-Regular.ttf
- Modern-Bold.ttf
- Neon-Regular.ttf
- Neon-Bold.ttf
- Typewriter-Regular.ttf
- Typewriter-Bold.ttf
- Strong-Regular.ttf
- Strong-Bold.ttf
- Elegant-Regular.ttf
- Elegant-Bold.ttf
- Literature-Regular.ttf
- Literature-Bold.ttf
- Directional-Regular.ttf
- Directional-Bold.ttf
- Bubble-Regular.ttf
- Bubble-Bold.ttf
- Poster-Regular.ttf
- Poster-Bold.ttf
- Editor-Regular.ttf
- Editor-Bold.ttf

## Usage Guidelines

### 1. UI Text (Roboto)
Use Roboto for all interface elements:
- Navigation menus
- Form labels and input text
- Button text
- Error and success messages
- Profile information
- Comments and captions
- Settings and preferences

### 2. Branding (Instagram Sans)
Use Instagram Sans for:
- App logos and titles
- Marketing campaigns
- Promotional banners
- Brand messaging
- Onboarding screens
- Feature announcements

### 3. Stories/Reels (Style Selection)
Allow users to select from available text styles:
- Provide a style selector widget
- Show real-time preview
- Allow color and size customization
- Support bold variants

### 4. Spiritual Content (Elegant/Literature)
Use elegant and literature fonts for:
- Inspirational quotes
- Spiritual messages
- Religious content
- Meditation guides
- Sacred texts

## Implementation Examples

### Basic Text Usage
```dart
import '../utils/font_theme.dart';

// UI Text
Text('Welcome', style: FontTheme.bodyText)

// Brand Text
Text('RGRAM', style: FontTheme.brandTitle)

// Spiritual Text
Text('Peace be with you', style: FontTheme.spiritualTitle)
```

### Stories/Reels Text Editor
```dart
import '../widgets/text_style_selector.dart';

TextStyleSelector(
  selectedStyle: 'modern',
  onStyleChanged: (style) {
    // Update text style
  },
  previewText: 'Your text here',
)
```

### Custom Text Styling
```dart
StyledTextWidget(
  text: 'Hello World',
  styleName: 'neon',
  color: Colors.cyan,
  fontSize: 24,
  isBold: true,
)
```

## Theme Integration

The font system is integrated with the existing religious theme system:

```dart
// Theme service automatically uses Roboto for all text
ThemeService themeService = Provider.of<ThemeService>(context);

// Text automatically inherits theme colors
Text('Themed text', style: FontTheme.bodyText)
```

## Best Practices

1. **Consistency**: Always use the predefined text styles from `FontTheme`
2. **Hierarchy**: Use appropriate font weights to create visual hierarchy
3. **Accessibility**: Ensure sufficient contrast between text and background
4. **Performance**: Preload commonly used fonts
5. **User Choice**: Allow users to customize text styles in Stories/Reels
6. **Branding**: Use Instagram Sans consistently for brand elements
7. **Spiritual Content**: Use elegant fonts for spiritual and inspirational content

## Migration Guide

To update existing screens to use the new font system:

1. Import the font theme:
```dart
import '../utils/font_theme.dart';
```

2. Replace hardcoded font families:
```dart
// Before
Text('Hello', style: TextStyle(fontFamily: 'Poppins'))

// After
Text('Hello', style: FontTheme.bodyText)
```

3. Update theme service references:
```dart
// Before
fontFamily: 'Poppins'

// After
fontFamily: FontTheme.roboto
```

## Testing

Test the font system with:
- Different screen sizes
- Various text lengths
- Multiple languages
- Accessibility features
- Performance on different devices

## Future Enhancements

- Dynamic font loading
- User font preferences
- Additional spiritual-themed fonts
- Font size accessibility options
- Custom font upload for users
- Font pairing suggestions
