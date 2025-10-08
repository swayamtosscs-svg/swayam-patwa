import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String? verificationType;
  final double size;
  final Color? color;
  final bool showText;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.verificationType,
    this.size = 16.0,
    this.color,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    final badgeColor = color ?? Colors.blue[600]!;
    final iconSize = size;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: iconSize * 0.6,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: badgeColor,
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class VerificationBadgeSmall extends StatelessWidget {
  final bool isVerified;
  final String? verificationType;

  const VerificationBadgeSmall({
    super.key,
    required this.isVerified,
    this.verificationType,
  });

  @override
  Widget build(BuildContext context) {
    return VerificationBadge(
      isVerified: isVerified,
      verificationType: verificationType,
      size: 12.0,
    );
  }
}

class VerificationBadgeMedium extends StatelessWidget {
  final bool isVerified;
  final String? verificationType;

  const VerificationBadgeMedium({
    super.key,
    required this.isVerified,
    this.verificationType,
  });

  @override
  Widget build(BuildContext context) {
    return VerificationBadge(
      isVerified: isVerified,
      verificationType: verificationType,
      size: 16.0,
    );
  }
}

class VerificationBadgeLarge extends StatelessWidget {
  final bool isVerified;
  final String? verificationType;
  final bool showText;

  const VerificationBadgeLarge({
    super.key,
    required this.isVerified,
    this.verificationType,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return VerificationBadge(
      isVerified: isVerified,
      verificationType: verificationType,
      size: 20.0,
      showText: showText,
    );
  }
}

// Widget for displaying username with verification badge
class VerifiedUsername extends StatelessWidget {
  final String username;
  final bool isVerified;
  final String? verificationType;
  final TextStyle? textStyle;
  final double badgeSize;

  const VerifiedUsername({
    super.key,
    required this.username,
    required this.isVerified,
    this.verificationType,
    this.textStyle,
    this.badgeSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          username,
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 4),
        VerificationBadge(
          isVerified: isVerified,
          verificationType: verificationType,
          size: badgeSize,
        ),
      ],
    );
  }
}

// Widget for displaying profile picture with verification badge
class VerifiedProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final bool isVerified;
  final String? verificationType;
  final double size;
  final double badgeSize;

  const VerifiedProfilePicture({
    super.key,
    this.imageUrl,
    required this.isVerified,
    this.verificationType,
    this.size = 40.0,
    this.badgeSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
          child: imageUrl == null || imageUrl!.isEmpty
              ? Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: Colors.grey[600],
                )
              : null,
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: VerificationBadge(
              isVerified: isVerified,
              verificationType: verificationType,
              size: badgeSize,
            ),
          ),
      ],
    );
  }
}
