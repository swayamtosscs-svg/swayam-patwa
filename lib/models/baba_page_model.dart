class BabaPage {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final String coverImage;
  final String location;
  final String religion;
  final String website;
  final String creatorId; // Added creator field
  final int followersCount;
  final int postsCount;
  final int videosCount;
  final int storiesCount;
  final bool isActive;
  final bool isFollowing;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabaPage({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.coverImage,
    required this.location,
    required this.religion,
    required this.website,
    required this.creatorId,
    required this.followersCount,
    required this.postsCount,
    required this.videosCount,
    required this.storiesCount,
    required this.isActive,
    required this.isFollowing,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabaPage.fromJson(Map<String, dynamic> json) {
    return BabaPage(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avatar: json['avatar'] ?? '',
      coverImage: json['coverImage'] ?? '',
      location: json['location'] ?? '',
      religion: json['religion'] ?? '',
      website: json['website'] ?? '',
      creatorId: json['creatorId'] ?? json['creator'] ?? json['createdBy'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      videosCount: json['videosCount'] ?? 0,
      storiesCount: json['storiesCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isFollowing: json['isFollowing'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'coverImage': coverImage,
      'location': location,
      'religion': religion,
      'website': website,
      'creatorId': creatorId,
      'followersCount': followersCount,
      'postsCount': postsCount,
      'videosCount': videosCount,
      'storiesCount': storiesCount,
      'isActive': isActive,
      'isFollowing': isFollowing,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BabaPage copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    String? coverImage,
    String? location,
    String? religion,
    String? website,
    String? creatorId,
    int? followersCount,
    int? postsCount,
    int? videosCount,
    int? storiesCount,
    bool? isActive,
    bool? isFollowing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabaPage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      location: location ?? this.location,
      religion: religion ?? this.religion,
      website: website ?? this.website,
      creatorId: creatorId ?? this.creatorId,
      followersCount: followersCount ?? this.followersCount,
      postsCount: postsCount ?? this.postsCount,
      videosCount: videosCount ?? this.videosCount,
      storiesCount: storiesCount ?? this.storiesCount,
      isActive: isActive ?? this.isActive,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BabaPageResponse {
  final bool success;
  final String message;
  final BabaPage? data;

  BabaPageResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BabaPageResponse.fromJson(Map<String, dynamic> json) {
    return BabaPageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BabaPage.fromJson(json['data']) : null,
    );
  }
}

class BabaPageRequest {
  final String name;
  final String description;
  final String location;
  final String religion;
  final String website;

  BabaPageRequest({
    required this.name,
    required this.description,
    required this.location,
    required this.religion,
    required this.website,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'religion': religion,
      'website': website,
    };
  }
}

class BabaPageListResponse {
  final bool success;
  final String message;
  final List<BabaPage> pages;
  final PaginationInfo? pagination;

  BabaPageListResponse({
    required this.success,
    required this.message,
    required this.pages,
    this.pagination,
  });

  factory BabaPageListResponse.fromJson(Map<String, dynamic> json) {
    List<BabaPage> pages = [];
    if (json['data'] != null && json['data']['pages'] != null) {
      final List<dynamic> pagesData = json['data']['pages'];
      pages = pagesData.map((pageData) => BabaPage.fromJson(pageData)).toList();
    }

    PaginationInfo? pagination;
    if (json['data'] != null && json['data']['pagination'] != null) {
      pagination = PaginationInfo.fromJson(json['data']['pagination']);
    }

    return BabaPageListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pages: pages,
      pagination: pagination,
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 10,
    );
  }
}

class BabaPageFollowResponse {
  final bool success;
  final String message;
  final BabaPageFollowData? data;

  BabaPageFollowResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BabaPageFollowResponse.fromJson(Map<String, dynamic> json) {
    return BabaPageFollowResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? BabaPageFollowData.fromJson(json['data']) : null,
    );
  }
}

class BabaPageFollowData {
  final String followId;
  final String pageId;
  final String followerId;

  BabaPageFollowData({
    required this.followId,
    required this.pageId,
    required this.followerId,
  });

  factory BabaPageFollowData.fromJson(Map<String, dynamic> json) {
    return BabaPageFollowData(
      followId: json['followId'] ?? '',
      pageId: json['pageId'] ?? '',
      followerId: json['followerId'] ?? '',
    );
  }
}
