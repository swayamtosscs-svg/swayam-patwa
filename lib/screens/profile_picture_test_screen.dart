import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/profile_picture_service.dart';

class ProfilePictureTestScreen extends StatefulWidget {
  const ProfilePictureTestScreen({super.key});

  @override
  State<ProfilePictureTestScreen> createState() => _ProfilePictureTestScreenState();
}

class _ProfilePictureTestScreenState extends State<ProfilePictureTestScreen> {
  bool _isLoading = false;
  String? _currentImageUrl;
  String? _publicId;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfilePicture();
  }

  Future<void> _loadCurrentProfilePicture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null || authProvider.userProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProfilePictureService.retrieveProfilePicture(
        userId: authProvider.userProfile!.id,
        token: authProvider.authToken!,
      );

      if (response['success'] == true && mounted) {
        final data = response['data'];
        setState(() {
          _currentImageUrl = data['avatar'];
          _publicId = data['publicId'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      _showSnackBar('Authentication token not found', Colors.red);
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      await _uploadImage(File(image.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await authProvider.uploadProfilePicture(imageFile);

      if (response['success'] == true && mounted) {
        final data = response['data'];
        setState(() {
          _currentImageUrl = data['avatar'];
          _publicId = data['publicId'];
          _isLoading = false;
        });

        _showSnackBar('Profile picture uploaded successfully!', Colors.green);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
          response['message'] ?? 'Failed to upload profile picture',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error uploading image: $e', Colors.red);
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_publicId == null) {
      _showSnackBar('No profile picture to delete', Colors.orange);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
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
      final response = await authProvider.deleteProfilePicture(_publicId!);

      if (response['success'] == true && mounted) {
        setState(() {
          _currentImageUrl = null;
          _publicId = null;
          _isLoading = false;
        });

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
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.userProfile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to test profile picture functionality'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Picture Test'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Current Profile Picture Display
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
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
                    : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                        ? Image.network(
                            _currentImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
              ),
            ),

            const SizedBox(height: 24),

            // Status Information
            if (_currentImageUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(height: 8),
                    const Text(
                      'Profile Picture Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (_publicId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_publicId!.substring(0, 20)}...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'No Profile Picture',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Upload a profile picture to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (_currentImageUrl != null)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _deleteProfilePicture,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // API Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Endpoints Used:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• POST /api/dp/upload - Upload profile picture'),
                  Text('• GET /api/dp/retrieve-simple - Get profile picture'),
                  Text('• DELETE /api/dp/delete-simple - Delete profile picture'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 100,
        color: Colors.blue,
      ),
    );
  }
}

