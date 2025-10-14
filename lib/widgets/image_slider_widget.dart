import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/responsive_image_utils.dart';

class ImageSliderController {
  static _ImageSliderWidgetState? _currentSlider;
  
  static void setCurrentSlider(_ImageSliderWidgetState? state) {
    _currentSlider = state;
  }
  
  static void nextImage() {
    _currentSlider?.nextImage();
  }
  
  static void previousImage() {
    _currentSlider?.previousImage();
  }
  
  static bool get hasMultipleImages => (_currentSlider?.widget.imageUrls.length ?? 0) > 1;
  
  static int get currentIndex => _currentSlider?._currentIndex ?? 0;
  
  static int get imageCount => _currentSlider?.widget.imageUrls.length ?? 0;
}

class ImageSliderWidget extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final bool showCounter;
  final VoidCallback? onTap;

  const ImageSliderWidget({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.showCounter = true,
    this.onTap,
  });

  @override
  State<ImageSliderWidget> createState() => _ImageSliderWidgetState();
}

class _ImageSliderWidgetState extends State<ImageSliderWidget> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
    // Register this slider as the current one
    ImageSliderController.setCurrentSlider(this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    // Unregister this slider
    if (ImageSliderController._currentSlider == this) {
      ImageSliderController.setCurrentSlider(null);
    }
    super.dispose();
  }

  void nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 48,
          ),
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          child: _buildImageWidget(widget.imageUrls.first),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        child: Stack(
          children: [
            // Image Slider
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return _buildImageWidget(widget.imageUrls[index]);
              },
            ),
            
            // Counter Overlay (like LinkedIn)
            if (widget.showCounter && widget.imageUrls.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // Dot Indicators
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imageUrls.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // Validate and clean the image URL
    String cleanUrl = imageUrl.trim();
    
    // Check if URL is valid
    if (cleanUrl.isEmpty || 
        (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://'))) {
      return _buildErrorWidget('Invalid image URL');
    }

    // Try CachedNetworkImage first for better performance
    try {
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: BoxFit.cover, // Maintain aspect ratio while filling container
        width: double.infinity,
        height: widget.height,
        placeholder: (context, url) => AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[200]!,
                    Colors.grey[300]!,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * _fadeAnimation.value),
                          child: const CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: _fadeAnimation.value,
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        errorWidget: (context, url, error) {
          print('ImageSliderWidget: CachedNetworkImage error for URL: $url');
          print('ImageSliderWidget: Error: $error');
          // Try fallback to Image.network
          return Image.network(
            cleanUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: widget.height,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget('Failed to load image');
            },
          );
        },
        memCacheWidth: ResponsiveImageUtils.getOptimalCacheDimensions(MediaQuery.of(context).size.width)['memCacheWidth']!,
        memCacheHeight: ResponsiveImageUtils.getOptimalCacheDimensions(MediaQuery.of(context).size.width)['memCacheHeight']!,
        maxWidthDiskCache: ResponsiveImageUtils.getOptimalCacheDimensions(MediaQuery.of(context).size.width)['maxWidthDiskCache']!,
        maxHeightDiskCache: ResponsiveImageUtils.getOptimalCacheDimensions(MediaQuery.of(context).size.width)['maxHeightDiskCache']!,
        fadeInDuration: ResponsiveImageUtils.getOptimalFadeDurations(MediaQuery.of(context).size.width)['fadeInDuration']!,
        fadeOutDuration: ResponsiveImageUtils.getOptimalFadeDurations(MediaQuery.of(context).size.width)['fadeOutDuration']!,
        useOldImageOnUrlChange: true, // Better performance
        imageBuilder: (context, imageProvider) => AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8), // Add subtle rounded corners
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('ImageSliderWidget: CachedNetworkImage exception: $e');
      // Fallback to regular Image.network
      return Image.network(
        cleanUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[300]!,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('ImageSliderWidget: Image.network error for URL: $cleanUrl');
          print('ImageSliderWidget: Error: $error');
          return _buildErrorWidget('Failed to load image');
        },
      );
    }
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to retry',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 10,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
