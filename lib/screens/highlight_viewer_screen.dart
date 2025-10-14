import 'package:flutter/material.dart';
import '../models/highlight_model.dart';
import '../models/story_model.dart';

class HighlightViewerScreen extends StatefulWidget {
  final Highlight highlight;

  const HighlightViewerScreen({
    Key? key,
    required this.highlight,
  }) : super(key: key);

  @override
  State<HighlightViewerScreen> createState() => _HighlightViewerScreenState();
}

class _HighlightViewerScreenState extends State<HighlightViewerScreen> {
  int _currentStoryIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.highlight.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.highlight.stories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.highlight.name),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_border,
                size: 64,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'No stories in this highlight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    child: widget.highlight.authorAvatar != null && widget.highlight.authorAvatar!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.highlight.authorAvatar!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 16);
                              },
                            ),
                          )
                        : const Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.highlight.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.highlight.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_currentStoryIndex + 1}/${widget.highlight.stories.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress indicator
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  widget.highlight.stories.length,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < widget.highlight.stories.length - 1 ? 2 : 0),
                      height: 2,
                      decoration: BoxDecoration(
                        color: index <= _currentStoryIndex ? Colors.white : Colors.white30,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Story viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStoryIndex = index;
                  });
                },
                itemCount: widget.highlight.stories.length,
                itemBuilder: (context, index) {
                  final story = widget.highlight.stories[index];
                  return _buildStoryView(story);
                },
              ),
            ),
            
            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.reply,
                    label: 'Reply',
                    onTap: () {
                      // Handle reply
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reply feature coming soon')),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.favorite_border,
                    label: 'Like',
                    onTap: () {
                      // Handle like
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Like feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryView(Story story) {
    return GestureDetector(
      onTap: () {
        // Handle tap to pause/resume
      },
      onTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < screenWidth / 3) {
          _previousStory();
        } else if (details.localPosition.dx > screenWidth * 2 / 3) {
          _nextStory();
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: story.type == 'image'
            ? Image.network(
                story.media,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Video playback coming soon',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
