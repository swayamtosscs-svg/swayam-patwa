import 'package:flutter/material.dart';

class PostCounterWidget extends StatelessWidget {
  final int totalCount;
  final int visibleCount;
  final String type; // 'images' or 'posts'
  final VoidCallback? onTap;

  const PostCounterWidget({
    super.key,
    required this.totalCount,
    required this.visibleCount,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount <= visibleCount) {
      return const SizedBox.shrink();
    }

    final remainingCount = totalCount - visibleCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'images' ? Icons.photo_library : Icons.grid_view,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '+$remainingCount $type',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
