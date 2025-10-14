import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Conditional imports for web
import 'cross_platform_webview_web.dart' if (dart.library.io) 'cross_platform_webview_stub.dart';

class CrossPlatformWebView extends StatefulWidget {
  final String url;
  final bool showLoadingIndicator;
  
  const CrossPlatformWebView({
    super.key, 
    required this.url,
    this.showLoadingIndicator = true,
  });

  @override
  State<CrossPlatformWebView> createState() => _CrossPlatformWebViewState();
}

class _CrossPlatformWebViewState extends State<CrossPlatformWebView> {
  WebViewController? _webViewController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      // Temporarily use fallback for Windows
      _initWindowsFallback();
    } else if (kIsWeb) {
      _initWebIframe();
    }
  }

  Future<void> _initWindowsFallback() async {
    try {
      // Initialize WebView for Windows using webview_flutter
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
              if (mounted) {
                setState(() {
                  _isInitialized = true;
                  _hasError = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Failed to load stream: ${error.description}';
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('CrossPlatformWebView: Windows WebView initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize WebView: $e';
        });
      }
    }
  }

  void _initWebIframe() {
    try {
      // For web, we'll use a simple approach without the web package
      // The iframe will be handled by the HtmlElementView in the build method
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('CrossPlatformWebView: Web iframe initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'WebView Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                    _isInitialized = false;
                  });
                  if (!kIsWeb && Platform.isWindows) {
                    _initWindowsFallback();
                  } else if (kIsWeb) {
                    _initWebIframe();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized && widget.showLoadingIndicator) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading stream...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      // 🟢 Web platform: use simple iframe approach
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'Live Stream',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stream URL: ${widget.url}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // On web, open stream in new tab
                  // This will be handled by url_launcher
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Stream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (Platform.isWindows) {
      // 🟢 Windows platform: use webview_flutter
      return Container(
        color: Colors.black,
        child: _isInitialized && _webViewController != null
            ? WebViewWidget(controller: _webViewController!)
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'WebView Error',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _initWindowsFallback();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await launchUrl(
                                Uri.parse(widget.url),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              print('Error opening URL: $e');
                            }
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Open in Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading live stream...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
      );
    } else {
      // For mobile platforms - fallback to text
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "WebView not supported on this platform",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }
}
