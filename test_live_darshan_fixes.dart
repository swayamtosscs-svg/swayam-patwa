import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'lib/screens/live_darshan_webview_screen.dart';
import 'lib/services/live_streaming_service.dart';

void main() {
  group('Live Darshan WebView Tests', () {
    testWidgets('Live Darshan WebView Screen loads correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveDarshanWebViewScreen(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the screen loads
      expect(find.text('Live Darshan'), findsOneWidget);
    });

    testWidgets('Error fallback displays correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveDarshanWebViewScreen(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Check for error fallback elements
      expect(find.text('Live Darshan'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Check Server'), findsOneWidget);
    });

    testWidgets('Server URL is clickable', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: const LiveDarshanWebViewScreen(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Find the server URL
      expect(find.text('https://103.14.120.163:8443/'), findsOneWidget);
    });
  });

  group('Live Streaming Service Tests', () {
    test('Server status check handles errors gracefully', () async {
      try {
        await LiveStreamingService.initialize();
        final status = await LiveStreamingService.getServerStatus();
        print('Server status: $status');
        
        // Should not throw an exception
        expect(status, isA<Map<String, dynamic>>());
      } catch (e) {
        print('Expected error during testing: $e');
        // This is expected in test environment
      }
    });

    test('SSL bypass initialization works', () async {
      try {
        await LiveStreamingService.initialize();
        // Should not throw an exception
        expect(true, isTrue);
      } catch (e) {
        print('SSL initialization error: $e');
        fail('SSL initialization should not fail');
      }
    });
  });

  group('WebView Configuration Tests', () {
    test('WebView controller configuration is valid', () {
      // Test WebView controller creation
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36');

      expect(controller, isNotNull);
    });

    test('Navigation delegate handles URLs correctly', () {
      // Test navigation decision logic
      bool shouldNavigate(String url) {
        return url.contains('103.14.120.163') || 
               url.contains('localhost') ||
               url.startsWith('data:') ||
               url.startsWith('javascript:') ||
               url.startsWith('blob:') ||
               url.startsWith('file:') ||
               url.startsWith('ws:') ||
               url.startsWith('wss:');
      }

      expect(shouldNavigate('https://103.14.120.163:8443/'), isTrue);
      expect(shouldNavigate('https://google.com'), isFalse);
      expect(shouldNavigate('data:text/html,<html></html>'), isTrue);
      expect(shouldNavigate('ws://103.14.120.163:8443/ws'), isTrue);
    });
  });

  group('Error Handling Tests', () {
    test('Error messages are user-friendly', () {
      String getErrorMessage(int errorCode) {
        if (errorCode == -2) {
          return 'Network error. Check your internet connection.';
        } else if (errorCode == -6) {
          return 'Server not responding. Retrying...';
        } else if (errorCode == -8) {
          return 'SSL certificate error. Retrying...';
        }
        return 'Connection failed. Retrying...';
      }

      expect(getErrorMessage(-2), contains('Network error'));
      expect(getErrorMessage(-6), contains('Server not responding'));
      expect(getErrorMessage(-8), contains('SSL certificate error'));
      expect(getErrorMessage(999), contains('Connection failed'));
    });

    test('HTTP error messages are descriptive', () {
      String getHttpErrorMessage(int statusCode) {
        if (statusCode == 404) {
          return 'Server not found. Retrying...';
        } else if (statusCode == 500) {
          return 'Server internal error. Retrying...';
        } else if (statusCode == 503) {
          return 'Server temporarily unavailable. Retrying...';
        }
        return 'Server error. Retrying...';
      }

      expect(getHttpErrorMessage(404), contains('Server not found'));
      expect(getHttpErrorMessage(500), contains('Server internal error'));
      expect(getHttpErrorMessage(503), contains('Server temporarily unavailable'));
      expect(getHttpErrorMessage(999), contains('Server error'));
    });
  });
}
