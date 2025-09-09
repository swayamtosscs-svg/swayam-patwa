import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class CloudinaryImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCache;

  const CloudinaryImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCache = true,
  });

  @override
  State<CloudinaryImageWidget> createState() => _CloudinaryImageWidgetState();
}

class _CloudinaryImageWidgetState extends State<CloudinaryImageWidget> {
  Uint8List? _cachedImage;
  bool _isLoading = true;
  bool _hasError = false;
  static final Map<String, Uint8List> _imageCache = {};
  static const int _maxCacheSize = 50; // Limit cache to 50 images

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CloudinaryImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.enableCache && _imageCache.containsKey(widget.imageUrl)) {
      setState(() {
        _cachedImage = _imageCache[widget.imageUrl];
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageBytes = await _loadCloudinaryImage(widget.imageUrl);
      if (imageBytes != null && mounted) {
        setState(() {
          _cachedImage = imageBytes;
          _isLoading = false;
        });
        
        // Cache the image if enabled
        if (widget.enableCache) {
          _addToCache(widget.imageUrl, imageBytes);
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _addToCache(String key, Uint8List bytes) {
    // Implement LRU cache to prevent memory overflow
    if (_imageCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _imageCache.keys.first;
      _imageCache.remove(oldestKey);
    }
    _imageCache[key] = bytes;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }
    
    if (_hasError || _cachedImage == null) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
    
    return Image.memory(
      _cachedImage!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        print('CloudinaryImageWidget: Error displaying image: $error');
        return widget.errorWidget ?? _buildDefaultErrorWidget();
      },
    );
  }

  /// Load Cloudinary image with SSL bypass for Windows and memory optimization
  Future<Uint8List?> _loadCloudinaryImage(String imageUrl) async {
    try {
      print('CloudinaryImageWidget: Loading image from: $imageUrl');
      
      // Create HTTP client with SSL bypass for Windows
      final client = _createHttpClient();
      
      final request = await client.getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        print('CloudinaryImageWidget: Image loaded successfully');
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      } else {
        print('CloudinaryImageWidget: Failed to load image. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('CloudinaryImageWidget: Error loading image: $e');
      return null;
    }
  }

  /// Create HTTP client with SSL bypass for Windows
  HttpClient _createHttpClient() {
    final client = HttpClient();
    
    if (Platform.isWindows) {
      // On Windows, bypass SSL certificate verification for development
      client.badCertificateCallback = (cert, host, port) {
        print('CloudinaryImageWidget: Bypassing SSL certificate for $host:$port');
        return true; // Accept all certificates
      };
    }
    
    return client;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width ?? 70,
      height: widget.height ?? 70,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(widget.width != null ? widget.width! / 2 : 35),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width ?? 70,
      height: widget.height ?? 70,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(widget.width != null ? widget.width! / 2 : 35),
      ),
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Color(0xFF666666),
          size: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clear this widget's cached image to free memory
    if (_cachedImage != null && !widget.enableCache) {
      _cachedImage = null;
    }
    super.dispose();
  }

  /// Static method to clear all cached images (call this when memory is low)
  static void clearCache() {
    _imageCache.clear();
  }

  /// Static method to get cache size
  static int get cacheSize => _imageCache.length;
}
