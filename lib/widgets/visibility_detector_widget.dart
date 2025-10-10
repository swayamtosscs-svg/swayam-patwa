import 'package:flutter/material.dart';
import 'dart:async';

class VisibilityDetectorWidget extends StatefulWidget {
  final Widget child;
  final String videoKey;
  final Function(bool isVisible)? onVisibilityChanged;
  final double visibilityThreshold;

  const VisibilityDetectorWidget({
    super.key,
    required this.child,
    required this.videoKey,
    this.onVisibilityChanged,
    this.visibilityThreshold = 0.5, // 50% visibility threshold
  });

  @override
  State<VisibilityDetectorWidget> createState() => _VisibilityDetectorWidgetState();
}

class _VisibilityDetectorWidgetState extends State<VisibilityDetectorWidget> {
  final GlobalKey _key = GlobalKey();
  bool _isVisible = false;
  bool _hasBeenVisible = false;
  Timer? _visibilityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void didUpdateWidget(VisibilityDetectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoKey != widget.videoKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVisibility();
      });
    }
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted) return;
    
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate visible area
    final visibleTop = position.dy.clamp(0, screenHeight);
    final visibleBottom = (position.dy + size.height).clamp(0, screenHeight);
    final visibleLeft = position.dx.clamp(0, screenWidth);
    final visibleRight = (position.dx + size.width).clamp(0, screenWidth);
    
    final visibleHeight = visibleBottom - visibleTop;
    final visibleWidth = visibleRight - visibleLeft;
    
    // Calculate visibility percentage based on area
    final totalArea = size.height * size.width;
    final visibleArea = visibleHeight * visibleWidth;
    final visibilityPercentage = totalArea > 0 ? visibleArea / totalArea : 0;
    
    final isVisible = visibilityPercentage >= widget.visibilityThreshold;
    
    // Debounce visibility changes to avoid rapid state changes
    if (isVisible != _isVisible) {
      _visibilityTimer?.cancel();
      _visibilityTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isVisible = isVisible;
            _hasBeenVisible = _hasBeenVisible || isVisible;
          });
          
          widget.onVisibilityChanged?.call(isVisible);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Handle different types of scroll notifications
        if (notification is ScrollUpdateNotification || 
            notification is ScrollEndNotification ||
            notification is ScrollStartNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkVisibility();
          });
        }
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Handle PageView scroll notifications (PageView uses ScrollNotification internally)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkVisibility();
          });
          return false;
        },
        child: Container(
          key: _key,
          child: widget.child,
        ),
      ),
    );
  }
}
