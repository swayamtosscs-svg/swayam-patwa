import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class _ImageSliderWidgetState extends State<ImageSliderWidget> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Register this slider as the current one
    ImageSliderController.setCurrentSlider(this);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        fit: BoxFit.cover, // Changed from fitWidth to cover to prevent stretching
        width: double.infinity,
        height: widget.height, // Use the provided height
        placeholder: (context, url) => Container(
          height: widget.height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('ImageSliderWidget: CachedNetworkImage error for URL: $url');
          print('ImageSliderWidget: Error: $error');
          // Try fallback to Image.network
          return Image.network(
            cleanUrl,
            fit: BoxFit.cover, // Changed from fitWidth to cover
            width: double.infinity,
            height: widget.height,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget('Failed to load image');
            },
          );
        },
        memCacheWidth: 800, // Optimize memory usage
        memCacheHeight: 600,
      );
    } catch (e) {
      print('ImageSliderWidget: CachedNetworkImage exception: $e');
      // Fallback to regular Image.network
      return Image.network(
        cleanUrl,
        fit: BoxFit.cover, // Changed from fitWidth to cover
        width: double.infinity,
        height: widget.height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: widget.height,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.blue,
                strokeWidth: 2,
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
      color: Colors.grey[200],
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
          ],
        ),
      ),
    );
  }
}
