import 'package:flutter/material.dart';
import '../services/media_service.dart';
import '../services/google_auth_service.dart';

class DemoMediaScreen extends StatefulWidget {
  const DemoMediaScreen({Key? key}) : super(key: key);

  @override
  State<DemoMediaScreen> createState() => _DemoMediaScreenState();
}

class _DemoMediaScreenState extends State<DemoMediaScreen> {
  List<MediaItem> _videos = [];
  List<MediaItem> _images = [];
  bool _isLoadingVideos = false;
  bool _isLoadingImages = false;
  String? _errorMessage;
  GoogleUser? _currentUser;
  bool _isLoadingAuth = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    setState(() {
      _isLoadingAuth = true;
    });

    try {
      final user = await GoogleAuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoadingAuth = false;
      });

      // If user is signed in, load media
      if (user != null) {
        _loadVideos();
        _loadImages();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking user: $e';
        _isLoadingAuth = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoadingAuth = true;
      _errorMessage = null;
    });

    try {
      // Use mock authentication for now since we can't open browser in Flutter
      final user = await GoogleAuthService.mockGoogleAuth();
      setState(() {
        _currentUser = user;
        _isLoadingAuth = false;
      });

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.fullName}! Redirecting to spiritual path selection...'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirect to spiritual path selection page
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/interests');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign-in failed: $e';
        _isLoadingAuth = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoadingAuth = true;
    });

    try {
      await GoogleAuthService.signOut();
      setState(() {
        _currentUser = null;
        _videos.clear();
        _images.clear();
        _isLoadingAuth = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign-out failed: $e';
        _isLoadingAuth = false;
      });
    }
  }

  Future<void> _loadVideos() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingVideos = true;
      _errorMessage = null;
    });

    try {
      final response = await MediaService.getVideos();
      if (response.success) {
        setState(() {
          _videos = response.items;
          _isLoadingVideos = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load videos';
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading videos: $e';
        _isLoadingVideos = false;
      });
    }
  }

  Future<void> _loadImages() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingImages = true;
    });

    try {
      final response = await MediaService.getImages();
      if (response.success) {
        setState(() {
          _images = response.items;
          _isLoadingImages = false;
        });
      } else {
        setState(() {
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Media'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadVideos();
                _loadImages();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Media API',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Endpoint: http://103.14.120.163:8081/api/media/combined',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Method: GET',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Authentication: Google Sign-In Required',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Authentication Section
            if (_currentUser == null) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In Required',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please sign in with Google to access the demo media content.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingAuth ? null : _signInWithGoogle,
                          icon: _isLoadingAuth
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: Text(_isLoadingAuth ? 'Signing In...' : 'Continue with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // User Profile Card
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (_currentUser!.avatar != null)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(_currentUser!.avatar!),
                        )
                      else
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${_currentUser!.fullName}!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentUser!.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoadingAuth ? null : _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Videos Section
              Text(
                'Demo Videos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoadingVideos)
                const Center(child: CircularProgressIndicator())
              else if (_videos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No videos available'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: video.thumbnail.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    child: Image.network(
                                      video.thumbnail,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.video_library,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.video_library,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          
                          // Video Info
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Type: ${video.type}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'File: ${video.fileType}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Open video URL
                                          _launchUrl(video.url);
                                        },
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Play Video'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          // Copy video URL
                                          _copyToClipboard(video.url);
                                        },
                                        icon: const Icon(Icons.copy),
                                        label: const Text('Copy URL'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Images Section
              Text(
                'Demo Images',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoadingImages)
                const Center(child: CircularProgressIndicator())
              else if (_images.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No images available'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final image = _images[index];
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: Image.network(
                                  image.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  image.title,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Type: ${image.type}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) {
    // In a real app, you would use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening URL: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(String text) {
    // In a real app, you would use flutter_clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
