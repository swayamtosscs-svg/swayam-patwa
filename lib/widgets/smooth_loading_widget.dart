import 'package:flutter/material.dart';

class SmoothLoadingWidget extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool showMessage;
  final Duration animationDuration;

  const SmoothLoadingWidget({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
    this.showMessage = true,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<SmoothLoadingWidget> createState() => _SmoothLoadingWidgetState();
}

class _SmoothLoadingWidgetState extends State<SmoothLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Rotation animation for the spinner
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    // Fade animation for smooth appearance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    // Scale animation for gentle pulsing
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.color ?? Theme.of(context).primaryColor,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            if (widget.showMessage && widget.message != null) ...[
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.message!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SmoothFeedLoader extends StatefulWidget {
  final String? message;
  final bool showStories;
  final bool showPosts;

  const SmoothFeedLoader({
    super.key,
    this.message,
    this.showStories = true,
    this.showPosts = true,
  });

  @override
  State<SmoothFeedLoader> createState() => _SmoothFeedLoaderState();
}

class _SmoothFeedLoaderState extends State<SmoothFeedLoader>
    with TickerProviderStateMixin {
  late AnimationController _storiesController;
  late AnimationController _postsController;
  
  late Animation<double> _storiesAnimation;
  late Animation<double> _postsAnimation;

  @override
  void initState() {
    super.initState();
    
    // Stories loading animation
    _storiesController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _storiesAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _storiesController,
      curve: Curves.easeInOut,
    ));
    
    // Posts loading animation (delayed)
    _postsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _postsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _postsController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delay
    _storiesController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _postsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _storiesController.dispose();
    _postsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _storiesAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(_storiesAnimation),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}

class SmoothRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshMessage;

  const SmoothRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      strokeWidth: 2.5,
      displacement: 40.0,
      child: child,
    );
  }
}
