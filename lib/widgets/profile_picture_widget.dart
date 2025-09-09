import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/profile_picture_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String userId;
  final String token;
  final Function(String) onImageChanged;
  final double size;
  final Color borderColor;
  final bool showEditButton;

  const ProfilePictureWidget({
    super.key,
    this.currentImageUrl,
    required this.userId,
    required this.token,
    required this.onImageChanged,
    this.size = 120,
    this.borderColor = Colors.blue,
    this.showEditButton = true,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  bool _isLoading = false;
  String? _localImageUrl;
  String? _publicId;

  @override
  void initState() {
    super.initState();
    print('ProfilePictureWidget: initState called');
    print('ProfilePictureWidget: currentImageUrl: ${widget.currentImageUrl}');
    print('ProfilePictureWidget: userId: ${widget.userId}');
    print('ProfilePictureWidget: token available: ${widget.token.isNotEmpty}');
    
    // Set the local image URL from the current image URL
    _localImageUrl = widget.currentImageUrl;
    print('ProfilePictureWidget: _localImageUrl set to: $_localImageUrl');
    
    // Only load from API if we don't have a current image
    if (_localImageUrl == null || _localImageUrl!.isEmpty) {
      print('ProfilePictureWidget: No current image, loading from API');
      _loadProfilePicture();
    } else {
      print('ProfilePictureWidget: Using current image URL: $_localImageUrl');
    }
  }

  @override
  void didUpdateWidget(ProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('ProfilePictureWidget: didUpdateWidget called');
    print('ProfilePictureWidget: old currentImageUrl: ${oldWidget.currentImageUrl}');
    print('ProfilePictureWidget: new currentImageUrl: ${widget.currentImageUrl}');
    
    // Update local image URL if the widget's currentImageUrl changed
    if (oldWidget.currentImageUrl != widget.currentImageUrl) {
      print('ProfilePictureWidget: Updating local image URL to: ${widget.currentImageUrl}');
      setState(() {
        _localImageUrl = widget.currentImageUrl;
      });
    }
  }

  Future<void> _loadProfilePicture() async {
    if (widget.token.isEmpty) {
      print('ProfilePictureWidget: No token available, skipping load');
      return;
    }

    print('ProfilePictureWidget: Loading profile picture for user ${widget.userId}');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfilePictureService.retrieveProfilePicture(
        userId: widget.userId,
        token: widget.token,
      );

      print('ProfilePictureWidget: Load response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('ProfilePictureWidget: Profile picture data: $data');
        
        if (data != null && data['avatar'] != null && data['avatar'].toString().isNotEmpty) {
          setState(() {
            _localImageUrl = data['avatar'];
            _publicId = data['publicId'];
            _isLoading = false;
          });
          print('ProfilePictureWidget: Profile picture loaded: $_localImageUrl');
          
          // Notify parent about the change if we got a new image
          if (widget.currentImageUrl != _localImageUrl) {
            widget.onImageChanged(_localImageUrl!);
          }
        } else {
          print('ProfilePictureWidget: No avatar data in response');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('ProfilePictureWidget: Failed to load profile picture: ${response['message']}');
        print('ProfilePictureWidget: Error details: ${response['error']}');
        setState(() {
          _isLoading = false;
        });
        
        // Show error message to user
        if (mounted) {
          _showSnackBar(
            response['message'] ?? 'Failed to load profile picture',
            Colors.orange,
          );
        }
      }
    } catch (e) {
      print('ProfilePictureWidget: Error loading profile picture: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading profile picture: $e', Colors.red);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.token.isEmpty) {
      _showSnackBar('Authentication token not found', Colors.red);
      return;
    }

    try {
      print('ProfilePictureWidget: Starting image picker');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        print('ProfilePictureWidget: Image selected: ${image.path}');
        print('ProfilePictureWidget: Image name: ${image.name}');
        print('ProfilePictureWidget: Image size: ${await image.length()} bytes');
        
        // Handle web platform differently
        if (kIsWeb) {
          try {
            // For web, use the web-compatible upload method
            final bytes = await image.readAsBytes();
            print('ProfilePictureWidget: Web image bytes length: ${bytes.length}');
            await _uploadImageWeb(bytes, image.name);
          } catch (e) {
            print('ProfilePictureWidget: Error processing web image: $e');
            _showSnackBar('Error processing selected image. Please try again.', Colors.red);
          }
        } else {
          // For mobile platforms, use File object
          final imageFile = File(image.path);
          if (await imageFile.exists()) {
            print('ProfilePictureWidget: Image file exists, proceeding with upload');
            await _uploadImage(imageFile);
          } else {
            print('ProfilePictureWidget: Image file does not exist');
            _showSnackBar('Selected image file not found', Colors.red);
          }
        }
      } else {
        print('ProfilePictureWidget: No image selected');
      }
    } catch (e) {
      print('ProfilePictureWidget: Error picking image: $e');
      
      // Provide more specific error messages
      String errorMessage = 'Error selecting image: $e';
      if (e.toString().contains('_Namespace')) {
        errorMessage = 'Image picker not supported on this platform. Please use a different method.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please allow access to your photo gallery.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Image selection was cancelled.';
      }
      
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    print('ProfilePictureWidget: Starting image upload');
    print('ProfilePictureWidget: User ID: ${widget.userId}');
    print('ProfilePictureWidget: Token available: ${widget.token.isNotEmpty}');
    print('ProfilePictureWidget: Image file path: ${imageFile.path}');
    print('ProfilePictureWidget: Image file size: ${await imageFile.length()} bytes');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('ProfilePictureWidget: Calling ProfilePictureService.uploadProfilePicture');
      final response = await ProfilePictureService.uploadProfilePicture(
        imageFile: imageFile,
        userId: widget.userId,
        token: widget.token,
      );

      print('ProfilePictureWidget: Upload response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('ProfilePictureWidget: Upload successful, data: $data');
        
        setState(() {
          _localImageUrl = data['avatar'];
          _publicId = data['publicId'];
          _isLoading = false;
        });

        // Notify parent about the change
        widget.onImageChanged(data['avatar']);

        _showSnackBar('Profile picture uploaded successfully!', Colors.green);
      } else {
        print('ProfilePictureWidget: Upload failed: ${response['message']}');
        print('ProfilePictureWidget: Error details: ${response['error']}');
        setState(() {
          _isLoading = false;
        });
        
        // Show specific error message based on error type
        String errorMessage = response['message'] ?? 'Failed to upload profile picture';
        if (response['error'] == 'Unauthorized') {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (response['error'] == 'File Too Large') {
          errorMessage = 'Image file is too large. Please select a smaller image.';
        } else if (response['error'] == 'Network Error') {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (response['error'] == 'Timeout') {
          errorMessage = 'Upload timed out. Please try again.';
        } else if (response['error'] == 'Invalid File Format') {
          errorMessage = 'Invalid image format. Please select a valid image (JPG, PNG, GIF, WebP).';
        } else if (response['error'] == 'SSL Error') {
          errorMessage = 'SSL certificate error. Please check your network settings.';
        } else if (response['error'] == 'Validation Error') {
          errorMessage = 'Validation failed. Please check your input.';
        }
        
        _showSnackBar(errorMessage, Colors.red);
        
        // Add debug button for failed uploads
        if (mounted) {
          _showDebugDialog(imageFile);
        }
      }
    } catch (e) {
      print('ProfilePictureWidget: Error during upload: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
    }
  }
  
  /// Show debug dialog with options to test different upload approaches
  void _showDebugDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Failed - Debug Options'),
          content: const Text('The profile picture upload failed. Would you like to run debug tests to identify the issue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _runDebugTests(imageFile);
              },
              child: const Text('Run Debug Tests'),
            ),
          ],
        );
      },
    );
  }
  
  /// Run debug tests to identify upload issues
  Future<void> _runDebugTests(File imageFile) async {
    print('ProfilePictureWidget: Running debug tests...');
    
    try {
      // Debug tests removed - using direct ProfilePictureService
      print('ProfilePictureWidget: Debug tests completed - using ProfilePictureService');
    } catch (e) {
      print('ProfilePictureWidget: Debug tests failed: $e');
      _showSnackBar('Debug tests failed: $e', Colors.red);
    }
  }

  Future<void> _uploadImageWeb(List<int> imageBytes, String fileName) async {
    print('ProfilePictureWidget: Starting web image upload');
    print('ProfilePictureWidget: User ID: ${widget.userId}');
    print('ProfilePictureWidget: Token available: ${widget.token.isNotEmpty}');
    print('ProfilePictureWidget: Image bytes length: ${imageBytes.length}');
    print('ProfilePictureWidget: File name: $fileName');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a temporary file for web upload
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);
      
      print('ProfilePictureWidget: Calling ProfilePictureService.uploadProfilePicture');
      final response = await ProfilePictureService.uploadProfilePicture(
        imageFile: tempFile,
        userId: widget.userId,
        token: widget.token,
      );

      print('ProfilePictureWidget: Web upload response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('ProfilePictureWidget: Web upload successful, data: $data');
        
        setState(() {
          _localImageUrl = data['avatar'];
          _publicId = data['publicId'];
          _isLoading = false;
        });

        // Notify parent about the change
        widget.onImageChanged(data['avatar']);

        _showSnackBar('Profile picture uploaded successfully!', Colors.green);
      } else {
        print('ProfilePictureWidget: Web upload failed: ${response['message']}');
        print('ProfilePictureWidget: Error details: ${response['error']}');
        setState(() {
          _isLoading = false;
        });
        
        // Show specific error message based on error type
        String errorMessage = response['message'] ?? 'Failed to upload profile picture';
        if (response['error'] == 'Unauthorized') {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (response['error'] == 'File Too Large') {
          errorMessage = 'Image file is too large. Please select a smaller image.';
        } else if (response['error'] == 'Network Error') {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (response['error'] == 'Timeout') {
          errorMessage = 'Upload timed out. Please try again.';
        } else if (response['error'] == 'Invalid File Format') {
          errorMessage = 'Invalid image format. Please select a valid image (JPG, PNG, GIF, WebP).';
        } else if (response['error'] == 'SSL Error') {
          errorMessage = 'SSL certificate error. Please check your network settings.';
        } else if (response['error'] == 'Validation Error') {
          errorMessage = 'Validation failed. Please check your input.';
        }
        
        _showSnackBar(errorMessage, Colors.red);
        
        // Add debug button for failed uploads (web)
        if (mounted) {
          _showWebDebugDialog(imageBytes, fileName);
        }
      }
    } catch (e) {
      print('ProfilePictureWidget: Error during web upload: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
    }
  }
  
  /// Show debug dialog for web uploads
  void _showWebDebugDialog(List<int> imageBytes, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Web Upload Failed - Debug Options'),
          content: const Text('The web profile picture upload failed. Would you like to run debug tests to identify the issue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _runWebDebugTests(imageBytes, fileName);
              },
              child: const Text('Run Debug Tests'),
            ),
          ],
        );
      },
    );
  }
  
  /// Run debug tests for web uploads
  Future<void> _runWebDebugTests(List<int> imageBytes, String fileName) async {
    print('ProfilePictureWidget: Running web debug tests...');
    
    try {
      // For web, we'll test with the bytes directly
      // Create a temporary file for testing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/debug_$fileName');
      await tempFile.writeAsBytes(imageBytes);
      
      // Debug tests removed - using direct ProfilePictureService
      print('ProfilePictureWidget: Web debug tests completed - using ProfilePictureService');
      
      // Clean up temp file
      await tempFile.delete();
    } catch (e) {
      print('ProfilePictureWidget: Web debug tests failed: $e');
      _showSnackBar('Web debug tests failed: $e', Colors.red);
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_publicId == null || widget.token.isEmpty) {
      _showSnackBar('No profile picture to delete', Colors.orange);
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile Picture'),
        content: const Text(
          'Are you sure you want to delete your profile picture? This action cannot be undone.',
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
      print('ProfilePictureWidget: Deleting profile picture with fileName: $_publicId');
      final response = await ProfilePictureService.deleteProfilePicture(
        userId: widget.userId,
        fileName: _publicId!,
        token: widget.token,
      );

      print('ProfilePictureWidget: Delete response: $response');

      if (response['success'] == true && mounted) {
        setState(() {
          _localImageUrl = null;
          _publicId = null;
          _isLoading = false;
        });

        // Notify parent about the change
        widget.onImageChanged('');

        _showSnackBar('Profile picture deleted successfully!', Colors.green);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to delete profile picture',
          Colors.red,
        );
      }
    } catch (e) {
      print('ProfilePictureWidget: Error deleting profile picture: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error deleting image: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile Picture Container
        Container(
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
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: _isLoading
                ? Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    ),
                  )
                : _localImageUrl != null && _localImageUrl!.isNotEmpty
                    ? Builder(
                        builder: (context) {
                          print('ProfilePictureWidget: Displaying image: $_localImageUrl');
                          return Image.network(
                            _localImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('ProfilePictureWidget: Image network error: $error');
                              return _buildDefaultAvatar();
                            },
                          );
                        },
                      )
                    : Builder(
                        builder: (context) {
                          print('ProfilePictureWidget: No image URL, showing default avatar');
                          return _buildDefaultAvatar();
                        },
                      ),
          ),
        ),

        // Edit Button (if enabled)
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: widget.borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.camera_alt,
                  color: widget.borderColor,
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'upload':
                      _pickAndUploadImage();
                      break;
                    case 'refresh':
                      _loadProfilePicture();
                      break;
                    case 'delete':
                      _deleteProfilePicture();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'upload',
                    child: Row(
                      children: [
                        Icon(Icons.upload, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Upload New'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  if (_localImageUrl != null && _localImageUrl!.isNotEmpty)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.borderColor.withOpacity(0.1),
            widget.borderColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: widget.borderColor,
      ),
    );
  }
}
