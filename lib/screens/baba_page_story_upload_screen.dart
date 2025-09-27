import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_story_model.dart';
import '../services/baba_page_story_service.dart';
import '../providers/auth_provider.dart';

class BabaPageStoryUploadScreen extends StatefulWidget {
  final BabaPage babaPage;

  const BabaPageStoryUploadScreen({
    Key? key,
    required this.babaPage,
  }) : super(key: key);

  @override
  State<BabaPageStoryUploadScreen> createState() => _BabaPageStoryUploadScreenState();
}

class _BabaPageStoryUploadScreenState extends State<BabaPageStoryUploadScreen> {
  dynamic _selectedMedia; // Use dynamic to support both File and XFile
  String _mediaType = 'image';
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
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
        maxDuration: const Duration(seconds: 60),
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
      }
    } catch (e) {
      _showErrorSnackBar('Error picking video: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
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
      _showErrorSnackBar('Error taking photo: $e');
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
            _selectedMedia = video;
          } else {
            // On mobile, convert to File
            _selectedMedia = File(video.path);
          }
          _mediaType = 'video';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking video: $e');
    }
  }

  Future<void> _uploadStory() async {
    if (_selectedMedia == null) {
      _showErrorSnackBar('Please select media first');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter story content');
      return;
    }

    print('BabaPageStoryUploadScreen: Starting upload process');
    print('BabaPageStoryUploadScreen: Media file: ${_selectedMedia!.path}');
    print('BabaPageStoryUploadScreen: Media type: $_mediaType');
    print('BabaPageStoryUploadScreen: Baba page: ${widget.babaPage.id}');

    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      // Upload story using the Baba page story service
      final result = await BabaPageStoryService.uploadBabaPageStory(
        mediaFile: _selectedMedia!,
        babaPageId: widget.babaPage.id,
        content: _contentController.text.trim(),
        token: token,
      );

      print('BabaPageStoryUploadScreen: Upload result - Success: ${result.success}');
      print('BabaPageStoryUploadScreen: Upload result - Message: ${result.message}');

      if (result.success) {
        _showSuccessSnackBar('Story uploaded successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Failed to upload story: ${result.message}');
      }
    } catch (e) {
      print('BabaPageStoryUploadScreen: Error uploading story: $e');
      _showErrorSnackBar('Error uploading story: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Story',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_selectedMedia != null && _contentController.text.trim().isNotEmpty)
            TextButton(
              onPressed: _isUploading ? null : _uploadStory,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baba page info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: widget.babaPage.avatar.isNotEmpty
                        ? NetworkImage(widget.babaPage.avatar)
                        : null,
                    child: widget.babaPage.avatar.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.babaPage.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Uploading story...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Media selection
            if (_selectedMedia == null) ...[
              const Text(
                'Select Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMediaOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: Colors.blue,
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMediaOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: Colors.green,
                      onTap: _takePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMediaOption(
                      icon: Icons.videocam,
                      label: 'Video',
                      color: Colors.purple,
                      onTap: _pickVideo,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Media preview
              const Text(
                'Media Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _mediaType == 'image'
                      ? Image.file(
                          _selectedMedia!,
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Video Selected'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Content input
            const Text(
              'Story Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your spiritual thoughts...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedMedia != null && _contentController.text.trim().isNotEmpty && !_isUploading) 
                    ? _uploadStory 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedMedia != null && _contentController.text.trim().isNotEmpty) 
                      ? Colors.orange 
                      : Colors.grey.shade300,
                  foregroundColor: (_selectedMedia != null && _contentController.text.trim().isNotEmpty) 
                      ? Colors.white 
                      : Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading...'),
                        ],
                      )
                    : Text(
                        _selectedMedia == null 
                            ? 'Select Media First'
                            : _contentController.text.trim().isEmpty 
                                ? 'Enter Story Content'
                                : 'Upload Story',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
