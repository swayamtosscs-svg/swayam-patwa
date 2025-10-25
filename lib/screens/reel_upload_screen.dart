import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/video_player_widget.dart';
import 'package:provider/provider.dart';
import '../services/reel_service.dart';
import '../services/media_upload_service.dart';
import '../services/local_storage_service.dart';
import '../services/user_media_service.dart';
import '../models/reel_model.dart';
import '../models/post_model.dart';
import '../providers/auth_provider.dart';

class ReelUploadScreen extends StatefulWidget {
  const ReelUploadScreen({Key? key}) : super(key: key);

  @override
  State<ReelUploadScreen> createState() => _ReelUploadScreenState();
}

class _ReelUploadScreenState extends State<ReelUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _thumbnailController = TextEditingController();
  
  dynamic _selectedVideo; // Use dynamic to support both File and XFile
  bool _isLoading = false;
  String? _uploadResult;
  bool _isVideoInitialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('ReelUploadScreen: Initializing');
    // Pre-fill with example token from the API documentation
  }



  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60), // Reels can be longer than stories
      );

      if (video != null) {
        setState(() {
          if (kIsWeb) {
            // On web, use the video object directly
            _selectedVideo = video;
          } else {
            // On mobile, convert to File
            _selectedVideo = File(video.path);
          }
        });
        _initializeVideoController();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking video: $e');
    }
  }

  Future<void> _takeVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        setState(() {
          if (kIsWeb) {
            // On web, use the video object directly
            _selectedVideo = video;
          } else {
            // On mobile, convert to File
            _selectedVideo = File(video.path);
          }
        });
        _initializeVideoController();
      }
    } catch (e) {
      _showErrorSnackBar('Error taking video: $e');
    }
  }

  Future<void> _initializeVideoController() async {
    if (_selectedVideo != null) {
      if (kIsWeb) {
        // For web, we can't use VideoPlayerController.file
        // Skip video preview on web for now
        setState(() {
          _isVideoInitialized = false;
        });
        return;
      }
      
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _uploadReel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadResult = null;
    });

    try {
      if (_selectedVideo == null) {
        _showErrorSnackBar('Please select a video first');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current user ID from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userProfile?.id;
      
      if (currentUserId == null) {
        _showErrorSnackBar('User not authenticated');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // First upload video to local storage with userId
      print('Starting video upload to local storage...');
      final mediaUploadResult = await MediaUploadService.uploadVideo(
        _selectedVideo!,
        currentUserId,
        title: _contentController.text.trim().isNotEmpty 
            ? _contentController.text.trim() 
            : 'Reel Upload',
      );
      print('Local storage upload result: ${mediaUploadResult.success} - ${mediaUploadResult.message}');
      
      if (mediaUploadResult.success && mediaUploadResult.data != null) {
        print('Video uploaded successfully to local storage: ${mediaUploadResult.data!.secureUrl}');
        
        // Video uploaded successfully, now create reel
        final token = authProvider.authToken;
        
        if (token == null) {
          _showErrorSnackBar('Authentication token not found');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        print('Creating reel with token: ${token.substring(0, 20)}...');
        final response = await ReelService.uploadReel(
          content: _contentController.text,
          videoUrl: mediaUploadResult.data!.secureUrl,
          thumbnail: _thumbnailController.text.isNotEmpty 
            ? _thumbnailController.text 
            : mediaUploadResult.data!.secureUrl, // Use video URL as thumbnail if none provided
          token: token,
        );

        print('Reel service response: ${response.success} - ${response.message}');

        if (response.success) {
          // Save the reel locally so it shows up in the profile
          final localReel = Post(
            id: 'local_reel_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'current_user',
            username: 'You',
            userAvatar: 'https://via.placeholder.com/50/6366F1/FFFFFF?text=U',
            caption: _contentController.text.trim(),
            videoUrl: mediaUploadResult.data!.secureUrl,
            type: PostType.reel,
            createdAt: DateTime.now(),
            hashtags: [],
          );
          
          print('Saving reel locally...');
          await LocalStorageService.saveReel(localReel);
          print('Reel saved locally successfully');
          
          setState(() {
            _uploadResult = '✅ Reel uploaded successfully!\n\nVideo uploaded to local storage\nReel created and saved locally\nYou can now see it in your profile!';
            _isLoading = false;
          });

          // Clear form on success
          _contentController.clear();
          _thumbnailController.clear();
          setState(() {
            _selectedVideo = null;
            _isVideoInitialized = false;
          });
          
          // Show success message
          _showSuccessSnackBar('Reel uploaded successfully! Check your profile.');
          
          // Notify that media has been updated for this user
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.userProfile?.id;
          if (currentUserId != null) {
            UserMediaService.notifyMediaUpdated(currentUserId);
            // Also clear any cached data
            UserMediaService.clearUserCache(currentUserId);
          }
          
        } else {
          // Even if reel service fails, we still have the video uploaded
          // Save it locally so it appears in the profile
          final localReel = Post(
            id: 'local_reel_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'current_user',
            username: 'You',
            userAvatar: 'https://via.placeholder.com/50/6366F1/FFFFFF?text=U',
            caption: _contentController.text.trim(),
            videoUrl: mediaUploadResult.data!.secureUrl,
            type: PostType.reel,
            createdAt: DateTime.now(),
            hashtags: [],
          );
          
          await LocalStorageService.saveReel(localReel);
          
          setState(() {
            _uploadResult = '⚠️ Video uploaded to local storage but reel service failed\n\nVideo is saved locally and will appear in your profile\nError: ${response.message}';
            _isLoading = false;
          });
          
          _showSuccessSnackBar('Video uploaded! Check your profile for the reel.');
        }
      } else {
        _showErrorSnackBar('Video upload failed: ${mediaUploadResult.message}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _uploadReel: $e');
      setState(() {
        _uploadResult = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildVideoSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Video',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedVideo != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isVideoInitialized
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: VideoPlayerWidget(
                          videoUrl: _selectedVideo is File 
                              ? _selectedVideo.path 
                              : _selectedVideo.path,
                          autoPlay: false,
                          looping: true,
                          muted: true,
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        if (_selectedVideo == null)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No video selected', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takeVideo,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Record Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: 'Reel Content',
        hintText: 'Enter your reel description...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter reel content';
        }
        return null;
      },
    );
  }

  Widget _buildThumbnailInput() {
    return TextFormField(
      controller: _thumbnailController,
      decoration: const InputDecoration(
        labelText: 'Thumbnail URL (Optional)',
        hintText: 'Leave empty to use video as thumbnail...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.image),
      ),
      validator: (value) {
        // Thumbnail is now optional
        if (value != null && value.trim().isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasAbsolutePath) {
            return 'Please enter a valid URL';
          }
        }
        return null;
      },
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _uploadReel,
      icon: _isLoading 
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.upload),
      label: Text(_isLoading ? 'Uploading...' : 'Upload Reel'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUploadResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _uploadResult!.startsWith('✅') 
          ? Colors.green.shade50 
          : Colors.red.shade50,
        border: Border.all(
          color: _uploadResult!.startsWith('✅') 
            ? Colors.green.shade200 
            : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _uploadResult!,
        style: TextStyle(
          color: _uploadResult!.startsWith('✅') 
            ? Colors.green.shade800 
            : Colors.red.shade800,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ReelUploadScreen: Building screen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Reel'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video Selection
              _buildVideoSelection(),
              
              const SizedBox(height: 24),
              
              // Content Input
              _buildContentInput(),
              
              const SizedBox(height: 24),
              
              // Thumbnail Input
              _buildThumbnailInput(),
              
              const SizedBox(height: 32),
              
              // Upload Button
              _buildUploadButton(),
              
              const SizedBox(height: 24),
              
              // Upload Result
              if (_uploadResult != null) _buildUploadResult(),
            ],
          ),
        ),
      ),
    );
  }
}
