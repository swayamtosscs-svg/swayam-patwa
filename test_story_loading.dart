import 'package:flutter/material.dart';
import 'lib/services/story_service.dart';
import 'lib/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Test widget to debug story loading issues
class TestStoryLoadingWidget extends StatefulWidget {
  const TestStoryLoadingWidget({Key? key}) : super(key: key);

  @override
  State<TestStoryLoadingWidget> createState() => _TestStoryLoadingWidgetState();
}

class _TestStoryLoadingWidgetState extends State<TestStoryLoadingWidget> {
  List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _testStoryLoading() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('Starting story loading test...');
      
      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _addLog('Auth provider loaded: ${authProvider != null}');
      
      if (authProvider == null) {
        _addLog('ERROR: AuthProvider is null');
        return;
      }

      final token = authProvider.authToken;
      final userProfile = authProvider.userProfile;
      
      _addLog('Token available: ${token != null}');
      _addLog('User profile available: ${userProfile != null}');
      
      if (token == null) {
        _addLog('ERROR: No auth token found');
        return;
      }
      
      if (userProfile == null) {
        _addLog('ERROR: No user profile found');
        return;
      }

      _addLog('User ID: ${userProfile.id}');
      _addLog('User name: ${userProfile.fullName}');
      _addLog('Token length: ${token.length}');
      _addLog('Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      _addLog('Calling StoryService.getUserStories...');
      final stories = await StoryService.getUserStories(
        userProfile.id,
        token: token,
        page: 1,
        limit: 10,
      );

      _addLog('Stories loaded: ${stories.length}');
      
      for (int i = 0; i < stories.length; i++) {
        final story = stories[i];
        _addLog('Story $i: ${story.id} - ${story.type} - ${story.media}');
      }

      if (stories.isEmpty) {
        _addLog('WARNING: No stories found for user');
        _addLog('This might be why highlights are not showing stories');
      } else {
        _addLog('SUCCESS: Found ${stories.length} stories');
      }

    } catch (e) {
      _addLog('ERROR: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Loading Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testStoryLoading,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test Story Loading'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log.contains('ERROR');
                final isWarning = log.contains('WARNING');
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: isError ? Colors.red : (isWarning ? Colors.orange : Colors.black),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Test app to run the story loading test
class TestStoryLoadingApp extends StatelessWidget {
  const TestStoryLoadingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Loading Test',
      home: const TestStoryLoadingWidget(),
    );
  }
}

void main() {
  runApp(const TestStoryLoadingApp());
}
