import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/video_player_widget.dart';
import 'package:provider/provider.dart';
import '../services/story_service.dart';
import '../services/media_upload_service.dart';
import '../models/story_model.dart';
import '../providers/auth_provider.dart';

class StoryUploadScreen extends StatefulWidget {
  final String token;

  const StoryUploadScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  dynamic _selectedMedia; // Use dynamic to support both File and XFile
  String _mediaType = 'image';
  bool _isUploading = false;
  bool _isVideoInitialized = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// Check and request camera permission
  Future<bool> _checkCameraPermission() async {
    try {
      print('StoryUploadScreen: Checking camera permission...');
      
      // Check if camera permission is granted
      var status = await Permission.camera.status;
      print('StoryUploadScreen: Camera permission status: $status');
      
      if (status.isGranted) {
        return true;
      }
      
      // Request permission if not granted
      if (status.isDenied) {
        print('StoryUploadScreen: Requesting camera permission...');
        status = await Permission.camera.request();
        print('StoryUploadScreen: Camera permission request result: $status');
      }
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Show dialog to open app settings
        _showPermissionDialog();
        return false;
      } else {
        _showErrorSnackBar('Camera permission denied. Please enable camera access to take photos.');
        return false;
      }
    } catch (e) {
      print('StoryUploadScreen: Error checking camera permission: $e');
      _showErrorSnackBar('Error checking camera permission: $e');
      return false;
    }
  }

  /// Show dialog to open app settings for permission
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'Camera access is required to take photos and videos. Please enable camera permission in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (kIsWeb) {
          // On web, use the image object directly
          _selectedMedia = image;
        } else {
          // On mobile, convert to File
          _selectedMedia = File(image.path);
        }
          _mediaType = 'image';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15), // Stories are typically short
      );

      if (video != null) {
        setState(() {
          if (kIsWeb) {
            // On web, use the video object directly
            _selectedMedia = video;
          } else {
            // On mobile, convert to File
            _selectedMedia = File(video.path);
          }
          _mediaType = 'video';
        });
        _initializeVideoController();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking video: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      print('StoryUploadScreen: Starting camera capture...');
      
      // Check camera permission first
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        print('StoryUploadScreen: Camera permission denied');
        return;
      }
      
      // Check if camera is available
      final ImagePicker picker = ImagePicker();
      
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear, // Use rear camera by default
      );

      print('StoryUploadScreen: Camera capture result: ${photo?.path}');

      if (photo != null) {
        print('StoryUploadScreen: Photo captured successfully: ${photo.path}');
        setState(() {
          if (kIsWeb) {
            // On web, use the photo object directly
            _selectedMedia = photo;
          } else {
            // On mobile, convert to File
            _selectedMedia = File(photo.path);
          }
          _mediaType = 'image';
        });
        
        // Show success message
        _showSuccessSnackBar('Photo captured successfully!');
      } else {
        print('StoryUploadScreen: No photo captured (user cancelled)');
        _showErrorSnackBar('No photo captured. Please try again.');
      }
    } catch (e) {
      print('StoryUploadScreen: Error taking photo: $e');
      
      // Provide more specific error messages
      String errorMessage = 'Error taking photo: $e';
      if (e.toString().contains('camera')) {
        errorMessage = 'Camera access denied. Please check permissions.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Camera permission required. Please enable camera access in settings.';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'Camera not available on this device.';
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<void> _takeVideo() async {
    try {
      print('StoryUploadScreen: Starting video camera capture...');
      
      // Check camera permission first
      bool hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        print('StoryUploadScreen: Camera permission denied');
        return;
      }
      
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 15),
        preferredCameraDevice: CameraDevice.rear, // Use rear camera by default
      );

      print('StoryUploadScreen: Video camera capture result: ${video?.path}');

      if (video != null) {
        print('StoryUploadScreen: Video captured successfully: ${video.path}');
        setState(() {
          if (kIsWeb) {
            // On web, use the video object directly
            _selectedMedia = video;
          } else {
            // On mobile, convert to File
            _selectedMedia = File(video.path);
          }
          _mediaType = 'video';
        });
        _initializeVideoController();
        
        // Show success message
        _showSuccessSnackBar('Video captured successfully!');
      } else {
        print('StoryUploadScreen: No video captured (user cancelled)');
        _showErrorSnackBar('No video captured. Please try again.');
      }
    } catch (e) {
      print('StoryUploadScreen: Error taking video: $e');
      
      // Provide more specific error messages
      String errorMessage = 'Error taking video: $e';
      if (e.toString().contains('camera')) {
        errorMessage = 'Camera access denied. Please check permissions.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Camera permission required. Please enable camera access in settings.';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'Camera not available on this device.';
      }
      
      _showErrorSnackBar(errorMessage);
    }
  }

  void _initializeVideoController() {
    if (_selectedMedia != null) {
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

  Future<void> _uploadStory() async {
    if (_selectedMedia == null) {
      _showErrorSnackBar('Please select media first');
      return;
    }

    print('StoryUploadScreen: Starting upload process');
    print('StoryUploadScreen: Media file: ${_selectedMedia!.path}');
    print('StoryUploadScreen: Media type: $_mediaType');
    print('StoryUploadScreen: Token: ${widget.token.substring(0, 20)}...');

    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user ID from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userProfile?.id;
      
      if (currentUserId == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      // Upload story directly using the story service
      final result = await StoryService.uploadStoryFromFile(
        file: _selectedMedia!,
        userId: currentUserId,
        caption: _captionController.text.isNotEmpty ? _captionController.text : 'My story',
        token: widget.token,
      );

      print('StoryUploadScreen: Upload result - Success: ${result.success}');
      print('StoryUploadScreen: Upload result - Message: ${result.message}');

      if (result.success) {
        if (result.message.contains('locally')) {
          _showSuccessSnackBar('Story uploaded and stored locally! (Server unavailable)');
        } else {
          _showSuccessSnackBar('Story uploaded successfully!');
        }
        // Wait a bit before navigating back to show the success message
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('Upload failed: ${result.message}');
      }
    } catch (e) {
      print('StoryUploadScreen: Exception during upload: $e');
      _showErrorSnackBar('Error uploading story: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Story'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedMedia != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadStory,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Media Preview
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedMedia != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _mediaType == 'image'
                          ? kIsWeb
                              ? Image.network(
                                  _selectedMedia!.path,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  _selectedMedia!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                          : _isVideoInitialized
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayerWidget(
                                      videoUrl: _selectedMedia is File 
                                          ? _selectedMedia.path 
                                          : _selectedMedia.path,
                                      autoPlay: false,
                                      looping: true,
                                      muted: true,
                                    ),
                                    FloatingActionButton(
                                      onPressed: () {
                                        // Play/pause is handled by VideoPlayerWidget
                                        setState(() {});
                                      },
                                      child: const Icon(
                                        Icons.play_arrow,
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                    )
                  : MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: _pickImage, // Opens gallery when tapped
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.grey[600]!.withOpacity(0.3),
                        highlightColor: Colors.grey[600]!.withOpacity(0.1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: Matrix4.identity()..scale(1.0), // Removed _isTapping
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[600]!, // Removed _isTapping
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[800]!.withOpacity(0.3), // Removed _isTapping
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Select media for your story',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to open gallery',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Caption Input Field
          if (_selectedMedia != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a caption to your story...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ),

          // Media Selection Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMediaButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _pickImage,
                    ),
                    _buildMediaButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: _takePhoto,
                      isPrimary: true, // Make camera button more prominent
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMediaButton(
                      icon: Icons.video_library,
                      label: 'Video Gallery',
                      onTap: _pickVideo,
                    ),
                    _buildMediaButton(
                      icon: Icons.videocam,
                      label: 'Video Camera',
                      onTap: _takeVideo,
                      isPrimary: true, // Make video camera button more prominent
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? Colors.blue[600] : Colors.grey[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: isPrimary ? 4 : 1, // Higher elevation for primary button
          ),
        ),
      ),
    );
  }
}
