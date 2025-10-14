import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

/// Debug test to check follow status API response
/// This helps identify if the issue is with the API or the UI logic
class FollowStatusDebugTest extends StatefulWidget {
  final String targetUserId;
  final String targetUsername;

  const FollowStatusDebugTest({
    super.key,
    required this.targetUserId,
    required this.targetUsername,
  });

  @override
  State<FollowStatusDebugTest> createState() => _FollowStatusDebugTestState();
}

class _FollowStatusDebugTestState extends State<FollowStatusDebugTest> {
  bool _isLoading = false;
  Map<String, dynamic>? _apiResponse;
  bool? _isFollowingFromAPI;
  bool? _isFollowingFromAuthProvider;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Status Debug'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debugging follow status for: ${widget.targetUsername}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('User ID: ${widget.targetUserId}'),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testFollowStatus,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Test Follow Status'),
            ),
            
            const SizedBox(height: 20),
            
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            if (_apiResponse != null) ...[
              const Text(
                'API Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _apiResponse.toString(),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            if (_isFollowingFromAPI != null) ...[
              Row(
                children: [
                  const Text('API says following: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isFollowingFromAPI! ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isFollowingFromAPI!.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            
            if (_isFollowingFromAuthProvider != null) ...[
              Row(
                children: [
                  const Text('AuthProvider says following: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isFollowingFromAuthProvider! ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isFollowingFromAuthProvider!.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            
            if (_isFollowingFromAPI != null && _isFollowingFromAuthProvider != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isFollowingFromAPI == _isFollowingFromAuthProvider) 
                    ? Colors.green[50] 
                    : Colors.orange[50],
                  border: Border.all(
                    color: (_isFollowingFromAPI == _isFollowingFromAuthProvider) 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (_isFollowingFromAPI == _isFollowingFromAuthProvider)
                    ? '✅ API and AuthProvider responses match!'
                    : '⚠️ API and AuthProvider responses differ!',
                  style: TextStyle(
                    color: (_isFollowingFromAPI == _isFollowingFromAuthProvider) 
                      ? Colors.green[800] 
                      : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            const Text(
              'Expected Button States:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• If following = true: Button shows "Following"'),
                  Text('• If following = false: Button shows "Follow"'),
                  Text('• If requested = true: Button shows "Requested"'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFollowStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _apiResponse = null;
      _isFollowingFromAPI = null;
      _isFollowingFromAuthProvider = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        setState(() {
          _errorMessage = 'No auth token found';
          _isLoading = false;
        });
        return;
      }

      print('Testing follow status for user: ${widget.targetUserId}');
      
      // Test 1: Direct API call
      print('1. Testing direct API call...');
      final apiResponse = await ApiService.checkRGramFollowStatus(
        targetUserId: widget.targetUserId,
        token: token,
      );
      
      print('API Response: $apiResponse');
      
      bool? apiFollowingStatus;
      if (apiResponse['success'] == true && apiResponse['data'] != null) {
        apiFollowingStatus = apiResponse['data']['isFollowing'] ?? false;
      }
      
      // Test 2: AuthProvider method
      print('2. Testing AuthProvider method...');
      final authProviderFollowing = await authProvider.isFollowingUser(widget.targetUserId);
      print('AuthProvider result: $authProviderFollowing');
      
      setState(() {
        _apiResponse = apiResponse;
        _isFollowingFromAPI = apiFollowingStatus;
        _isFollowingFromAuthProvider = authProviderFollowing;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error testing follow status: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}

/// Helper function to show the debug test
void showFollowStatusDebug(BuildContext context, String targetUserId, String targetUsername) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FollowStatusDebugTest(
        targetUserId: targetUserId,
        targetUsername: targetUsername,
      ),
    ),
  );
}
