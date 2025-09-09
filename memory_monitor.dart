import 'dart:async';
import 'package:flutter/material.dart';
import 'lib/services/memory_optimization_service.dart';

/// Simple memory monitoring widget for development
class MemoryMonitor extends StatefulWidget {
  const MemoryMonitor({super.key});

  @override
  State<MemoryMonitor> createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor> {
  Timer? _timer;
  Map<String, dynamic> _memoryStats = {};
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _memoryStats = MemoryOptimizationService.getMemoryStats();
        });
      }
    });
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void _clearCaches() {
    MemoryOptimizationService.clearAllCaches();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All caches cleared')),
    );
  }

  void _toggleLowMemoryMode() {
    if (_memoryStats['isLowMemoryMode'] == true) {
      MemoryOptimizationService.disableLowMemoryMode();
    } else {
      MemoryOptimizationService.enableLowMemoryMode();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Low memory mode ${_memoryStats['isLowMemoryMode'] == true ? 'disabled' : 'enabled'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return Positioned(
        top: 50,
        right: 20,
        child: FloatingActionButton.small(
          onPressed: _toggleVisibility,
          child: const Icon(Icons.memory),
        ),
      );
    }

    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Memory Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleVisibility,
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Flutter Cache', '${_memoryStats['flutterImageCacheSize'] ?? 0}/${_memoryStats['flutterImageCacheMaxSize'] ?? 0}'),
            _buildStatRow('Custom Cache', '${_memoryStats['customImageCacheSize'] ?? 0}/${_memoryStats['customImageCacheMaxSize'] ?? 0}'),
            _buildStatRow('Low Memory Mode', _memoryStats['isLowMemoryMode'] == true ? 'Enabled' : 'Disabled'),
            if (_memoryStats['lastCleanup'] != null)
              _buildStatRow('Last Cleanup', _formatTime(_memoryStats['lastCleanup'])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearCaches,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Clear Caches', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleLowMemoryMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _memoryStats['isLowMemoryMode'] == true ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      _memoryStats['isLowMemoryMode'] == true ? 'Disable LMM' : 'Enable LMM',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return 'Never';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Invalid';
    }
  }
}

/// Add this widget to your app for development memory monitoring
/// Usage: Add MemoryMonitor() to your main screen's Stack
/// Example:
/// Stack(
///   children: [
///     YourMainContent(),
///     if (kDebugMode) const MemoryMonitor(),
///   ],
/// )
