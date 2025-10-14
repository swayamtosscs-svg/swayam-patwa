import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/auth_provider.dart';
import 'lib/services/highlight_service.dart';
import 'lib/models/highlight_model.dart';

void main() {
  runApp(const HighlightsTestApp());
}

class HighlightsTestApp extends StatelessWidget {
  const HighlightsTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Highlights Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HighlightsTestScreen(),
    );
  }
}

class HighlightsTestScreen extends StatefulWidget {
  const HighlightsTestScreen({Key? key}) : super(key: key);

  @override
  State<HighlightsTestScreen> createState() => _HighlightsTestScreenState();
}

class _HighlightsTestScreenState extends State<HighlightsTestScreen> {
  List<Highlight> _highlights = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // You'll need to replace this with a valid token
      const String testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGM5MTIwOWE5MjFhMDAxZGE5NzdjMDIiLCJpYXQiOjE3NjAwMDcxNDMsImV4cCI6MTc2MjU5OTE0M30.yD8-6FOqR5K1Y-g15SxFe3KxHWOxITpFC-6ll64THAU';
      
      print('Testing highlights API...');
      final response = await HighlightService.getHighlights(
        token: testToken,
        page: 1,
        limit: 10,
      );

      print('Highlights response: ${response.success}');
      print('Highlights count: ${response.highlights.length}');
      print('Highlights message: ${response.message}');

      if (response.success) {
        setState(() {
          _highlights = response.highlights;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading highlights: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlights Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHighlights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHighlights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _highlights.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_border, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No highlights found'),
                          Text('Create your first highlight!'),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Found ${_highlights.length} highlights',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _highlights.length,
                            itemBuilder: (context, index) {
                              final highlight = _highlights[index];
                              return Card(
                                margin: const EdgeInsets.all(8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      highlight.name.isNotEmpty 
                                          ? highlight.name[0].toUpperCase()
                                          : 'H',
                                    ),
                                  ),
                                  title: Text(highlight.name),
                                  subtitle: Text(highlight.description),
                                  trailing: Text('${highlight.storiesCount} stories'),
                                  onTap: () {
                                    print('Highlight tapped: ${highlight.name}');
                                  },
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


