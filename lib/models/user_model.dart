enum Religion {
  hinduism,
  islam,
  christianity,
  buddhism,
  sikhism,
  judaism,
  other,
}

enum UserVerificationStatus {
  unverified,
  pending,
  verified,
  rejected,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? username;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final String? website;
  final String? location;
  final Religion? selectedReligion;
  final DateTime createdAt;
  final DateTime lastActive;
  final UserVerificationStatus verificationStatus;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int reelsCount;
  final List<String> followers;
  final List<String> following;
  final bool isOnline;
  final bool isPrivate;
  final bool isEmailVerified;
  final bool isVerified;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    this.website,
    this.location,
    this.selectedReligion,
    required this.createdAt,
    required this.lastActive,
    this.verificationStatus = UserVerificationStatus.unverified,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.reelsCount = 0,
    this.followers = const [],
    this.following = const [],
    this.isOnline = false,
    this.isPrivate = false,
    this.isEmailVerified = false,
    this.isVerified = false,
    this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? data['_id'] ?? '',
      name: data['fullName'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      username: data['username'],
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['avatar'] ?? data['profileImageUrl'] ?? data['profile_image_url'] ?? '',
      bio: data['bio'] ?? '',
      website: data['website'],
      location: data['location'] ?? '',
      selectedReligion: data['religion'] != null 
          ? Religion.values.firstWhere(
              (e) => e.toString() == 'Religion.${data['religion']}',
              orElse: () => Religion.other,
            )
          : null,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      lastActive: DateTime.tryParse(data['lastActive'] ?? '') ?? DateTime.now(),
      verificationStatus: UserVerificationStatus.values.firstWhere(
        (e) => e.toString() == 'UserVerificationStatus.${data['isVerified'] ?? 'unverified'}',
        orElse: () => UserVerificationStatus.unverified,
      ),
      followersCount: data['followersCount'] ?? data['followers_count'] ?? 0,
      followingCount: data['followingCount'] ?? data['following_count'] ?? 0,
      postsCount: data['postsCount'] ?? data['posts_count'] ?? 0,
      reelsCount: data['reelsCount'] ?? data['reels_count'] ?? 0,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      isOnline: data['isOnline'] ?? data['is_online'] ?? false,
      isPrivate: data['isPrivate'] ?? data['is_private'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? data['is_email_verified'] ?? false,
      isVerified: data['isVerified'] ?? data['is_verified'] ?? false,
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'website': website,
      'location': location,
      'selectedReligion': selectedReligion?.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'verificationStatus': verificationStatus.toString().split('.').last,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'reelsCount': reelsCount,
      'followers': followers,
      'following': following,
      'isOnline': isOnline,
      'isPrivate': isPrivate,
      'isEmailVerified': isEmailVerified,
      'isVerified': isVerified,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    String? website,
    String? location,
    Religion? selectedReligion,
    DateTime? createdAt,
    DateTime? lastActive,
    UserVerificationStatus? verificationStatus,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? reelsCount,
    List<String>? followers,
    List<String>? following,
    bool? isOnline,
    bool? isPrivate,
    bool? isEmailVerified,
    bool? isVerified,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      location: location ?? this.location,
      selectedReligion: selectedReligion ?? this.selectedReligion,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      reelsCount: reelsCount ?? this.reelsCount,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isOnline: isOnline ?? this.isOnline,
      isPrivate: isPrivate ?? this.isPrivate,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
    );
  }

  String get religionDisplayName {
    switch (selectedReligion) {
      case Religion.hinduism:
        return 'Hinduism';
      case Religion.islam:
        return 'Islam';
      case Religion.christianity:
        return 'Christianity';
      case Religion.buddhism:
        return 'Buddhism';
      case Religion.sikhism:
        return 'Sikhism';
      case Religion.judaism:
        return 'Judaism';
      case Religion.other:
        return 'Other';
      default:
        return 'Not Selected';
    }
  }

  String get religionSymbol {
    switch (selectedReligion) {
      case Religion.hinduism:
        return 'ॐ';
      case Religion.islam:
        return '☪';
      case Religion.christianity:
        return '✝';
      case Religion.buddhism:
        return '☸';
      case Religion.sikhism:
        return '☬';
      case Religion.judaism:
        return '✡';
      case Religion.other:
        return '🕉';
      default:
        return '🙏';
    }
  }

  // Getter for fullName to maintain compatibility
  String get fullName => name;
} 

extension ReligionExtension on Religion {
  String get religionDisplayName {
    switch (this) {
      case Religion.hinduism:
        return 'Hinduism';
      case Religion.islam:
        return 'Islam';
      case Religion.christianity:
        return 'Christianity';
      case Religion.buddhism:
        return 'Buddhism';
      case Religion.sikhism:
        return 'Sikhism';
      case Religion.judaism:
        return 'Judaism';
      case Religion.other:
        return 'Other';
      default:
        return 'Not Selected';
    }
  }

  String get religionSymbol {
    switch (this) {
      case Religion.hinduism:
        return 'ॐ';
      case Religion.islam:
        return '☪';
      case Religion.christianity:
        return '✝';
      case Religion.buddhism:
        return '☸';
      case Religion.sikhism:
        return '☬';
      case Religion.judaism:
        return '✡';
      case Religion.other:
        return '🕉';
      default:
        return '🙏';
    }
  }
} 