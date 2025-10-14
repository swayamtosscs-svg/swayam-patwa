import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class CustomHttpClient {
  static http.Client? _client;
  static const int _maxConnections = 15; // Further increased for better concurrency
  static const Duration _connectionTimeout = Duration(seconds: 3); // Further reduced timeout
  static const Duration _idleTimeout = Duration(seconds: 10); // Further reduced idle timeout
  static const Duration _receiveTimeout = Duration(seconds: 5); // Further reduced receive timeout
  
  // Request deduplication to prevent duplicate requests
  static final Map<String, Future<http.Response>> _activeRequests = {};
  
  /// Get a custom HTTP client that handles SSL issues with memory optimization
  static http.Client get client {
    _client ??= _createClient();
    return _client!;
  }
  
  /// Create a custom HTTP client with SSL bypass for development and memory optimization
  static http.Client _createClient() {
    if (Platform.isWindows) {
      // On Windows, create a client that can handle SSL issues
      print('CustomHttpClient: Creating optimized client for Windows platform');
      
      // Create HttpClient with SSL bypass for development
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('CustomHttpClient: Bypassing SSL certificate verification for $host:$port');
        return true; // Accept all certificates for development
      };
      
      // Set optimized timeouts and connection limits
      httpClient.connectionTimeout = _connectionTimeout;
      httpClient.idleTimeout = _idleTimeout;
      httpClient.maxConnectionsPerHost = _maxConnections;
      
      // Enable connection pooling for better performance
      httpClient.autoUncompress = true;
      
      return IOClient(httpClient);
    } else {
      // On other platforms, use default client with optimizations
      return http.Client();
    }
  }
  
  /// Dispose the custom client to free memory
  static void dispose() {
    _client?.close();
    _client = null;
  }
  
  /// Make a GET request with custom headers, memory optimization, and request deduplication
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    // Create request key for deduplication
    final requestKey = 'GET_${url.toString()}_${headers?.toString() ?? ''}';
    
    // Check if same request is already in progress
    if (_activeRequests.containsKey(requestKey)) {
      print('CustomHttpClient: Request already in progress, waiting for result');
      return await _activeRequests[requestKey]!;
    }
    
    try {
      // Create future for this request
      final future = client.get(url, headers: headers);
      _activeRequests[requestKey] = future;
      
      final response = await future;
      _activeRequests.remove(requestKey);
      return response;
    } catch (e) {
      _activeRequests.remove(requestKey);
      print('CustomHttpClient: GET request failed: $e');
      rethrow;
    }
  }
  
  /// Make a POST request with custom headers and body, with memory optimization
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await client.post(url, headers: headers, body: body);
      return response;
    } catch (e) {
      print('CustomHttpClient: POST request failed: $e');
      rethrow;
    }
  }
  
  /// Clear any cached connections and active requests to free memory
  static void clearCache() {
    // Clear active requests
    _activeRequests.clear();
    // Force recreation of client to clear any cached connections
    dispose();
    print('CustomHttpClient: Cache and active requests cleared');
  }
}
