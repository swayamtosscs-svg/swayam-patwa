import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/live_stream_service.dart';
import 'in_app_viewer_screen.dart';

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _streams = [];
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() {
      _loading = true;
    });
    final result = await LiveStreamService.getStreams();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final List<dynamic> list = data['streams'] ?? [];
      setState(() {
        _streams = list.cast<Map<String, dynamic>>();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to load streams'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      _loading = false;
    });
  }

  void _openInApp(String joinUrl) async {
    // Navigate to dedicated in-app viewer screen instead of WebView
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppViewerScreen(
          stream: _streams.firstWhere((s) => s['id'] == joinUrl.split('room=')[1]),
          userName: 'Viewer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Live'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStreams,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final s = _streams[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        (s['hostName'] ?? 'L')[0].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(s['title'] ?? ''),
                    subtitle: Text('${s['hostName'] ?? ''} • ${s['category'] ?? ''}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InAppViewerScreen(
                            stream: s,
                            userName: 'Viewer',
                          ),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: _streams.length,
              ),
      ),
    );
  }
}
