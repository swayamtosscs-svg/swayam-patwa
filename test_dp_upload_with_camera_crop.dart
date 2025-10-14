import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

/// Test file to verify DP upload with camera and crop functionality
/// This file demonstrates the new features implemented:
/// 1. Camera capture option
/// 2. Gallery selection option  
/// 3. Image cropping functionality
/// 4. Improved UI with source selection dialog

class DPUploadTestScreen extends StatefulWidget {
  const DPUploadTestScreen({Key? key}) : super(key: key);

  @override
  State<DPUploadTestScreen> createState() => _DPUploadTestScreenState();
}

class _DPUploadTestScreenState extends State<DPUploadTestScreen> {
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DP Upload Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profile Picture Upload Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Display selected image
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _selectedImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_selectedImagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Text('No image selected'),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // Test buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testImageSourceDialog,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Test Image Source Dialog'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCameraCapture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Test Camera Capture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testGallerySelection,
              icon: const Icon(Icons.photo_library),
              label: const Text('Test Gallery Selection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testImageCropping,
              icon: const Icon(Icons.crop),
              label: const Text('Test Image Cropping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            const SizedBox(height: 20),
            
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Test Image Source Dialog" to see the new dialog'),
                    Text('2. Tap "Test Camera Capture" to test camera functionality'),
                    Text('3. Tap "Test Gallery Selection" to test gallery selection'),
                    Text('4. Tap "Test Image Cropping" to test cropping (requires image)'),
                    SizedBox(height: 8),
                    Text(
                      'Features Implemented:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('✓ Camera capture option'),
                    Text('✓ Gallery selection option'),
                    Text('✓ Image cropping with square aspect ratio'),
                    Text('✓ Improved UI with source selection dialog'),
                    Text('✓ Better image quality settings'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testImageSourceDialog() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source != null) {
      _showSnackBar('Selected: ${source == ImageSource.camera ? 'Camera' : 'Gallery'}');
    }
  }

  Future<void> _testCameraCapture() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _testGallerySelection() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _testImageCropping() async {
    if (_selectedImagePath == null) {
      _showSnackBar('Please select an image first');
      return;
    }
    
    await _cropImage(File(_selectedImagePath!));
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
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
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

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _isLoading = false;
        });
        _showSnackBar('Image selected: ${image.name}');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('No image selected');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _cropImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.blue,
            cropFrameColor: Colors.blue,
            cropGridColor: Colors.blue.withOpacity(0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
            hideBottomControls: false,
            showCropGrid: true,
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
        setState(() {
          _selectedImagePath = croppedFile.path;
          _isLoading = false;
        });
        _showSnackBar('Image cropped successfully');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Cropping cancelled');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Cropping error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Main function to run the test
void main() {
  runApp(const MaterialApp(
    home: DPUploadTestScreen(),
  ));
}
