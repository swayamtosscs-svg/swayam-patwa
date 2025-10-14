import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/live_stream_service.dart';
import '../services/camera_service.dart';
import 'native_stream_host_screen.dart';

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController(text: 'My Live Stream');
  final TextEditingController _hostNameController = TextEditingController(text: 'Host');
  final TextEditingController _descriptionController = TextEditingController(text: 'Live stream');
  String? _hostUrl;
  String? _joinUrl;
  String? _roomId;
  String? _streamKey;
  bool _cameraReady = false;
  Map<String, dynamic>? _status;
  WebViewController? _webViewController;

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LiveStreamService.createLiveRoom(
        title: _titleController.text.trim().isEmpty ? 'My Live Stream' : _titleController.text.trim(),
        hostName: _hostNameController.text.trim().isEmpty ? 'Host' : _hostNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: 'General',
        tags: const ['live', 'stream'],
        isPrivate: false,
        maxViewers: 100,
        allowChat: true,
        allowViewerSpeak: false,
        thumbnail: 'https://example.com/thumbnail.jpg',
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        setState(() {
          _hostUrl = data['hostUrl'];
          _joinUrl = data['joinUrl'];
          _roomId = data['roomId'];
          _streamKey = data['streamKey'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Room created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create room'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openHostPage() async {
    final target = _hostUrl ?? 'https://new-live-api.onrender.com/host.html';
    try {
      if (kIsWeb) {
        // Web: fallback to open in same tab
        final uri = Uri.parse(target);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_self');
        } else {
          throw 'Cannot launch host URL';
        }
        return;
      }
      _webViewController ??= WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
      _webViewController!.loadRequest(Uri.parse(target));
      // Show as in-app bottom sheet
      // If WebView unavailable on platform, fall back to launcher
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        builder: (_) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback to external open if WebView not supported
      final Uri url = Uri.parse(target);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open host page: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _startLiveStream() async {
    if (_roomId == null || _streamKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a room first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure camera & mic permissions and start camera (skip on web)
      try {
        _cameraReady = await CameraService.initializeCamera();
        if (_cameraReady) {
          await CameraService.startPreview();
        }
      } catch (_) {
        // Ignore camera errors on web or unsupported platforms
      }

      // Call start API
      final startResult = await LiveStreamService.startLiveStream(
        roomId: _roomId!,
        streamKey: _streamKey!,
      );

      if (startResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(startResult['data']['message'] ?? 'Live started'),
            backgroundColor: Colors.green,
          ),
        );
        // Stream started successfully - user can now use native host or web host
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(startResult['message'] ?? 'Failed to start'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkStatus() async {
    if (_roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a room first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final result = await LiveStreamService.getRoomStatus(_roomId!);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _status = result['success'] == true ? result['data'] : null;
    });
    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to get status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Live'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videocam,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Live Streaming Host',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Create a live room using the API, then open the host page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hostNameController,
                decoration: const InputDecoration(
                  labelText: 'Host name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              // Button Grid Layout for better space utilization
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600 ? 200 : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createRoom,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add_circle_outline),
                      label: Text(_isLoading ? 'Creating...' : 'Create Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600 ? 200 : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startLiveStream,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Live Stream'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600 ? 200 : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _roomId != null && _streamKey != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NativeStreamHostScreen(
                                    roomId: _roomId!,
                                    streamKey: _streamKey!,
                                    title: _titleController.text.trim().isEmpty 
                                        ? 'My Live Stream' 
                                        : _titleController.text.trim(),
                                    hostName: _hostNameController.text.trim().isEmpty 
                                        ? 'Host' 
                                        : _hostNameController.text.trim(),
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Native Stream Host'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600 ? 200 : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openHostPage,
                      icon: const Icon(Icons.launch),
                      label: const Text('Web Host Page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width > 600 ? 200 : double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkStatus,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Check Room Status'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_cameraReady && CameraService.cameraController != null) ...[
                SizedBox(
                  width: 240,
                  height: 160,
                  child: CameraPreview(CameraService.cameraController!),
                ),
                const SizedBox(height: 8),
                const Text('Camera preview active'),
              ],
              if (_roomId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Room ID: $_roomId', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      Text('Stream Key: $_streamKey', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      if (_joinUrl != null) Text('Join URL: $_joinUrl', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      if (_hostUrl != null) Text('Host URL: $_hostUrl', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      if (_status != null) ...[
                        const SizedBox(height: 8),
                        Text('Status: ${_status!['status']}  •  Live: ${_status!['isLive']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        Text('Viewers: ${_status!['viewerCount']}  •  Duration: ${_status!['duration']}s', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      ]
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
