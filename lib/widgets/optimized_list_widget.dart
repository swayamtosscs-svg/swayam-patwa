import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final Widget? separatorBuilder;
  final double? itemExtent;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.itemCount,
    this.itemBuilder,
    this.separatorBuilder,
    this.itemExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) {
      return ListView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const BouncingScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder!,
        itemExtent: itemExtent,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        // Performance optimizations
        cacheExtent: 250, // Reduced cache extent for better memory usage
      );
    }

    return ListView(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      children: children,
      // Performance optimizations
      cacheExtent: 250,
    );
  }
}

class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;

  const OptimizedGridView({
    super.key,
    required this.children,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.itemCount,
    this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
  });

  @override
  Widget build(BuildContext context) {
    if (itemBuilder != null) {
      return GridView.builder(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics ?? const BouncingScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder!,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        // Performance optimizations
        cacheExtent: 250,
      );
    }

    return GridView.count(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      children: children,
      // Performance optimizations
      cacheExtent: 250,
    );
  }
}

/// Optimized lazy loading widget for better performance
class OptimizedLazyLoadingWidget extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final double threshold;

  const OptimizedLazyLoadingWidget({
    super.key,
    required this.child,
    this.loadingWidget,
    required this.onLoadMore,
    this.hasMore = true,
    this.threshold = 0.8,
  });

  @override
  State<OptimizedLazyLoadingWidget> createState() => _OptimizedLazyLoadingWidgetState();
}

class _OptimizedLazyLoadingWidgetState extends State<OptimizedLazyLoadingWidget> {
  bool _isLoading = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * widget.threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !widget.hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onLoadMore();
    } catch (e) {
      if (kDebugMode) {
        print('OptimizedLazyLoadingWidget: Error loading more: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        if (_isLoading && widget.hasMore)
          widget.loadingWidget ?? 
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
}

/// Optimized refresh indicator for better performance
class OptimizedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const OptimizedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor ?? Colors.white,
      strokeWidth: 2.0,
      displacement: 40.0,
      child: child,
    );
  }
}
