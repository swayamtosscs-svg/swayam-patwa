import 'package:flutter/material.dart';
import '../utils/font_theme.dart';

/// Widget for selecting text styles in Stories/Reels editor
class TextStyleSelector extends StatefulWidget {
  final String selectedStyle;
  final Function(String) onStyleChanged;
  final String previewText;

  const TextStyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onStyleChanged,
    this.previewText = 'Sample Text',
  });

  @override
  State<TextStyleSelector> createState() => _TextStyleSelectorState();
}

class _TextStyleSelectorState extends State<TextStyleSelector> {
  late String _selectedStyle;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.selectedStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: FontTheme.availableTextStyles.length,
        itemBuilder: (context, index) {
          final style = FontTheme.availableTextStyles[index];
          final isSelected = _selectedStyle == style;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStyle = style;
              });
              widget.onStyleChanged(style);
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Style name
                  Text(
                    style.toUpperCase(),
                    style: FontTheme.caption.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Preview text
                  Flexible(
                    child: Text(
                      widget.previewText,
                      style: FontTheme.getTextStyle(style, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget for displaying text with selected style in Stories/Reels
class StyledTextWidget extends StatelessWidget {
  final String text;
  final String styleName;
  final Color? color;
  final double? fontSize;
  final bool isBold;
  final TextAlign? textAlign;

  const StyledTextWidget({
    super.key,
    required this.text,
    required this.styleName,
    this.color,
    this.fontSize,
    this.isBold = false,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle;
    
    if (isBold) {
      textStyle = FontTheme.getBoldTextStyle(styleName, color: color, fontSize: fontSize);
    } else {
      textStyle = FontTheme.getTextStyle(styleName, color: color, fontSize: fontSize);
    }

    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
    );
  }
}

/// Widget for text style customization in Stories/Reels editor
class TextStyleCustomizer extends StatefulWidget {
  final String selectedStyle;
  final Color selectedColor;
  final double selectedFontSize;
  final bool isBold;
  final Function(String) onStyleChanged;
  final Function(Color) onColorChanged;
  final Function(double) onFontSizeChanged;
  final Function(bool) onBoldChanged;

  const TextStyleCustomizer({
    super.key,
    required this.selectedStyle,
    required this.selectedColor,
    required this.selectedFontSize,
    required this.isBold,
    required this.onStyleChanged,
    required this.onColorChanged,
    required this.onFontSizeChanged,
    required this.onBoldChanged,
  });

  @override
  State<TextStyleCustomizer> createState() => _TextStyleCustomizerState();
}

class _TextStyleCustomizerState extends State<TextStyleCustomizer> {
  late String _selectedStyle;
  late Color _selectedColor;
  late double _selectedFontSize;
  late bool _isBold;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.selectedStyle;
    _selectedColor = widget.selectedColor;
    _selectedFontSize = widget.selectedFontSize;
    _isBold = widget.isBold;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Style Selector
          TextStyleSelector(
            selectedStyle: _selectedStyle,
            onStyleChanged: (style) {
              setState(() {
                _selectedStyle = style;
              });
              widget.onStyleChanged(style);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Color Selector
          Row(
            children: [
              Text(
                'Color:',
                style: FontTheme.labelText.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Colors.white,
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.purple,
                    Colors.orange,
                  ].map((color) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                      widget.onColorChanged(color);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color ? Colors.white : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Font Size Slider
          Row(
            children: [
              Text(
                'Size:',
                style: FontTheme.labelText.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _selectedFontSize,
                  min: 12,
                  max: 48,
                  divisions: 18,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                  onChanged: (value) {
                    setState(() {
                      _selectedFontSize = value;
                    });
                    widget.onFontSizeChanged(value);
                  },
                ),
              ),
              Text(
                '${_selectedFontSize.round()}',
                style: FontTheme.labelText.copyWith(color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bold Toggle
          Row(
            children: [
              Text(
                'Bold:',
                style: FontTheme.labelText.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 16),
              Switch(
                value: _isBold,
                onChanged: (value) {
                  setState(() {
                    _isBold = value;
                  });
                  widget.onBoldChanged(value);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

