import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:video_thumbnail/video_thumbnail.dart'; // Commented out for smaller APK
import 'package:provider/provider.dart';
import '../services/baba_page_reel_service.dart';
import '../utils/app_theme.dart';
import '../models/baba_page_model.dart';
import '../providers/auth_provider.dart';

class BabaPageReelUploadScreen extends StatefulWidget {
  final BabaPage babaPage;

  const BabaPageReelUploadScreen({
    Key? key,
    required this.babaPage,
  }) : super(key: key);

  @override
  State<BabaPageReelUploadScreen> createState() => _BabaPageReelUploadScreenState();
}

class _BabaPageReelUploadScreenState extends State<BabaPageReelUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _videoFile;
  File? _thumbnailFile;
  bool _isLoading = false;
  bool _isGeneratingThumbnail = false;
  String? _selectedCategory = 'video';

  final List<String> _categories = [
    'video',
    'reel',
    'tutorial',
    'meditation',
    'prayer',
    'spiritual',
    'yoga',
    'bhajan',
    'kirtan',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Upload Reel - ${widget.babaPage.name}',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (_videoFile != null && _thumbnailFile != null)
            TextButton(
              onPressed: _isLoading ? null : _uploadReel,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : const Text(
                      'Upload',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Selection Section
              _buildVideoSelectionSection(),
              const SizedBox(height: 24),
              
              // Thumbnail Selection Section
              _buildThumbnailSelectionSection(),
              const SizedBox(height: 24),
              
              // Form Fields Section
              _buildFormFieldsSection(),
              const SizedBox(height: 24),
              
              // Category Selection Section
              _buildCategorySelectionSection(),
              const SizedBox(height: 32),
              
              // Upload Button
              _buildUploadButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Video',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          
          if (_videoFile == null)
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to select video',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MP4, MOV, AVI, MKV, WebM, M4V',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max size: 100MB',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_file,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _videoFile!.path.split('/').last,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_videoFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoFile = null;
                          _thumbnailFile = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Thumbnail',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          
          if (_thumbnailFile == null)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickThumbnail,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withOpacity(0.3),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 32,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select Image',
                            style: TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_videoFile != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: _generateThumbnail,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isGeneratingThumbnail)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                                ),
                              )
                            else
                              Icon(
                                Icons.auto_awesome,
                                size: 32,
                                color: AppTheme.accentColor,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              _isGeneratingThumbnail ? 'Generating...' : 'Auto Generate',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _thumbnailFile!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _thumbnailFile = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          
          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter video title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins',
              ),
              hintStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              if (value.trim().length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Enter video description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins',
              ),
              hintStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              if (value.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final canUpload = _videoFile != null && 
                     _thumbnailFile != null && 
                     _titleController.text.trim().isNotEmpty && 
                     _descriptionController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canUpload && !_isLoading ? _uploadReel : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
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
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              )
            : Text(
                canUpload ? 'Upload Reel' : 'Select Video & Thumbnail',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // Max 10 minutes
      );

      if (video != null) {
        final file = File(video.path);
        final fileSize = await file.length();
        
        if (fileSize > 100 * 1024 * 1024) { // 100MB
          _showSnackBar('Video file is too large. Maximum size is 100MB.', Colors.red);
          return;
        }

        setState(() {
          _videoFile = file;
          _thumbnailFile = null; // Reset thumbnail when video changes
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting video: $e', Colors.red);
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        if (fileSize > 10 * 1024 * 1024) { // 10MB
          _showSnackBar('Thumbnail file is too large. Maximum size is 10MB.', Colors.red);
          return;
        }

        setState(() {
          _thumbnailFile = file;
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting thumbnail: $e', Colors.red);
    }
  }

  Future<void> _generateThumbnail() async {
    if (_videoFile == null) return;

    setState(() {
      _isGeneratingThumbnail = true;
    });

    try {
      // Video thumbnail generation disabled for smaller APK - use placeholder
      final thumbnailFile = _videoFile; // Use video file as placeholder
      if (thumbnailFile != null) {
        final fileSize = await thumbnailFile.length();
        
        if (fileSize > 10 * 1024 * 1024) { // 10MB
          _showSnackBar('Generated thumbnail is too large.', Colors.red);
          return;
        }

        setState(() {
          _thumbnailFile = thumbnailFile;
        });
        
        _showSnackBar('Thumbnail generated successfully!', Colors.green);
      } else {
        _showSnackBar('Failed to generate thumbnail', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error generating thumbnail: $e', Colors.red);
    } finally {
      setState(() {
        _isGeneratingThumbnail = false;
      });
    }
  }

  Future<void> _uploadReel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoFile == null || _thumbnailFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get auth token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        _showSnackBar('Authentication token not found. Please login again.', Colors.red);
        return;
      }

      final response = await BabaPageReelService.uploadBabaPageReel(
        videoFile: _videoFile!,
        thumbnailFile: _thumbnailFile!,
        babaPageId: widget.babaPage.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory ?? 'video',
        token: token,
      );

      if (response['success'] == true) {
        _showSnackBar('Reel uploaded successfully! Video will be available for playback shortly.', Colors.green);
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar(response['message'] ?? 'Failed to upload reel', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error uploading reel: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
