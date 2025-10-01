import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static CameraController? _cameraController;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;
  static bool _isInitializing = false; // Prevent multiple initialization calls

  // Initialize camera
  static Future<bool> initializeCamera() async {
    try {
      // Prevent multiple initialization calls
      if (_isInitializing) {
        debugPrint('Camera initialization already in progress, skipping...');
        return _isInitialized;
      }
      
      if (_isInitialized) {
        debugPrint('Camera already initialized, skipping...');
        return true;
      }
      
      _isInitializing = true;
      debugPrint('Initializing camera for Live Darshan...');
      
      // Check if running on Windows (camera plugin not supported)
      if (Platform.isWindows) {
        debugPrint('Camera plugin not supported on Windows platform');
        _isInitializing = false;
        return false;
      }
      
      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        debugPrint('Camera permission denied');
        return false;
      }

      // Check microphone permission
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras![0], // Use first camera (usually back camera)
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      _isInitializing = false;
      
      debugPrint('Camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitializing = false;
      return false;
    }
  }

  // Get camera controller
  static CameraController? get cameraController => _cameraController;

  // Check if camera is initialized
  static bool get isInitialized => _isInitialized;

  // Start camera preview
  static Future<void> startPreview() async {
    if (_cameraController != null && _isInitialized) {
      try {
        await _cameraController!.startImageStream((CameraImage image) {
          // Process camera frames for live streaming
          debugPrint('Camera frame received: ${image.width}x${image.height}');
        });
        debugPrint('Camera preview started');
      } catch (e) {
        debugPrint('Error starting camera preview: $e');
      }
    }
  }

  // Stop camera preview
  static Future<void> stopPreview() async {
    if (_cameraController != null) {
      try {
        await _cameraController!.stopImageStream();
        debugPrint('Camera preview stopped');
      } catch (e) {
        debugPrint('Error stopping camera preview: $e');
      }
    }
  }

  // Take photo
  static Future<String?> takePhoto() async {
    if (_cameraController != null && _isInitialized) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        debugPrint('Photo taken: ${photo.path}');
        return photo.path;
      } catch (e) {
        debugPrint('Error taking photo: $e');
        return null;
      }
    }
    return null;
  }

  // Start video recording
  static Future<String?> startVideoRecording() async {
    if (_cameraController != null && _isInitialized) {
      try {
        await _cameraController!.startVideoRecording();
        debugPrint('Video recording started');
        return 'recording';
      } catch (e) {
        debugPrint('Error starting video recording: $e');
        return null;
      }
    }
    return null;
  }

  // Stop video recording
  static Future<String?> stopVideoRecording() async {
    if (_cameraController != null && _isInitialized) {
      try {
        final XFile video = await _cameraController!.stopVideoRecording();
        debugPrint('Video recording stopped: ${video.path}');
        return video.path;
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
        return null;
      }
    }
    return null;
  }

  // Switch camera (front/back)
  static Future<void> switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      try {
        final currentCamera = _cameraController!.description;
        final newCameraIndex = _cameras!.indexOf(currentCamera) == 0 ? 1 : 0;
        
        await _cameraController!.dispose();
        _cameraController = CameraController(
          _cameras![newCameraIndex],
          ResolutionPreset.high,
          enableAudio: true,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _cameraController!.initialize();
        debugPrint('Camera switched to: ${_cameras![newCameraIndex].name}');
      } catch (e) {
        debugPrint('Error switching camera: $e');
      }
    }
  }

  // Get camera info
  static Map<String, dynamic> getCameraInfo() {
    if (_cameraController != null && _isInitialized) {
      return {
        'isInitialized': _isInitialized,
        'cameraName': _cameraController!.description.name,
        'cameraLensDirection': _cameraController!.description.lensDirection.toString(),
        'resolution': '${_cameraController!.value.previewSize?.width}x${_cameraController!.value.previewSize?.height}',
        'isRecording': _cameraController!.value.isRecordingVideo,
        'availableCameras': _cameras?.length ?? 0,
      };
    }
    return {
      'isInitialized': false,
      'error': 'Camera not initialized',
    };
  }

  // Dispose camera
  static Future<void> dispose() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      _isInitialized = false;
      debugPrint('Camera disposed');
    }
  }

  // Check permissions
  static Future<Map<String, bool>> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    
    return {
      'camera': cameraStatus == PermissionStatus.granted,
      'microphone': micStatus == PermissionStatus.granted,
    };
  }

  // Request permissions
  static Future<Map<String, bool>> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    return {
      'camera': cameraStatus == PermissionStatus.granted,
      'microphone': micStatus == PermissionStatus.granted,
    };
  }
}

