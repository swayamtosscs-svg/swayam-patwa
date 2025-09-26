import 'dart:async';
import 'package:flutter/foundation.dart';

class PerformanceTest {
  static Future<Map<String, dynamic>> testFeedRefresh({
    required Future<void> Function() refreshFunction,
    required String testName,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await refreshFunction();
      stopwatch.stop();
      
      final result = {
        'testName': testName,
        'success': true,
        'duration': stopwatch.elapsedMilliseconds,
        'durationFormatted': '${stopwatch.elapsedMilliseconds}ms',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (kDebugMode) {
        print('Performance Test [$testName]: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      final result = {
        'testName': testName,
        'success': false,
        'duration': stopwatch.elapsedMilliseconds,
        'durationFormatted': '${stopwatch.elapsedMilliseconds}ms (ERROR)',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (kDebugMode) {
        print('Performance Test [$testName]: ERROR - ${stopwatch.elapsedMilliseconds}ms - $e');
      }
      
      return result;
    }
  }
  
  static Future<List<Map<String, dynamic>>> runFeedPerformanceTests({
    required Future<void> Function() optimizedRefresh,
    required Future<void> Function() standardRefresh,
  }) async {
    final results = <Map<String, dynamic>>[];
    
    // Test optimized refresh
    final optimizedResult = await testFeedRefresh(
      refreshFunction: optimizedRefresh,
      testName: 'Optimized Feed Refresh',
    );
    results.add(optimizedResult);
    
    // Wait a bit between tests
    await Future.delayed(const Duration(seconds: 1));
    
    // Test standard refresh
    final standardResult = await testFeedRefresh(
      refreshFunction: standardRefresh,
      testName: 'Standard Feed Refresh',
    );
    results.add(standardResult);
    
    // Calculate improvement
    if (optimizedResult['success'] == true && standardResult['success'] == true) {
      final optimizedTime = optimizedResult['duration'] as int;
      final standardTime = standardResult['duration'] as int;
      final improvement = ((standardTime - optimizedTime) / standardTime * 100).round();
      
      results.add({
        'testName': 'Performance Improvement',
        'success': true,
        'improvement': improvement,
        'improvementFormatted': '$improvement% faster',
        'optimizedTime': optimizedTime,
        'standardTime': standardTime,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('Performance Improvement: $improvement% faster');
        print('Optimized: ${optimizedTime}ms vs Standard: ${standardTime}ms');
      }
    }
    
    return results;
  }
  
  static void printPerformanceReport(List<Map<String, dynamic>> results) {
    if (kDebugMode) {
      print('\n=== FEED REFRESH PERFORMANCE REPORT ===');
      for (final result in results) {
        print('${result['testName']}: ${result['durationFormatted'] ?? result['improvementFormatted']}');
        if (result['error'] != null) {
          print('  Error: ${result['error']}');
        }
      }
      print('=====================================\n');
    }
  }
}
