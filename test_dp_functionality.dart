import 'dart:io';
import 'package:flutter/material.dart';
import '../services/dp_service.dart';

class TestDPFunctionality extends StatefulWidget {
  const TestDPFunctionality({Key? key}) : super(key: key);

  @override
  State<TestDPFunctionality> createState() => _TestDPFunctionalityState();
}

class _TestDPFunctionalityState extends State<TestDPFunctionality> {
  String? _testUserId = '68e8ecfe819e345addde2deb';
  String? _testToken = 'YOUR_TEST_TOKEN_HERE'; // Replace with actual token
  String? _currentDPUrl;
  String? _currentFileName;
  String? _currentFilePath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DP Functionality Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DP Upload and Deletion Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Current DP Info
            if (_currentDPUrl != null) ...[
              const Text('Current DP:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('URL: $_currentDPUrl'),
              Text('File Name: $_currentFileName'),
              Text('File Path: $_currentFilePath'),
              const SizedBox(height: 20),
            ],
            
            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testRetrieveDP,
              child: const Text('Test Retrieve DP'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testDeleteDP,
              child: const Text('Test Delete DP'),
            ),
            const SizedBox(height: 10),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Future<void> _testRetrieveDP() async {
    if (_testUserId == null || _testToken == null) {
      _showSnackBar('Please set test user ID and token', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DPService.retrieveDP(
        userId: _testUserId!,
        token: _testToken!,
      );

      print('Test Retrieve DP Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _currentDPUrl = data['dpUrl'];
          _currentFileName = data['fileName'];
          _currentFilePath = data['publicUrl'];
          _isLoading = false;
        });
        _showSnackBar('DP Retrieved Successfully', Colors.green);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to retrieve DP: ${response['message']}', Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error retrieving DP: $e', Colors.red);
    }
  }

  Future<void> _testDeleteDP() async {
    if (_testUserId == null || _testToken == null) {
      _showSnackBar('Please set test user ID and token', Colors.red);
      return;
    }

    if (_currentFileName == null) {
      _showSnackBar('No DP to delete. Please retrieve DP first.', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DPService.deleteDP(
        userId: _testUserId!,
        fileName: _currentFileName!,
        token: _testToken!,
        filePath: _currentFilePath, // Pass the filePath parameter
      );

      print('Test Delete DP Response: $response');

      if (response['success'] == true) {
        setState(() {
          _currentDPUrl = null;
          _currentFileName = null;
          _currentFilePath = null;
          _isLoading = false;
        });
        _showSnackBar('DP Deleted Successfully', Colors.green);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to delete DP: ${response['message']}', Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error deleting DP: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
