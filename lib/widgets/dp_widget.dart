import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/dp_service.dart';
import '../utils/app_theme.dart';
import '../utils/avatar_utils.dart';
import '../screens/fullscreen_dp_viewer_screen.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../screens/story_viewer_screen.dart';

class DPWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String userId;
  final String token;
  final Function(String) onImageChanged;
  final double size;
  final Color borderColor;
  final bool showEditButton;
  final String? userName; // Add user name for default avatar

  const DPWidget({
    Key? key,
    this.currentImageUrl,
    required this.userId,
    required this.token,
    required this.onImageChanged,
    this.size = 120,
    this.borderColor = AppTheme.primaryColor,
    this.showEditButton = true,
    this.userName, // Add user name parameter
  }) : super(key: key);

  @override
  State<DPWidget> createState() => _DPWidgetState();
}

class _DPWidgetState extends State<DPWidget> with SingleTickerProviderStateMixin {
  String? _localImageUrl;
  String? _fileName;
  bool _isLoading = false;
  bool _hasActiveStory = false;
  List<Story> _stories = [];
  AnimationController? _ringController;

  @override
  void initState() {
    super.initState();
    _localImageUrl = widget.currentImageUrl;
    _loadDP();
    _initStoryState();
  }

  @override
  void didUpdateWidget(DPWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentImageUrl != widget.currentImageUrl) {
      print('DPWidget: currentImageUrl changed from ${oldWidget.currentImageUrl} to ${widget.currentImageUrl}');
      _localImageUrl = widget.currentImageUrl;
      // Reload DP to get the latest image
      _loadDP();
    }
    if (oldWidget.userId != widget.userId || oldWidget.token != widget.token) {
      _initStoryState();
    }
  }

  @override
  void dispose() {
    _ringController?.dispose();
    super.dispose();
  }

  Future<void> _initStoryState() async {
    if (widget.token.isEmpty) return;
    try {
      final fetched = await StoryService.getUserStories(widget.userId, token: widget.token, page: 1, limit: 20);
      
      // Debug: Verify that all fetched stories belong to the correct user
      print('DPWidget: Fetched ${fetched.length} stories for user ${widget.userId}');
      for (final story in fetched) {
        print('DPWidget: Story ${story.id} - Author: ${story.authorId} (${story.authorName})');
        if (story.authorId != widget.userId) {
          print('DPWidget: WARNING - Story ${story.id} belongs to different user ${story.authorId}, expected ${widget.userId}');
        }
      }
      
      // Filter stories to ensure only stories from the correct user are shown
      final filteredStories = fetched.where((story) => story.authorId == widget.userId).toList();
      print('DPWidget: After filtering, ${filteredStories.length} stories remain for user ${widget.userId}');
      
      bool active = false;
      final now = DateTime.now();
      for (final s in filteredStories) {
        if (s.isActive && s.expiresAt.isAfter(now)) {
          active = true;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _stories = filteredStories; // Use filtered stories instead of raw fetched stories
        _hasActiveStory = active;
      });
      _updateRingAnimation();
    } catch (e) {
      print('DPWidget: Error loading stories: $e');
    }
  }

  void _updateRingAnimation() {
    if (_hasActiveStory) {
      _ringController ??= AnimationController(vsync: this, duration: const Duration(seconds: 4));
      if (!_ringController!.isAnimating) {
        _ringController!.repeat();
      }
    } else {
      _ringController?.stop();
    }
  }

  Future<void> _loadDP() async {
    if (widget.token.isEmpty) {
      print('DPWidget: No token available, skipping load');
      return;
    }

    print('DPWidget: Loading DP for user ${widget.userId}');
    print('DPWidget: Current image URL from props: ${widget.currentImageUrl}');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DPService.retrieveDP(
        userId: widget.userId,
        token: widget.token,
      );

      print('DPWidget: Load response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('DPWidget: DP data: $data');
        
        if (data != null && data['dpUrl'] != null && data['dpUrl'].toString().isNotEmpty) {
          setState(() {
            _localImageUrl = data['dpUrl'];
            _fileName = data['fileName'];
            _isLoading = false;
          });
          print('DPWidget: DP loaded: $_localImageUrl');
          print('DPWidget: File name: $_fileName');
          print('DPWidget: Absolute URL: ${AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!)}');
          print('DPWidget: Is valid URL: ${AvatarUtils.isValidAvatarUrl(_localImageUrl)}');
          
          // Notify parent about the change if we got a new image
          if (widget.currentImageUrl != _localImageUrl) {
            widget.onImageChanged(_localImageUrl!);
          }
        } else {
          print('DPWidget: No DP data in response');
          // Check if we have a valid URL from props
          if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty && AvatarUtils.isValidAvatarUrl(widget.currentImageUrl)) {
            print('DPWidget: Using currentImageUrl from props: ${widget.currentImageUrl}');
            setState(() {
              _localImageUrl = widget.currentImageUrl;
              _fileName = null; // We don't have fileName from props
              _isLoading = false;
            });
          } else {
            setState(() {
              _localImageUrl = null;
              _fileName = null;
              _isLoading = false;
            });
          }
        }
      } else {
        print('DPWidget: Failed to load DP: ${response['message']}');
        print('DPWidget: Error details: ${response['error']}');
        
        // Check if we have a valid URL from props as fallback
        if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty && AvatarUtils.isValidAvatarUrl(widget.currentImageUrl)) {
          print('DPWidget: Using currentImageUrl from props as fallback: ${widget.currentImageUrl}');
          setState(() {
            _localImageUrl = widget.currentImageUrl;
            _fileName = null; // We don't have fileName from props
            _isLoading = false;
          });
        } else {
          setState(() {
            _localImageUrl = null;
            _fileName = null;
            _isLoading = false;
          });
        }
        
        // Don't show error message for "No display picture found" - this is normal
        if (response['message'] != 'No display picture found for this user.' && mounted) {
          _showSnackBar(
            response['message'] ?? 'Failed to load display picture',
            Colors.orange,
          );
        }
      }
    } catch (e) {
      print('DPWidget: Error loading DP: $e');
      
      // Check if we have a valid URL from props as fallback
      if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty && AvatarUtils.isValidAvatarUrl(widget.currentImageUrl)) {
        print('DPWidget: Using currentImageUrl from props as fallback after error: ${widget.currentImageUrl}');
        setState(() {
          _localImageUrl = widget.currentImageUrl;
          _fileName = null; // We don't have fileName from props
          _isLoading = false;
        });
      } else {
        setState(() {
          _localImageUrl = null;
          _fileName = null;
          _isLoading = false;
        });
        _showSnackBar('Error loading display picture: $e', Colors.red);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.token.isEmpty) {
      _showSnackBar('Authentication token not found', Colors.red);
      return;
    }

    print('DPWidget: Token available: ${widget.token.isNotEmpty}');
    print('DPWidget: User ID: ${widget.userId}');

    // Show image source selection dialog
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      print('DPWidget: Starting image picker with source: $source');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null) {
        print('DPWidget: Image selected: ${image.path}');
        print('DPWidget: Image name: ${image.name}');
        print('DPWidget: Image size: ${await image.length()} bytes');
        
        // Handle web platform differently
        if (kIsWeb) {
          try {
            // For web, use the web-compatible upload method
            final bytes = await image.readAsBytes();
            print('DPWidget: Web image bytes length: ${bytes.length}');
            await _uploadImageWeb(bytes, image.name);
          } catch (e) {
            print('DPWidget: Error processing web image: $e');
            _showSnackBar('Error processing selected image. Please try again.', Colors.red);
          }
        } else {
          // For mobile platforms, use File object with cropping
          final imageFile = File(image.path);
          if (await imageFile.exists()) {
            print('DPWidget: Image file exists, proceeding with crop and upload');
            await _cropAndUploadImage(imageFile);
          } else {
            print('DPWidget: Image file does not exist');
            _showSnackBar('Selected image file not found', Colors.red);
          }
        }
      } else {
        print('DPWidget: No image selected');
      }
    } catch (e) {
      print('DPWidget: Error picking image: $e');
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cropAndUploadImage(File imageFile) async {
    try {
      print('DPWidget: Starting image cropping');
      
      // Show cropping dialog
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop for profile picture
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppTheme.primaryColor,
            cropFrameColor: AppTheme.primaryColor,
            cropGridColor: AppTheme.primaryColor.withOpacity(0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
            hideBottomControls: false,
            showCropGrid: true,
            statusBarColor: AppTheme.primaryColor,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: false,
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (croppedFile != null) {
        print('DPWidget: Image cropped successfully: ${croppedFile.path}');
        final croppedImageFile = File(croppedFile.path);
        await _uploadImage(croppedImageFile);
      } else {
        print('DPWidget: Image cropping cancelled');
        _showSnackBar('Image cropping cancelled', Colors.orange);
      }
    } catch (e) {
      print('DPWidget: Error cropping image: $e');
      // If cropping fails, upload original image
      _showSnackBar('Cropping failed, uploading original image', Colors.orange);
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    print('DPWidget: Starting image upload');
    print('DPWidget: User ID: ${widget.userId}');
    print('DPWidget: Token available: ${widget.token.isNotEmpty}');
    print('DPWidget: Image file path: ${imageFile.path}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('DPWidget: Calling DPService.uploadDP');
      final response = await DPService.uploadDP(
        imageFile: imageFile,
        userId: widget.userId,
        token: widget.token,
      );

      print('DPWidget: Upload response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('DPWidget: Upload successful, data: $data');
        
        setState(() {
          _localImageUrl = data['dpUrl'];
          _fileName = data['fileName'];
          _isLoading = false;
        });

        // Notify parent about the change
        widget.onImageChanged(data['dpUrl']);

        _showSnackBar('Display picture uploaded successfully!', Colors.green);
      } else {
        print('DPWidget: Upload failed: ${response['message']}');
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to upload display picture',
          Colors.red,
        );
      }
    } catch (e) {
      print('DPWidget: Error uploading image: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
    }
  }

  Future<void> _uploadImageWeb(List<int> imageBytes, String fileName) async {
    print('DPWidget: Starting web image upload');
    print('DPWidget: User ID: ${widget.userId}');
    print('DPWidget: Token available: ${widget.token.isNotEmpty}');
    print('DPWidget: Image bytes length: ${imageBytes.length}');
    print('DPWidget: File name: $fileName');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a temporary file for web upload
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);
      
      print('DPWidget: Calling DPService.uploadDP');
      final response = await DPService.uploadDP(
        imageFile: tempFile,
        userId: widget.userId,
        token: widget.token,
      );

      print('DPWidget: Web upload response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('DPWidget: Web upload successful, data: $data');
        
        setState(() {
          _localImageUrl = data['dpUrl'];
          _fileName = data['fileName'];
          _isLoading = false;
        });

        // Notify parent about the change
        widget.onImageChanged(data['dpUrl']);

        _showSnackBar('Display picture uploaded successfully!', Colors.green);
      } else {
        print('DPWidget: Web upload failed: ${response['message']}');
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to upload display picture',
          Colors.red,
        );
      }
    } catch (e) {
      print('DPWidget: Error uploading web image: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
    }
  }

  Future<void> _deleteDP() async {
    if (_fileName == null || _fileName!.isEmpty) {
      _showSnackBar('No display picture to delete', Colors.orange);
      return;
    }

    if (widget.token.isEmpty) {
      _showSnackBar('Authentication token not found', Colors.red);
      return;
    }

    print('DPWidget: Attempting to delete DP with fileName: $_fileName');

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Display Picture'),
        content: const Text(
          'Are you sure you want to delete your display picture? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('DPWidget: Deleting DP with fileName: $_fileName');
      final response = await DPService.deleteDP(
        userId: widget.userId,
        fileName: _fileName!,
        token: widget.token,
      );

      print('DPWidget: Delete response: $response');

      if (response['success'] == true && mounted) {
        setState(() {
          _localImageUrl = null;
          _fileName = null;
          _isLoading = false;
        });

        // Notify parent about the change
        widget.onImageChanged('');

        _showSnackBar('Display picture deleted successfully!', Colors.green);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to delete display picture',
          Colors.red,
        );
      }
    } catch (e) {
      print('DPWidget: Error deleting DP: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error deleting display picture: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug information
    print('DPWidget: Building widget');
    print('DPWidget: _localImageUrl: $_localImageUrl');
    print('DPWidget: _fileName: $_fileName');
    print('DPWidget: showEditButton: ${widget.showEditButton}');
    print('DPWidget: Should show delete button: ${widget.showEditButton && _localImageUrl != null && _localImageUrl!.isNotEmpty && _fileName != null && _fileName!.isNotEmpty}');
    print('DPWidget: Is valid URL: ${_localImageUrl != null ? AvatarUtils.isValidAvatarUrl(_localImageUrl) : false}');
    print('DPWidget: Absolute URL: ${_localImageUrl != null ? AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!) : 'null'}');
    
    return Stack(
      children: [
        // Main DP container
        if (_hasActiveStory && _ringController != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ringController!,
              builder: (context, child) {
                return Center(
                  child: Transform.rotate(
                    angle: _ringController!.value * 2 * math.pi,
                    child: Container(
                      width: widget.size + 12,
                      height: widget.size + 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFFFF5E7E),
                            Color(0xFFFFC371),
                            Color(0xFF8B5CF6),
                            Color(0xFFFF5E7E),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  if (widget.showEditButton) {
                    _pickAndUploadImage();
                  } else {
                    if (_hasActiveStory && _stories.isNotEmpty) {
                      // Debug: Verify stories before opening story viewer
                      print('DPWidget: Opening story viewer for user ${widget.userId}');
                      print('DPWidget: Stories to show: ${_stories.length}');
                      for (final story in _stories) {
                        print('DPWidget: Story ${story.id} - Author: ${story.authorId} (${story.authorName})');
                      }
                      
                      final initialIndex = 0;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryViewerScreen(
                            story: _stories[initialIndex],
                            allStories: _stories,
                            initialIndex: initialIndex,
                          ),
                        ),
                      );
                    } else {
                      final hasValidImage = _localImageUrl != null &&
                          _localImageUrl!.isNotEmpty &&
                          AvatarUtils.isValidAvatarUrl(_localImageUrl);
                      if (hasValidImage) {
                        final absoluteUrl =
                            AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenDPViewerScreen(
                              imageUrl: absoluteUrl,
                              title: widget.userName ?? 'Profile photo',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
          onLongPress: _isLoading
              ? null
              : () {
                  final hasValidImage = _localImageUrl != null &&
                      _localImageUrl!.isNotEmpty &&
                      AvatarUtils.isValidAvatarUrl(_localImageUrl);
                  if (hasValidImage) {
                    final absoluteUrl =
                        AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullscreenDPViewerScreen(
                          imageUrl: absoluteUrl,
                          title: widget.userName ?? 'Profile photo',
                        ),
                      ),
                    );
                  }
                },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.borderColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.borderColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
            child: _isLoading
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.borderColor.withOpacity(0.1),
                          widget.borderColor.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : _localImageUrl != null && _localImageUrl!.isNotEmpty && AvatarUtils.isValidAvatarUrl(_localImageUrl)
                    ? Hero(
                        tag: 'dp_${AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!)}',
                        child: Image.network(
                          AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('DPWidget: Error loading image: $error');
                            print('DPWidget: Failed URL: ${AvatarUtils.getAbsoluteAvatarUrl(_localImageUrl!)}');
                            return _buildDefaultAvatar();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.borderColor.withOpacity(0.1),
                                    widget.borderColor.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
            ),
          ),
        ),
        
        // Edit button
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isLoading ? null : _pickAndUploadImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        
        // Delete button (only show if DP exists and we have fileName)
        if (widget.showEditButton && 
            _localImageUrl != null && 
            _localImageUrl!.isNotEmpty && 
            _fileName != null && 
            _fileName!.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isLoading ? null : _deleteDP,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return AvatarUtils.buildGradientDefaultAvatar(
      name: widget.userName,
      size: widget.size,
      borderColor: widget.borderColor,
      borderWidth: 4,
    );
  }
}
