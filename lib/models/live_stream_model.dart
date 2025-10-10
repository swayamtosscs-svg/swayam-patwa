class LiveRoom {
  final String id;
  final String streamKey;
  final String title;
  final String hostName;
  final String description;
  final String category;
  final List<String> tags;
  final DateTime startTime;
  final bool isLive;
  final String? hostSocketId;
  final String? thumbnail;
  final int maxViewers;
  final bool isPrivate;
  final bool allowChat;
  final bool allowViewerSpeak;
  final int totalViews;
  final int likes;
  final int shares;
  final int duration;
  final String status;
  final String? joinUrl;
  final String? hostUrl;

  LiveRoom({
    required this.id,
    required this.streamKey,
    required this.title,
    required this.hostName,
    required this.description,
    required this.category,
    required this.tags,
    required this.startTime,
    required this.isLive,
    this.hostSocketId,
    this.thumbnail,
    required this.maxViewers,
    required this.isPrivate,
    required this.allowChat,
    required this.allowViewerSpeak,
    required this.totalViews,
    required this.likes,
    required this.shares,
    required this.duration,
    required this.status,
    this.joinUrl,
    this.hostUrl,
  });

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      id: json['id'] ?? '',
      streamKey: json['streamKey'] ?? '',
      title: json['title'] ?? '',
      hostName: json['hostName'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      tags: List<String>.from(json['tags'] ?? []),
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : DateTime.now(),
      isLive: json['isLive'] ?? false,
      hostSocketId: json['hostSocketId'],
      thumbnail: json['thumbnail'],
      maxViewers: json['maxViewers'] ?? 100,
      isPrivate: json['isPrivate'] ?? false,
      allowChat: json['allowChat'] ?? true,
      allowViewerSpeak: json['allowViewerSpeak'] ?? false,
      totalViews: json['totalViews'] ?? 0,
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      duration: json['duration'] ?? 0,
      status: json['status'] ?? 'created',
      joinUrl: json['joinUrl'],
      hostUrl: json['hostUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamKey': streamKey,
      'title': title,
      'hostName': hostName,
      'description': description,
      'category': category,
      'tags': tags,
      'startTime': startTime.toIso8601String(),
      'isLive': isLive,
      'hostSocketId': hostSocketId,
      'thumbnail': thumbnail,
      'maxViewers': maxViewers,
      'isPrivate': isPrivate,
      'allowChat': allowChat,
      'allowViewerSpeak': allowViewerSpeak,
      'totalViews': totalViews,
      'likes': likes,
      'shares': shares,
      'duration': duration,
      'status': status,
      'joinUrl': joinUrl,
      'hostUrl': hostUrl,
    };
  }

  LiveRoom copyWith({
    String? id,
    String? streamKey,
    String? title,
    String? hostName,
    String? description,
    String? category,
    List<String>? tags,
    DateTime? startTime,
    bool? isLive,
    String? hostSocketId,
    String? thumbnail,
    int? maxViewers,
    bool? isPrivate,
    bool? allowChat,
    bool? allowViewerSpeak,
    int? totalViews,
    int? likes,
    int? shares,
    int? duration,
    String? status,
    String? joinUrl,
    String? hostUrl,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      streamKey: streamKey ?? this.streamKey,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      startTime: startTime ?? this.startTime,
      isLive: isLive ?? this.isLive,
      hostSocketId: hostSocketId ?? this.hostSocketId,
      thumbnail: thumbnail ?? this.thumbnail,
      maxViewers: maxViewers ?? this.maxViewers,
      isPrivate: isPrivate ?? this.isPrivate,
      allowChat: allowChat ?? this.allowChat,
      allowViewerSpeak: allowViewerSpeak ?? this.allowViewerSpeak,
      totalViews: totalViews ?? this.totalViews,
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      joinUrl: joinUrl ?? this.joinUrl,
      hostUrl: hostUrl ?? this.hostUrl,
    );
  }

  // Helper getters
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedViews {
    if (totalViews >= 1000000) {
      return '${(totalViews / 1000000).toStringAsFixed(1)}M';
    } else if (totalViews >= 1000) {
      return '${(totalViews / 1000).toStringAsFixed(1)}K';
    } else {
      return totalViews.toString();
    }
  }

  String get formattedLikes {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    } else {
      return likes.toString();
    }
  }

  bool get isActive => isLive && status == 'live';
  bool get isEnded => status == 'ended';
  bool get isScheduled => status == 'scheduled';
}

class LiveRoomCreationRequest {
  final String title;
  final String hostName;
  final String? description;
  final String? category;
  final List<String>? tags;
  final bool isPrivate;
  final int maxViewers;
  final bool allowChat;
  final bool allowViewerSpeak;
  final String? thumbnail;

  LiveRoomCreationRequest({
    required this.title,
    required this.hostName,
    this.description,
    this.category,
    this.tags,
    this.isPrivate = false,
    this.maxViewers = 100,
    this.allowChat = true,
    this.allowViewerSpeak = false,
    this.thumbnail,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'hostName': hostName,
      'description': description ?? '',
      'category': category ?? 'General',
      'tags': tags ?? ['live', 'stream'],
      'isPrivate': isPrivate,
      'maxViewers': maxViewers,
      'allowChat': allowChat,
      'allowViewerSpeak': allowViewerSpeak,
      'thumbnail': thumbnail ?? '',
    };
  }
}

class LiveRoomCreationResponse {
  final String roomId;
  final String streamKey;
  final String message;
  final LiveRoom room;
  final String? joinUrl;
  final String? hostUrl;

  LiveRoomCreationResponse({
    required this.roomId,
    required this.streamKey,
    required this.message,
    required this.room,
    this.joinUrl,
    this.hostUrl,
  });

  factory LiveRoomCreationResponse.fromJson(Map<String, dynamic> json) {
    return LiveRoomCreationResponse(
      roomId: json['roomId'] ?? '',
      streamKey: json['streamKey'] ?? '',
      message: json['message'] ?? '',
      room: LiveRoom.fromJson(json['room'] ?? {}),
      joinUrl: json['joinUrl'],
      hostUrl: json['hostUrl'],
    );
  }
}