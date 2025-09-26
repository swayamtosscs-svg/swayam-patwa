import 'package:flutter/material.dart';
import '../utils/avatar_utils.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? userName;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;

  const UserAvatarWidget({
    Key? key,
    this.avatarUrl,
    this.userName,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 2,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder && borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty && AvatarUtils.isValidAvatarUrl(avatarUrl)
            ? Image.network(
                AvatarUtils.getAbsoluteAvatarUrl(avatarUrl!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return AvatarUtils.buildDefaultAvatar(
                    name: userName,
                    size: size,
                    borderColor: borderColor,
                    borderWidth: 0, // No border since container handles it
                  );
                },
              )
            : AvatarUtils.buildDefaultAvatar(
                name: userName,
                size: size,
                borderColor: borderColor,
                borderWidth: 0, // No border since container handles it
              ),
      ),
    );
  }
}
