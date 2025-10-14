import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/highlight_model.dart';
import '../models/story_model.dart';
import '../services/highlight_service.dart';
import '../services/story_service.dart';
import '../providers/auth_provider.dart';

class CreateHighlightScreen extends StatefulWidget {
  final String? preselectedStoryId;
  
  const CreateHighlightScreen({Key? key, this.preselectedStoryId}) : super(key: key);

  @override
  State<CreateHighlightScreen> createState() => _CreateHighlightScreenState();
}

class _CreateHighlightScreenState extends State<CreateHighlightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;
  String? _token;
  List<Story> _availableStories = [];
  List<String> _selectedStoryIds = [];
  bool _storiesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      if (storedToken != null) {
        setState(() {
          _token = storedToken;
        });
        await _loadUserStories();
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authentication token found')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading token: $e')),
      );
    }
  }

  Future<void> _loadUserStories() async {
    if (_token == null) return;

    try {
      setState(() {
        _storiesLoading = true;
      });

      // Get current user ID from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;

      if (userId == null || userId.isEmpty) {
        print('CreateHighlightScreen: No user ID found in AuthProvider');
        setState(() {
          _availableStories = [];
          _storiesLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please login again.')),
        );
        return;
      }

      print('CreateHighlightScreen: Loading stories for user: $userId');
      final stories = await StoryService.getUserStories(userId, token: _token);
      print('CreateHighlightScreen: Loaded ${stories.length} stories');
      
      // Debug: Check story IDs
      for (int i = 0; i < stories.length; i++) {
        final story = stories[i];
        print('CreateHighlightScreen: Story $i - ID: "${story.id}", Type: ${story.type}, Media: ${story.media}');
        if (story.id.isEmpty) {
          print('CreateHighlightScreen: WARNING - Story $i has empty ID!');
        }
      }
      
      // Filter out stories with invalid IDs
      final validStories = stories.where((story) => story.id.isNotEmpty && story.id != 'null').toList();
      print('CreateHighlightScreen: Valid stories: ${validStories.length} out of ${stories.length}');
      
      setState(() {
        _availableStories = validStories;
        _storiesLoading = false;
        
        // Pre-select the story if preselectedStoryId is provided
        if (widget.preselectedStoryId != null) {
          final preselectedStory = validStories.firstWhere(
            (story) => story.id == widget.preselectedStoryId,
            orElse: () => validStories.isNotEmpty ? validStories.first : Story(
              id: '',
              authorId: '',
              authorName: '',
              authorUsername: '',
              authorAvatar: '',
              media: '',
              mediaId: '',
              type: '',
              mentions: [],
              hashtags: [],
              isActive: false,
              views: [],
              viewsCount: 0,
              expiresAt: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          if (preselectedStory.id.isNotEmpty) {
            _selectedStoryIds.add(preselectedStory.id);
            print('CreateHighlightScreen: Pre-selected story: ${preselectedStory.id}');
          }
        }
      });
    } catch (e) {
      print('CreateHighlightScreen: Error loading stories: $e');
      setState(() {
        _availableStories = [];
        _storiesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stories: $e')),
      );
    }
  }

  Future<void> _createHighlight() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one story')),
      );
      return;
    }

    if (_token == null) return;

    // Filter out empty or invalid story IDs
    final validStoryIds = _selectedStoryIds.where((id) => id.isNotEmpty && id != 'null').toList();
    
    if (validStoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid stories')),
      );
      return;
    }

    print('CreateHighlightScreen: Creating highlight with ${validStoryIds.length} valid story IDs');
    print('CreateHighlightScreen: Story IDs: $validStoryIds');

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HighlightService.createHighlight(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        storyIds: validStoryIds,
        isPublic: _isPublic,
        token: _token!,
      );

      if (response.success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highlight created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create highlight: ${response.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating highlight: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Highlight'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createHighlight,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: _storiesLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableStories.isEmpty
              ? _buildNoStoriesView()
              : _buildForm(),
    );
  }

  Widget _buildNoStoriesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.collections_bookmark_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No stories available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create some stories first to add them to highlights',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Highlight name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Highlight Name',
                hintText: 'Enter highlight name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a highlight name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Privacy setting
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      title: const Text('Public'),
                      subtitle: const Text('Anyone can see this highlight'),
                      value: true,
                      groupValue: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value!;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Private'),
                      subtitle: const Text('Only you can see this highlight'),
                      value: false,
                      groupValue: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stories selection
            const Text(
              'Select Stories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose stories to add to this highlight (${_selectedStoryIds.length} selected)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),

            // Stories grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _availableStories.length,
              itemBuilder: (context, index) {
                final story = _availableStories[index];
                final isSelected = _selectedStoryIds.contains(story.id);
                
                return GestureDetector(
                  onTap: () {
                    // Only allow selection of stories with valid IDs
                    if (story.id.isEmpty || story.id == 'null') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This story cannot be selected')),
                      );
                      return;
                    }
                    
                    setState(() {
                      if (isSelected) {
                        _selectedStoryIds.remove(story.id);
                      } else {
                        _selectedStoryIds.add(story.id);
                      }
                    });
                    
                    print('CreateHighlightScreen: Story ${story.id} ${isSelected ? 'deselected' : 'selected'}');
                    print('CreateHighlightScreen: Selected story IDs: $_selectedStoryIds');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Story media
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: story.type == 'image'
                              ? Image.network(
                                  story.media,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.play_circle_outline),
                                ),
                        ),
                        // Selection indicator
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


