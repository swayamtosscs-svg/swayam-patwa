import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerformanceService {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _performanceMetrics = {};
  static bool _isEnabled = kDebugMode;
  
  /// Start timing a performance operation
  static void startTimer(String operation) {
    if (!_isEnabled) return;
    
    _timers[operation] = Stopwatch()..start();
    if (kDebugMode) {
      print('PerformanceService: Started timer for $operation');
    }
  }
  
  /// End timing and record the duration
  static void endTimer(String operation) {
    if (!_isEnabled) return;
    
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      _performanceMetrics.putIfAbsent(operation, () => []);
      _performanceMetrics[operation]!.add(duration);
      
      if (kDebugMode) {
        print('PerformanceService: $operation took ${duration}ms');
      }
      
      _timers.remove(operation);
    }
  }
  
  /// Measure the execution time of a function
  static Future<T> measureAsync<T>(String operation, Future<T> Function() function) async {
    startTimer(operation);
    try {
      final result = await function();
      endTimer(operation);
      return result;
    } catch (e) {
      endTimer(operation);
      rethrow;
    }
  }
  
  /// Measure the execution time of a synchronous function
  static T measure<T>(String operation, T Function() function) {
    startTimer(operation);
    try {
      final result = function();
      endTimer(operation);
      return result;
    } catch (e) {
      endTimer(operation);
      rethrow;
    }
  }
  
  /// Get performance statistics for an operation
  static Map<String, dynamic> getStats(String operation) {
    final metrics = _performanceMetrics[operation];
    if (metrics == null || metrics.isEmpty) {
      return {'operation': operation, 'count': 0};
    }
    
    metrics.sort();
    final count = metrics.length;
    final min = metrics.first;
    final max = metrics.last;
    final avg = metrics.reduce((a, b) => a + b) / count;
    final median = count % 2 == 0 
        ? (metrics[count ~/ 2 - 1] + metrics[count ~/ 2]) / 2
        : metrics[count ~/ 2].toDouble();
    
    return {
      'operation': operation,
      'count': count,
      'min': min,
      'max': max,
      'avg': avg.round(),
      'median': median.round(),
    };
  }
  
  /// Get all performance statistics
  static Map<String, Map<String, dynamic>> getAllStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final operation in _performanceMetrics.keys) {
      stats[operation] = getStats(operation);
    }
    return stats;
  }
  
  /// Clear all performance data
  static void clearStats() {
    _timers.clear();
    _performanceMetrics.clear();
    if (kDebugMode) {
      print('PerformanceService: Cleared all performance data');
    }
  }
  
  /// Enable or disable performance monitoring
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (kDebugMode) {
      print('PerformanceService: Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Check if performance monitoring is enabled
  static bool get isEnabled => _isEnabled;
  
  /// Monitor memory usage
  static void logMemoryUsage(String context) {
    if (!_isEnabled) return;
    
    // This is a simplified memory monitoring
    // In a real app, you might want to use more sophisticated memory monitoring
    if (kDebugMode) {
      print('PerformanceService: Memory check at $context');
    }
  }
  
  /// Monitor frame rendering performance
  static void monitorFrameRate(String context) {
    if (!_isEnabled) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print('PerformanceService: Frame rendered at $context');
      }
    });
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? operationName;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
    this.operationName,
  });
  
  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  @override
  void initState() {
    super.initState();
    if (widget.operationName != null) {
      PerformanceService.startTimer(widget.operationName!);
    }
  }
  
  @override
  void dispose() {
    if (widget.operationName != null) {
      PerformanceService.endTimer(widget.operationName!);
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Performance overlay for debugging
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  
  const PerformanceOverlay({
    super.key,
    required this.child,
  });
  
  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  Map<String, Map<String, dynamic>> _stats = {};
  
  @override
  void initState() {
    super.initState();
    _updateStats();
    
    // Update stats every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateStats();
      } else {
        timer.cancel();
      }
    });
  }
  
  void _updateStats() {
    setState(() {
      _stats = PerformanceService.getAllStats();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || _stats.isEmpty) {
      return widget.child;
    }
    
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Performance Stats',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ..._stats.entries.map((entry) {
                  final stats = entry.value;
                  return Text(
                    '${entry.key}: ${stats['avg']}ms avg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
