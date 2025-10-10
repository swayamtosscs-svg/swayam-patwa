import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/live_stream_provider.dart';
import '../providers/auth_provider.dart';
import '../models/live_stream_model.dart';
import '../utils/app_theme.dart';

class CreateLiveStreamScreen extends StatefulWidget {
  const CreateLiveStreamScreen({super.key});

  @override
  State<CreateLiveStreamScreen> createState() => _CreateLiveStreamScreenState();
}

class _CreateLiveStreamScreenState extends State<CreateLiveStreamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'General';
  bool _isPrivate = false;
  bool _allowChat = true;
  bool _allowViewerSpeak = false;
  int _maxViewers = 100;
  String? _thumbnail;

  final List<String> _categories = [
    'General',
    'Gaming',
    'Music',
    'Education',
    'Sports',
    'Technology',
    'Entertainment',
    'News',
    'Spiritual',
    'Other',
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
        title: const Text(
          'Create Live Stream',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<LiveStreamProvider, AuthProvider>(
        builder: (context, liveProvider, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  _buildSectionTitle('Stream Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter your stream title',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Poppins',
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a stream title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description Field
                  _buildSectionTitle('Description (Optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe what your stream is about',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'Poppins',
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Category Selection
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  _buildSectionTitle('Stream Settings'),
                  const SizedBox(height: 16),
                  
                  // Privacy Setting
                  _buildSwitchTile(
                    title: 'Private Stream',
                    subtitle: 'Only invited viewers can watch',
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                  ),
                  
                  // Chat Setting
                  _buildSwitchTile(
                    title: 'Allow Chat',
                    subtitle: 'Viewers can send messages',
                    value: _allowChat,
                    onChanged: (value) {
                      setState(() {
                        _allowChat = value;
                      });
                    },
                  ),
                  
                  // Viewer Speak Setting
                  _buildSwitchTile(
                    title: 'Allow Viewer Speak',
                    subtitle: 'Viewers can speak during stream',
                    value: _allowViewerSpeak,
                    onChanged: (value) {
                      setState(() {
                        _allowViewerSpeak = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Max Viewers Setting
                  _buildSectionTitle('Maximum Viewers'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _maxViewers,
                        isExpanded: true,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        items: [50, 100, 200, 500, 1000].map((count) {
                          return DropdownMenuItem<int>(
                            value: count,
                            child: Text('$count viewers'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _maxViewers = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: liveProvider.isLoading ? null : _createLiveRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: liveProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Live Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Error Message
                  if (liveProvider.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        liveProvider.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _createLiveRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final liveProvider = Provider.of<LiveStreamProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await liveProvider.createLiveRoom(
      title: _titleController.text.trim(),
      hostName: authProvider.userProfile?.name ?? 'Anonymous',
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      tags: _getTagsForCategory(_selectedCategory),
      isPrivate: _isPrivate,
      maxViewers: _maxViewers,
      allowChat: _allowChat,
      allowViewerSpeak: _allowViewerSpeak,
      thumbnail: _thumbnail,
      authToken: authProvider.authToken,
    );

    if (result['success'] == true && mounted) {
      // Navigate to live stream screen or show success
      Navigator.of(context).pop(result);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Live room created successfully!',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  List<String> _getTagsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'gaming':
        return ['gaming', 'live', 'fun', 'entertainment'];
      case 'music':
        return ['music', 'live', 'performance', 'entertainment'];
      case 'education':
        return ['education', 'learning', 'tutorial', 'knowledge'];
      case 'sports':
        return ['sports', 'live', 'fitness', 'health'];
      case 'technology':
        return ['technology', 'tech', 'programming', 'innovation'];
      case 'spiritual':
        return ['spiritual', 'meditation', 'peace', 'mindfulness'];
      default:
        return ['live', 'stream', 'entertainment'];
    }
  }
}
