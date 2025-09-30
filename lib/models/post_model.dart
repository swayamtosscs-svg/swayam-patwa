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
  final int likesCount; // Add likesCount property
  final int comments;
  final int shares;
  final bool isLiked;
  final bool isSaved;
  final bool isFavourite; // Add isFavourite property
  final bool isFollowing;
  final String? music;
  final String? location;
  final DateTime createdAt;
  final List<String> hashtags;
  final String? thumbnailUrl;
  final bool isBabaJiPost;
  final bool isReel;
  final String? babaPageId;
  final bool isPrivate;

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
    this.likesCount = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isFavourite = false,
    this.isFollowing = false,
    this.music,
    this.location,
    required this.createdAt,
    this.hashtags = const [],
    this.thumbnailUrl,
    this.isBabaJiPost = false,
    this.isReel = false,
    this.babaPageId,
    this.isPrivate = false,
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
      likesCount: json['likesCount'] ?? json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      isFavourite: json['isFavourite'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      music: json['music'],
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      isBabaJiPost: json['isBabaJiPost'] ?? false,
      isReel: json['isReel'] ?? false,
      babaPageId: json['babaPageId'],
      isPrivate: json['isPrivate'] ?? false,
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
      'likesCount': likesCount,
      'comments': comments,
      'shares': shares,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isFavourite': isFavourite,
      'isFollowing': isFollowing,
      'music': music,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'hashtags': hashtags,
      'thumbnailUrl': thumbnailUrl,
      'isBabaJiPost': isBabaJiPost,
      'isReel': isReel,
      'babaPageId': babaPageId,
      'isPrivate': isPrivate,
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
    int? likesCount,
    int? comments,
    int? shares,
    bool? isLiked,
    bool? isSaved,
    bool? isFavourite,
    bool? isFollowing,
    String? music,
    String? location,
    DateTime? createdAt,
    List<String>? hashtags,
    String? thumbnailUrl,
    bool? isBabaJiPost,
    bool? isReel,
    String? babaPageId,
    bool? isPrivate,
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
      likesCount: likesCount ?? this.likesCount,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFavourite: isFavourite ?? this.isFavourite,
      isFollowing: isFollowing ?? this.isFollowing,
      music: music ?? this.music,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      hashtags: hashtags ?? this.hashtags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isBabaJiPost: isBabaJiPost ?? this.isBabaJiPost,
      isReel: isReel ?? this.isReel,
      babaPageId: babaPageId ?? this.babaPageId,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
} 