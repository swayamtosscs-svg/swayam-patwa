import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Validate URL
    if (imageUrl.isEmpty || 
        (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
      return _buildErrorWidget('Invalid image URL');
    }

    // Use CachedNetworkImage for better performance
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? (width != null ? (width! * MediaQuery.of(context).devicePixelRatio).round() : null),
      memCacheHeight: memCacheHeight ?? (height != null ? (height! * MediaQuery.of(context).devicePixelRatio).round() : null),
      placeholder: placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: errorWidget ?? _buildDefaultErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 200), // Faster fade in
      fadeOutDuration: const Duration(milliseconds: 100),
      // Optimize for performance
      useOldImageOnUrlChange: true,
      maxWidthDiskCache: 800, // Limit disk cache size
      maxHeightDiskCache: 600,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized image widget for profile pictures
class OptimizedProfileImageWidget extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool showBorder;

  const OptimizedProfileImageWidget({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBorder
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            )
          : null,
      child: ClipOval(
        child: OptimizedImageWidget(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
          memCacheHeight: (size * MediaQuery.of(context).devicePixelRatio).round(),
        ),
      ),
    );
  }
}

/// Optimized image widget for story thumbnails
class OptimizedStoryImageWidget extends StatelessWidget {
  final String imageUrl;
  final double size;

  const OptimizedStoryImageWidget({
    super.key,
    required this.imageUrl,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.purple,
            Colors.orange,
            Colors.pink,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: OptimizedImageWidget(
          imageUrl: imageUrl,
          width: size - 4,
          height: size - 4,
          fit: BoxFit.cover,
          memCacheWidth: ((size - 4) * MediaQuery.of(context).devicePixelRatio).round(),
          memCacheHeight: ((size - 4) * MediaQuery.of(context).devicePixelRatio).round(),
        ),
      ),
    );
  }
}
