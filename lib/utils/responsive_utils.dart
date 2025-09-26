import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getResponsiveWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * (percentage / 100);
  }

  static double getResponsiveHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * (percentage / 100);
  }

  static EdgeInsets getResponsivePadding(BuildContext context, {
    double horizontal = 4.0,
    double vertical = 4.0,
  }) {
    final screenWidth = getScreenWidth(context);
    final screenHeight = getScreenHeight(context);
    
    return EdgeInsets.symmetric(
      horizontal: screenWidth * (horizontal / 100),
      vertical: screenHeight * (vertical / 100),
    );
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getScreenWidth(context);
    final scaleFactor = screenWidth / 375; // Base width for scaling
    return baseFontSize * scaleFactor.clamp(0.8, 1.2);
  }

  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = getScreenWidth(context);
    final scaleFactor = screenWidth / 375;
    return baseSize * scaleFactor.clamp(0.8, 1.2);
  }

  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BoxDecoration? decoration,
  }) {
    return Container(
      width: width != null ? getResponsiveWidth(context, width) : null,
      height: height != null ? getResponsiveHeight(context, height) : null,
      padding: padding ?? getResponsivePadding(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }

  static Widget responsiveText({
    required BuildContext context,
    required String text,
    double fontSize = 14,
    FontWeight? fontWeight,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: getResponsiveFontSize(context, fontSize),
        fontWeight: fontWeight,
        color: color,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }

  static Widget responsiveIcon({
    required BuildContext context,
    required IconData icon,
    double size = 24,
    Color? color,
  }) {
    return Icon(
      icon,
      size: getResponsiveIconSize(context, size),
      color: color,
    );
  }

  static Widget responsiveSizedBox({
    required BuildContext context,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width != null ? getResponsiveWidth(context, width) : null,
      height: height != null ? getResponsiveHeight(context, height) : null,
    );
  }

  static bool isSmallScreen(BuildContext context) {
    return getScreenWidth(context) < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 360 && width < 768;
  }

  static bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 768;
  }
}
