import 'package:flutter/material.dart';

enum PostType { image, video, reel }

class Post {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String? caption;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> imageUrls; // Support for multiple images
  final PostType type;
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final String? music;
  final String? location;
  final DateTime createdAt;
  final List<String> hashtags;
  final String? thumbnailUrl;
  final bool isBabaJiPost;
  final bool isReel;
  final String? babaPageId;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    this.caption,
    this.imageUrl,
    this.videoUrl,
    this.imageUrls = const [],
    required this.type,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.music,
    this.location,
    required this.createdAt,
    this.hashtags = const [],
    this.thumbnailUrl,
    this.isBabaJiPost = false,
    this.isReel = false,
    this.babaPageId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      userAvatar: json['userAvatar'],
      caption: json['caption'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      type: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${json['type']}',
        orElse: () => PostType.image,
      ),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      music: json['music'],
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      isBabaJiPost: json['isBabaJiPost'] ?? false,
      isReel: json['isReel'] ?? false,
      babaPageId: json['babaPageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'caption': caption,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls,
      'type': type.toString().split('.').last,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isFollowing': isFollowing,
      'music': music,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'hashtags': hashtags,
      'thumbnailUrl': thumbnailUrl,
      'isBabaJiPost': isBabaJiPost,
      'isReel': isReel,
      'babaPageId': babaPageId,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? caption,
    String? imageUrl,
    String? videoUrl,
    List<String>? imageUrls,
    PostType? type,
    int? likes,
    int? comments,
    int? shares,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    String? music,
    String? location,
    DateTime? createdAt,
    List<String>? hashtags,
    String? thumbnailUrl,
    bool? isBabaJiPost,
    bool? isReel,
    String? babaPageId,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      music: music ?? this.music,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      hashtags: hashtags ?? this.hashtags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isBabaJiPost: isBabaJiPost ?? this.isBabaJiPost,
      isReel: isReel ?? this.isReel,
      babaPageId: babaPageId ?? this.babaPageId,
    );
  }
} 