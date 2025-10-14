import 'package:flutter/material.dart';
import '../models/highlight_model.dart';
import '../models/story_model.dart' as story_model;

class HighlightCard extends StatelessWidget {
  final Highlight highlight;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HighlightCard({
    Key? key,
    required this.highlight,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Highlight cover image (first story's media)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: _buildCoverImage(),
                  ),
                  const SizedBox(width: 12),
                  // Highlight info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          highlight.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          highlight.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.collections_bookmark,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${highlight.storiesCount} stories',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              highlight.isPublic ? Icons.public : Icons.lock,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              highlight.isPublic ? 'Public' : 'Private',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // More options button
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'edit':
                          // Implement edit functionality
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              if (highlight.stories.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Story previews
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: highlight.stories.length > 3 ? 3 : highlight.stories.length,
                    itemBuilder: (context, index) {
                      final story = highlight.stories[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey[300],
                        ),
                        child: _buildStoryPreview(story),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (highlight.stories.isEmpty) {
      return const Icon(
        Icons.collections_bookmark_outlined,
        color: Colors.grey,
        size: 24,
      );
    }

    final firstStory = highlight.stories.first;
    if (firstStory.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          firstStory.media,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image,
              color: Colors.grey,
              size: 24,
            );
          },
        ),
      );
    } else {
      return const Icon(
        Icons.play_circle_outline,
        color: Colors.grey,
        size: 24,
      );
    }
  }

  Widget _buildStoryPreview(story_model.Story story) {
    if (story.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          story.media,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image,
              color: Colors.grey,
              size: 16,
            );
          },
        ),
      );
    } else {
      return const Icon(
        Icons.play_circle_outline,
        color: Colors.grey,
        size: 16,
      );
    }
  }
}


