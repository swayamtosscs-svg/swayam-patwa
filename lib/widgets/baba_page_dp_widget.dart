import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart'; // Commented out for smaller APK
import '../services/baba_page_dp_service.dart';
import '../utils/app_theme.dart';
import '../screens/fullscreen_dp_viewer_screen.dart';

class BabaPageDPWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String babaPageId;
  final String token;
  final Function(String) onImageChanged;
  final double size;
  final Color borderColor;
  final bool showEditButton;

  const BabaPageDPWidget({
    Key? key,
    this.currentImageUrl,
    required this.babaPageId,
    required this.token,
    required this.onImageChanged,
    this.size = 120,
    this.borderColor = AppTheme.primaryColor,
    this.showEditButton = true,
  }) : super(key: key);

  @override
  State<BabaPageDPWidget> createState() => _BabaPageDPWidgetState();
}

class _BabaPageDPWidgetState extends State<BabaPageDPWidget> {
  String? _localImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localImageUrl = widget.currentImageUrl;
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }

  /// Refresh DP from server
  Future<void> refreshDP() async {
    try {
      print('BabaPageDPWidget: Refreshing DP from server');
      
      final response = await BabaPageDPService.retrieveBabaPageDP(
        babaPageId: widget.babaPageId,
        token: widget.token,
      );

      if (response['success'] == true && mounted) {
        final data = response['data'];
        final avatar = data['avatar'] as String?;
        
        setState(() {
          _localImageUrl = avatar;
        });
        
        widget.onImageChanged(avatar ?? '');
        print('BabaPageDPWidget: DP refreshed successfully: $avatar');
      } else {
        print('BabaPageDPWidget: DP refresh failed: ${response['message']}');
      }
    } catch (e) {
      print('BabaPageDPWidget: Error refreshing DP: $e');
    }
  }

  Future<void> _deleteImage() async {
    if (_isLoading) return;
    
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Display Picture'),
          content: const Text('Are you sure you want to delete this display picture? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('BabaPageDPWidget: Deleting DP for Baba Ji page: ${widget.babaPageId}');
      
      final response = await BabaPageDPService.deleteBabaPageDP(
        babaPageId: widget.babaPageId,
        token: widget.token,
      );

      if (response['success'] == true) {
        print('BabaPageDPWidget: DP deleted successfully');
        setState(() {
          _localImageUrl = null;
        });
        widget.onImageChanged('');
        
        // Refresh DP from server to ensure consistency
        await refreshDP();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Display picture deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        print('BabaPageDPWidget: DP delete failed: ${response['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete display picture'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('BabaPageDPWidget: Error deleting DP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting display picture: $e'),
            backgroundColor: AppTheme.errorColor,
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

  void _handleDPTap() {
    if (_localImageUrl != null && _localImageUrl!.isNotEmpty) {
      // If image exists, do nothing - user can use the view button
      return;
    } else {
      // Upload new image
      _pickAndUploadImage();
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.token.isEmpty) {
      _showSnackBar('Authentication token not found', Colors.red);
      return;
    }

    print('BabaPageDPWidget: Token available: ${widget.token.isNotEmpty}');
    print('BabaPageDPWidget: Baba Page ID: ${widget.babaPageId}');

    try {
      print('BabaPageDPWidget: Starting image picker');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        print('BabaPageDPWidget: Image selected: ${image.path}');
        print('BabaPageDPWidget: Image name: ${image.name}');
        print('BabaPageDPWidget: Image size: ${await image.length()} bytes');
        
        // Handle web platform differently
        if (kIsWeb) {
          try {
            // For web, use the web-compatible upload method
            final bytes = await image.readAsBytes();
            print('BabaPageDPWidget: Web image bytes length: ${bytes.length}');
            await _uploadImageWeb(bytes, image.name);
          } catch (e) {
            print('BabaPageDPWidget: Error processing web image: $e');
            _showSnackBar('Error processing selected image. Please try again.', Colors.red);
          }
        } else {
          // For mobile platforms, use File object with cropping
          final imageFile = File(image.path);
          if (await imageFile.exists()) {
            print('BabaPageDPWidget: Image file exists, proceeding with crop and upload');
            await _cropAndUploadImage(imageFile);
          } else {
            print('BabaPageDPWidget: Image file does not exist');
            _showSnackBar('Selected image file not found', Colors.red);
          }
        }
      } else {
        print('BabaPageDPWidget: No image selected');
      }
    } catch (e) {
      print('BabaPageDPWidget: Error picking image: $e');
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  Future<void> _cropAndUploadImage(File imageFile) async {
    try {
      // Image cropping disabled for smaller APK - upload directly
      await _uploadImage(imageFile);
    } catch (e) {
      print('BabaPageDPWidget: Error cropping image: $e');
      // If cropping fails, upload original image
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    print('BabaPageDPWidget: Starting image upload');
    print('BabaPageDPWidget: Baba Page ID: ${widget.babaPageId}');
    print('BabaPageDPWidget: Token available: ${widget.token.isNotEmpty}');
    print('BabaPageDPWidget: Image file path: ${imageFile.path}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('BabaPageDPWidget: Calling BabaPageDPService.uploadBabaPageDP');
      final response = await BabaPageDPService.uploadBabaPageDP(
        imageFile: imageFile,
        babaPageId: widget.babaPageId,
        token: widget.token,
      );

      print('BabaPageDPWidget: Upload response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('BabaPageDPWidget: Upload successful, data: $data');
        print('BabaPageDPWidget: Avatar URL from response: ${data['avatarUrl']}');
        
        setState(() {
          _localImageUrl = data['avatarUrl'];
          _isLoading = false;
        });

        // Notify parent about the change
        print('BabaPageDPWidget: Calling onImageChanged with: ${data['avatarUrl']}');
        widget.onImageChanged(data['avatarUrl']);

        // Refresh DP from server to ensure consistency
        await refreshDP();

        _showSnackBar('Baba Ji page display picture uploaded successfully!', Colors.green);
      } else {
        print('BabaPageDPWidget: Upload failed: ${response['message']}');
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to upload Baba Ji page display picture',
          Colors.red,
        );
      }
    } catch (e) {
      print('BabaPageDPWidget: Error uploading image: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
    }
  }

  Future<void> _uploadImageWeb(List<int> imageBytes, String fileName) async {
    print('BabaPageDPWidget: Starting web image upload');
    print('BabaPageDPWidget: Baba Page ID: ${widget.babaPageId}');
    print('BabaPageDPWidget: Token available: ${widget.token.isNotEmpty}');
    print('BabaPageDPWidget: Image bytes length: ${imageBytes.length}');
    print('BabaPageDPWidget: File name: $fileName');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a temporary file for web upload
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);
      
      print('BabaPageDPWidget: Calling BabaPageDPService.uploadBabaPageDP');
      final response = await BabaPageDPService.uploadBabaPageDP(
        imageFile: tempFile,
        babaPageId: widget.babaPageId,
        token: widget.token,
      );

      print('BabaPageDPWidget: Web upload response: $response');

      if (response['success'] == true && mounted) {
        final data = response['data'];
        print('BabaPageDPWidget: Web upload successful, data: $data');
        print('BabaPageDPWidget: Web Avatar URL from response: ${data['avatarUrl']}');
        
        setState(() {
          _localImageUrl = data['avatarUrl'];
          _isLoading = false;
        });

        // Notify parent about the change
        print('BabaPageDPWidget: Web calling onImageChanged with: ${data['avatarUrl']}');
        widget.onImageChanged(data['avatarUrl']);

        // Refresh DP from server to ensure consistency
        await refreshDP();

        _showSnackBar('Baba Ji page display picture uploaded successfully!', Colors.green);
      } else {
        print('BabaPageDPWidget: Web upload failed: ${response['message']}');
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to upload Baba Ji page display picture',
          Colors.red,
        );
      }
    } catch (e) {
      print('BabaPageDPWidget: Error uploading web image: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
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
    return Stack(
      children: [
        // Main DP container
        GestureDetector(
          onTap: _isLoading ? null : _handleDPTap,
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
                : _localImageUrl != null && _localImageUrl!.isNotEmpty && _isValidUrl(_localImageUrl!)
                    ? Image.network(
                        _localImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('BabaPageDPWidget: Error loading image: $error');
                          // Return default avatar instead of crashing
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
                      )
                    : _buildDefaultAvatar(),
            ),
          ),
        ),
        
        // Action buttons (only show if there's an image)
        if (_localImageUrl != null && _localImageUrl!.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete button
                GestureDetector(
                  onTap: _isLoading ? null : _deleteImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // View button
                GestureDetector(
                  onTap: _isLoading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullscreenDPViewerScreen(
                          imageUrl: _localImageUrl!,
                          title: 'Profile Picture',
                          subtitle: 'Baba Ji Page',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
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
            widget.borderColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.temple_hindu,
        size: widget.size * 0.5,
        color: widget.borderColor,
      ),
    );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
