import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/post_widget.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/following_screen.dart';
import '../screens/followers_screen.dart';
import '../utils/app_theme.dart';
import '../services/user_media_service.dart';
import '../services/chat_service.dart';
import '../screens/user_profile_screen.dart'; // Added import for UserProfileScreen
import '../screens/chat_screen.dart'; // Added import for ChatScreen
import '../widgets/dp_widget.dart'; // Added import for DPWidget
import '../screens/post_full_view_screen.dart';
import '../widgets/profile_reel_widget.dart';
import '../widgets/verification_badge.dart';
import '../screens/verification_request_screen.dart';
import '../services/verification_service.dart';
import '../models/verification_model.dart';
import '../models/highlight_model.dart';
import '../services/highlight_service.dart';
import '../screens/highlights_screen.dart';
import '../screens/create_highlight_screen.dart';
import '../screens/highlight_viewer_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Instagram-style: Posts, Reels, Saved
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userProfile;
      final token = authProvider.authToken;

      if (user != null && token != null) {
        final response = await VerificationService.getVerificationStatus(
          userId: user.id,
          token: token,
        );

        if (response.success && response.data != null) {
          // Update user verification status if needed
          if (response.data!.isVerified != user.isVerified) {
            // You might want to update the user profile here
            print('Verification status updated: ${response.data!.isVerified}');
          }
        }
      }
    } catch (e) {
      print('Error checking verification status: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: _buildInstagramStyleAppBar(authProvider.userProfile!),
          body: RefreshIndicator(
            onRefresh: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.refreshUserProfile();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildElegantProfileHeader(authProvider.userProfile!),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 8 : 12),
                  _buildRoundedSegmentedTabBar(),
                  _buildTabContent(authProvider.userProfile!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildInstagramStyleAppBar(UserModel user) {
    return AppBar(
      backgroundColor: const Color(0xFFF0EBE1), // Same as login page background
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      title: Row(
        children: [
          Text(
            user.username ?? 'username',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          // Verified badge (if user is verified)
          if (user.isVerified)
            const Icon(
              Icons.verified,
              color: Colors.blue,
              size: 16,
            ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black, size: 24),
          tooltip: 'More options',
          onSelected: (String value) {
            if (value == 'edit_profile') {
              _navigateToEditProfile(user);
            } else if (value == 'logout') {
              _showLogoutDialog(context);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'edit_profile',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF1A1A1A), size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFE53E3E), size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElegantProfileHeader(UserModel user) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600; // Mobile detection
    final mobilePadding = isMobile ? 8.0 : 18.0;
    final mobileMargin = isMobile ? 12.0 : 18.0;
    final mobileTopPadding = isMobile ? 40.0 : 72.0;
    final mobileSpacing = isMobile ? 8.0 : 16.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(mobileMargin, mobileMargin, mobileMargin, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEBF6FF), Color(0xFFF5E9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: isMobile ? 12 : 18, offset: const Offset(0, 8)),
            ],
          ),
          padding: EdgeInsets.only(top: mobileTopPadding, bottom: mobilePadding, left: mobilePadding, right: mobilePadding),
          child: Column(
            children: [
              SizedBox(height: isMobile ? 24 : 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
                  ),
                  SizedBox(width: isMobile ? 4 : 8),
                  if (user.isVerified)
                    Container(
                      padding: EdgeInsets.all(isMobile ? 2 : 4),
                      decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                      child: Icon(Icons.verified, size: isMobile ? 12 : 16, color: Colors.white),
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text('@${user.username}', style: TextStyle(color: const Color(0xFF666666), fontSize: isMobile ? 12 : 14)),
              SizedBox(height: isMobile ? 8 : 12),
              Wrap(
                spacing: isMobile ? 4 : 8,
                alignment: WrapAlignment.center,
                children: [
                  _tag('[ ${user.selectedReligion?.name.toUpperCase() ?? 'RELIGION'} ]', Colors.orange.shade100, Colors.orange.shade700),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 14),
              if (user.bio != null && user.bio!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
                  child: Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0xFF6B7280), height: 1.35, fontSize: isMobile ? 12 : 14),
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(height: isMobile ? 8 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _pillButton('Connect & Follow', onTap: () {}),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 14),
              FutureBuilder<UserMediaResponse>(
                future: UserMediaService.getUserMedia(userId: user.id),
                builder: (context, snapshot) {
                  int postsCount = user.postsCount;
                  int reelsCount = 0;
                  
                  if (snapshot.hasData && snapshot.data!.success) {
                    postsCount = snapshot.data!.posts.length;
                    reelsCount = snapshot.data!.reels.length;
                  }
                  
                  return Row(
                    children: [
                      Expanded(child: _smallStat(icon: Icons.grid_on, value: postsCount.toString(), label: 'Posts', color: Colors.blue.shade50)),
                      Expanded(child: _smallStat(icon: Icons.slow_motion_video_outlined, value: reelsCount.toString(), label: 'Reels', color: Colors.green.shade50)),
                      Expanded(
                        child: _buildFollowersStat(user),
                      ),
                      Expanded(
                        child: _buildFollowingStat(user),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: isMobile ? 12 : 20),
              // Highlights Section
              _buildHighlightsSection(user),
              const SizedBox(height: 20),
              // Action Buttons Section
              _buildActionButtons(user),
            ],
          ),
        ),
        Positioned(
          top: 4,
          left: (width / 2) - 62,
          child: _glowingAvatar(imageUrl: user.profileImageUrl, size: 124),
        ),
      ],
    );
  }

  Widget _tag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _glowingAvatar({String? imageUrl, double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 18, spreadRadius: 6),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white,
        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
            ? NetworkImage(imageUrl)
            : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _pillButton(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE6FFF6),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: const Color(0xFF99F6E4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_add_alt_1, size: 18, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text(
              'Connect & Follow',
              style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallStat({required IconData icon, required String value, required String label, required Color color, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(12),
            boxShadow: onTap != null ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 18),
                  const Spacer(),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowersStat(UserModel user) {
    return FutureBuilder<Map<String, int>>(
      future: Provider.of<AuthProvider>(context, listen: false).getUserCounts(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _smallStat(
            icon: Icons.groups_outlined, 
            value: '...', 
            label: 'Followers', 
            color: Colors.orange.shade50,
            onTap: () {},
          );
        }
        
        int followersCount = user.followersCount; // Fallback to cached count
        
        if (snapshot.hasData) {
          followersCount = snapshot.data!['followers'] ?? user.followersCount;
          print('ProfileScreen: Real followers count: $followersCount');
        } else if (snapshot.hasError) {
          print('ProfileScreen: Error fetching followers: ${snapshot.error}');
          // Keep using cached count on error
        }
        
        return _smallStat(
          icon: Icons.groups_outlined, 
          value: '$followersCount', 
          label: 'Followers', 
          color: Colors.orange.shade50,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowersScreen(userId: user.id),
              ),
            );
            // Refresh user profile when returning to get updated counts
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.refreshUserProfile();
            // Also refresh the current screen to show updated counts
            if (mounted) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  Widget _buildFollowingStat(UserModel user) {
    return FutureBuilder<Map<String, int>>(
      future: Provider.of<AuthProvider>(context, listen: false).getUserCounts(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _smallStat(
            icon: Icons.person_add_alt_1_outlined, 
            value: '...', 
            label: 'Following', 
            color: Colors.purple.shade50,
            onTap: () {},
          );
        }
        
        int followingCount = user.followingCount; // Fallback to cached count
        
        if (snapshot.hasData) {
          followingCount = snapshot.data!['following'] ?? user.followingCount;
          print('ProfileScreen: Real following count: $followingCount');
        } else if (snapshot.hasError) {
          print('ProfileScreen: Error fetching following: ${snapshot.error}');
          // Keep using cached count on error
        }
        
        return _smallStat(
          icon: Icons.person_add_alt_1_outlined, 
          value: '$followingCount', 
          label: 'Following', 
          color: Colors.purple.shade50,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowingScreen(userId: user.id),
              ),
            );
            // Refresh user profile when returning to get updated counts
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await authProvider.refreshUserProfile();
            // Also refresh the current screen to show updated counts
            if (mounted) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundedSegmentedTabBar() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final mobileMargin = isMobile ? 12.0 : 18.0;
    final mobilePadding = isMobile ? 2.0 : 4.0;
    
    return Container(
      margin: EdgeInsets.fromLTRB(mobileMargin, isMobile ? 8 : 12, mobileMargin, isMobile ? 4 : 8),
      padding: EdgeInsets.all(mobilePadding),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(isMobile ? 20 : 30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: isMobile ? 8 : 12, offset: const Offset(0, 6))]
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFE6FFF6), 
          borderRadius: BorderRadius.circular(isMobile ? 16 : 24), 
          boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.35), blurRadius: isMobile ? 6 : 10, offset: const Offset(0, 4))]
        ),
        labelColor: const Color(0xFF0F766E),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
        tabs: [
          Tab(text: 'Posts', icon: Icon(Icons.grid_on, size: isMobile ? 16 : 20)),
          Tab(text: 'Reels', icon: Icon(Icons.play_circle_outline, size: isMobile ? 16 : 20)),
          Tab(text: 'Tagged', icon: Icon(Icons.bookmark_border, size: isMobile ? 16 : 20)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isRefreshing ? null : () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    
                    try {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.refreshUserProfile();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile refreshed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to refresh profile: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
                    }
                  },
                  icon: _isRefreshing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
                ),
                
                
                // Message Button (only show if not own profile)
                if (Provider.of<AuthProvider>(context, listen: false).userProfile?.id != user.id)
                  IconButton(
                    onPressed: () async {
                      // Add conversation to local storage
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userProfile != null) {
                        await ChatService.addConversation(
                          currentUserId: authProvider.userProfile!.id,
                          otherUserId: user.id,
                          otherUsername: user.username ?? '',
                          otherFullName: user.name,
                          otherAvatar: '',
                        );
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientUserId: user.id,
                            recipientUsername: user.username ?? '',
                            recipientFullName: user.name,
                            recipientAvatar: '',
                            threadId: null, // New conversation
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, color: Color(0xFF6366F1)),
                    tooltip: 'Send Message',
                  ),
              ],
            ),
          ),
          
          // Profile Content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getReligionColor(user.selectedReligion).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Display Picture Widget
                DPWidget(
                  currentImageUrl: user.profileImageUrl,
                  userId: user.id,
                  token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
                  userName: user.fullName, // Pass user name for default avatar
                  onImageChanged: (String newImageUrl) async {
                    print('ProfileScreen: DP changed to: $newImageUrl');
                    // Update the user profile with new image URL
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.userProfile != null) {
                      print('ProfileScreen: Updating local user profile');
                      final updatedUser = authProvider.userProfile!.copyWith(
                        profileImageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                      );
                      print('ProfileScreen: Updated user profile image: ${updatedUser.profileImageUrl}');
                      authProvider.updateLocalUserProfile(updatedUser);
                    } else {
                      print('ProfileScreen: No user profile found in auth provider');
                    }
                  },
                  size: 120,
                  borderColor: _getReligionColor(user.selectedReligion),
                  showEditButton: true,
                ),
                
                
                const SizedBox(height: 16),
                
                // User Name and Verification
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (user.isVerified)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Username
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bio
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Website
                if (user.website != null && user.website!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.link,
                          size: 16,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.website!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6366F1),
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Privacy Toggle Button
                _buildPrivacyToggleButton(user),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildProfileStats(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Posts', '0'),
                ),
                Expanded(
                  child: _buildStatItem('Reels', '0'),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: authProvider.getFollowersForUser(user.id),
                    builder: (context, snapshot) {
                      int followersCount = user.followersCount;
                      if (snapshot.hasData) {
                        followersCount = snapshot.data!.length;
                      }
                      return _buildStatItem('Followers', followersCount.toString());
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: authProvider.getFollowingUsersForUser(user.id),
                    builder: (context, snapshot) {
                      int followingCount = user.followingCount;
                      if (snapshot.hasData) {
                        followingCount = snapshot.data!.length;
                      }
                      return _buildStatItem('Following', followingCount.toString());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

            return FutureBuilder<UserMediaResponse>(
          future: UserMediaService.getUserMedia(userId: user.id),
          builder: (context, snapshot) {
            // Debug: Log the user ID being used
            print('ProfileScreen Stats: Using user ID: ${user.id} for ${user.username}');
        
        int postsCount = 0;
        int reelsCount = 0;
        
        if (snapshot.hasData && snapshot.data!.success) {
          postsCount = snapshot.data!.posts.length;
          reelsCount = snapshot.data!.reels.length;
          
          // Debug logging
          print('Profile Stats: Total posts: ${snapshot.data!.posts.length}, Image posts: $postsCount, Reels: $reelsCount');
          for (final post in snapshot.data!.posts) {
            print('Profile Stats Post: ${post.id} - Type: ${post.type} - Caption: ${post.caption}');
          }
        } else {
          print('ProfileScreen Stats: No data or failed for user ${user.id}');
          if (snapshot.hasError) {
            print('ProfileScreen Stats: Error: ${snapshot.error}');
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItemWithCount('Posts', postsCount.toString(), () => _setTabIndex(0)),
                  ),
                  Expanded(
                    child: _buildStatItemWithCount('Reels', reelsCount.toString(), () => _setTabIndex(1)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersScreen(userId: user.id),
                          ),
                        );
                      },
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: Provider.of<AuthProvider>(context, listen: false).getFollowersForUser(user.id),
                        builder: (context, snapshot) {
                          int followersCount = user.followersCount;
                          if (snapshot.hasData) {
                            followersCount = snapshot.data!.length;
                          }
                          return _buildStatItem('Followers', followersCount.toString());
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowingScreen(userId: user.id),
                          ),
                        );
                      },
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: Provider.of<AuthProvider>(context, listen: false).getFollowingUsersForUser(user.id),
                        builder: (context, snapshot) {
                          int followingCount = user.followingCount;
                          if (snapshot.hasData) {
                            followingCount = snapshot.data!.length;
                          }
                          return _buildStatItem('Following', followingCount.toString());
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Privacy Status Indicator
              _buildPrivacyStatusIndicator(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrivacyStatusIndicator(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: user.isPrivate ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isPrivate ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            user.isPrivate ? Icons.lock : Icons.public,
            color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Text(
            user.isPrivate ? 'Private Account' : 'Public Account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _setTabIndex(int index) {
    _tabController.animateTo(index);
  }

  Widget _buildStatItemWithCount(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 2, color: Color(0xFF6366F1)),
          ),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF666666),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          tabs: const [
            Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Reels'),
            Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
          ],
        ),
    );
  }

  Widget _buildTabContent(UserModel user) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Calculate available height more intelligently for mobile
    double availableHeight;
    if (isMobile) {
      // For mobile: Use remaining space after header, tabs, and bottom navigation
      availableHeight = screenHeight * 0.45; // Reduced from 0.6 to 0.45
    } else {
      // For desktop: Use original calculation
      availableHeight = screenHeight * 0.6;
    }
    
    return Container(
        height: availableHeight,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(user),
            _buildReelsTab(user),
            _buildSavedTab(),
          ],
        ),
    );
  }

  Widget _buildPostsTab(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      return const Center(
        child: Text('Please login to view posts'),
      );
    }
    
            return FutureBuilder<UserMediaResponse>(
          future: UserMediaService.getUserMedia(userId: user.id),
          builder: (context, snapshot) {
            // Debug: Log the user ID being used for posts tab
            print('ProfileScreen Posts Tab: Using user ID: ${user.id} for ${user.username}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('ProfileScreen Posts Tab: Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading posts: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final userMedia = snapshot.data;
        if (userMedia == null || !userMedia.success) {
          print('ProfileScreen Posts Tab: No data or failed for user ${user.id}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load posts: Unknown error'),
              ],
            ),
          );
        }
        
        // Get only image posts
        final posts = userMedia.posts;
        
        // Debug logging
        print('ProfileScreen Posts Tab: Found ${posts.length} posts from API for user ${user.id}');
        for (final post in posts) {
          print('ProfileScreen Posts Tab Post: ${post.id} - ${post.caption} - ${post.imageUrl} - Type: ${post.type}');
        }
        
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No posts yet'),
                Text('Share your first post!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isSmallScreen = maxHeight < 600;
            
            return Container(
              height: maxHeight,
              child: GridView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to full screen post view
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostFullViewScreen(post: post),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6)),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: post.imageUrl != null
                              ? Image.network(
                                  post.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                      ),
                                    );
                                  },
                                )
                              : Container(color: Colors.grey[200]),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle, boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3)),
                            ]),
                            child: const Icon(Icons.more_horiz, size: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReelsTab(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      return const Center(
        child: Text('Please login to view reels'),
      );
    }
    
    return FutureBuilder<UserMediaResponse>(
      future: UserMediaService.getUserMedia(userId: user.id),
      builder: (context, snapshot) {
        // Debug: Log the username being used for reels tab
        print('ProfileScreen Reels Tab: Using username: ${user.username} for ${user.id}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('ProfileScreen Reels Tab: Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading reels: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final userMedia = snapshot.data;
        if (userMedia == null || !userMedia.success) {
          print('ProfileScreen Reels Tab: No data or failed for username: ${user.username}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load reels: Unknown error'),
              ],
            ),
          );
        }
        
        // Get only reels (videos)
        final reels = userMedia.reels;
        
        // Debug logging
        print('ProfileScreen Reels Tab: Found ${reels.length} reels from API for username: ${user.username}');
        for (final reel in reels) {
          print('ProfileScreen Reels Tab Reel: ${reel.id} - ${reel.caption} - ${reel.videoUrl} - Type: ${reel.type}');
        }
        
        if (reels.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No reels yet'),
                Text('Share your first reel!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isSmallScreen = maxHeight < 600;
            
            return Container(
              height: maxHeight,
              child: GridView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: reels.length,
                itemBuilder: (context, index) {
                  final reel = reels[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to full screen post view
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostFullViewScreen(post: reel),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6)),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ProfileReelWidget(
                            reel: reel,
                            showThumbnail: true,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle, boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3)),
                            ]),
                            child: const Icon(Icons.play_arrow, size: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildSavedTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<AuthProvider>(context, listen: false).getSavedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading saved posts: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final postsData = snapshot.data ?? [];
        
        if (postsData.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No saved posts yet'),
                Text('Save posts to view them later!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Fixed height
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: postsData.length,
            itemBuilder: (context, index) {
              final postData = postsData[index];
              final post = _createPostFromData(postData);
              return PostWidget(
                post: post,
                onComment: () {
                  // Handle comment
                },
                onShare: () {
                  // Handle share
                },
                onUserTap: () {
                  _navigateToUserProfile(post);
                },
                onDelete: () {
                  // Remove the deleted post from the list and refresh
                  setState(() {
                    postsData.removeWhere((p) => p['id'] == post.id || p['_id'] == post.id);
                  });
                  print('Post deleted: ${post.id}');
                },
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to create Post objects from API data
  Post _createPostFromData(Map<String, dynamic> postData) {
    return Post(
      id: postData['id'] ?? postData['_id'] ?? '',
      userId: postData['userId'] ?? postData['user_id'] ?? '',
      username: postData['username'] ?? '',
      userAvatar: postData['userAvatar'] ?? postData['user_avatar'] ?? '',
      caption: postData['caption'] ?? '',
      imageUrl: postData['imageUrl'] ?? postData['image_url'],
      videoUrl: postData['videoUrl'] ?? postData['video_url'],
      type: _parsePostType(postData['type'] ?? 'image'),
      likes: postData['likes'] ?? postData['likesCount'] ?? 0,
      comments: postData['comments'] ?? postData['commentsCount'] ?? 0,
      shares: postData['shares'] ?? postData['sharesCount'] ?? 0,
      createdAt: postData['createdAt'] != null 
          ? DateTime.parse(postData['createdAt']) 
          : DateTime.now(),
      hashtags: List<String>.from(postData['hashtags'] ?? []),
    );
  }

  // Helper method to parse post type
  PostType _parsePostType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.image;
    }
  }

  // Helper methods
  Color _getReligionColor(Religion? religion) {
    switch (religion) {
      case Religion.hinduism:
        return Colors.orange;
      case Religion.islam:
        return Colors.green;
      case Religion.christianity:
        return Colors.blue;
      case Religion.buddhism:
        return Colors.purple;
      case Religion.sikhism:
        return Colors.amber;
      case Religion.judaism:
        return Colors.indigo;
      case Religion.other:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _navigateToEditProfile(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(user: user),
      ),
    );
    
    if (result == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();
      
      if (mounted) {
        // Force UI refresh to show updated profile picture
        setState(() {});
        
        // Add a small delay to ensure the profile data is fully updated
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Force another refresh to ensure DPWidget gets the updated data
        if (mounted) {
          setState(() {});
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                // Close dialog first
                Navigator.of(context).pop();
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Logging out...'),
                        ],
                      ),
                    );
                  },
                );
                
                try {
                  // Call logout
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  
                  // Close loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  // Navigate to signup screen (as requested by user)
                  if (mounted) {
                    // Show immediate feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logging out...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    
                    // Immediately redirect to login page
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    
                    // Logout in background (don't wait for it)
                    authProvider.logout().catchError((e) {
                      print('Background logout error: $e');
                    });
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userProfile;
    
    final List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem(
        value: 'edit_profile',
        child: Text('Edit Profile'),
      ),
      // Verification Request Menu Item (always show for all users)
      if (user != null)
        PopupMenuItem(
          value: 'verification_request',
          child: Row(
            children: [
              const Icon(
                Icons.verified_user,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                user.isVerified ? 'Verification Status' : 'Request Verification',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      const PopupMenuItem(
        value: 'followers',
        child: Text('Followers'),
      ),
      const PopupMenuItem(
        value: 'following',
        child: Text('Following'),
      ),

      const PopupMenuDivider(), // Add separator
      // Privacy Toggle Menu Item
      if (user != null)
        PopupMenuItem(
          value: 'toggle_privacy',
          child: Row(
            children: [
              Icon(
                user.isPrivate ? Icons.lock : Icons.public,
                color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                user.isPrivate ? 'Make Public' : 'Make Private',
                style: TextStyle(
                  color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      const PopupMenuDivider(), // Add separator
      const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFE53E3E)),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(color: Color(0xFFE53E3E))),
          ],
        ),
      ),
    ];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 100,
        MediaQuery.of(context).size.height - 100,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
      items: menuItems,
    ).then((value) {
      if (value == 'edit_profile') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userProfile!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileEditScreen(user: user),
          ),
        );
      } else if (value == 'followers') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowersScreen(userId: Provider.of<AuthProvider>(context, listen: false).userProfile!.id),
          ),
        );
      } else if (value == 'following') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowingScreen(userId: Provider.of<AuthProvider>(context, listen: false).userProfile!.id),
          ),
        );
      } else if (value == 'verification_request') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userProfile;
        
        if (user != null) {
          if (user.isVerified) {
            // Show verification status dialog
            _showVerificationStatusDialog(context, user);
          } else {
            // Navigate to verification request screen
            Navigator.pushNamed(context, '/verification-request');
          }
        }
      } else if (value == 'toggle_privacy') {
        _handlePrivacyToggle(context);
      } else if (value == 'logout') {
        _showLogoutDialog(context);
      }
    });
  }

  void _showVerificationStatusDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.verified_user,
                color: Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Verification Status'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Congratulations! Your account is verified.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Blue Tick Verified',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your verification badge is visible to all users across the platform.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToUserProfile(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: post.userId,
          username: post.username,
          fullName: post.username, // Use username as fallback for fullName
          avatar: post.userAvatar,
          bio: '', // Default empty bio
          followersCount: 0, // Default value
          followingCount: 0, // Default value
          postsCount: 0, // Default value
          isPrivate: post.isPrivate ?? false, // Use the actual privacy status from post
        ),
      ),
    );
  }

  void _handlePrivacyToggle(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userProfile;
    
    if (user == null) return;
    
    try {
      final success = await authProvider.toggleAccountPrivacy();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account is now ${user.isPrivate ? 'public' : 'private'}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Failed to toggle privacy',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          // Verification Request Button (if not verified)
          if (!user.isVerified) ...[
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.pushNamed(context, '/verification-request');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Request Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Main Action Buttons Row
          Row(
            children: [
              // Edit Profile Button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _navigateToEditProfile(user),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Logout Button
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE53E3E),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _showLogoutDialog(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout,
                            color: Color(0xFFE53E3E),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Logout',
                            style: TextStyle(
                              color: Color(0xFFE53E3E),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggleButton(UserModel user) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Privacy Status Icon
              Icon(
                user.isPrivate ? Icons.lock : Icons.public,
                size: 20,
                color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              
              // Privacy Status Text
              Text(
                user.isPrivate ? 'Private Account' : 'Public Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
                  fontFamily: 'Poppins',
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Toggle Button
              GestureDetector(
                onTap: authProvider.isLoading ? null : () async {
                  try {
                    final success = await authProvider.toggleAccountPrivacy();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Account is now ${user.isPrivate ? 'public' : 'private'}',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.error ?? 'Failed to toggle privacy',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: const Color(0xFFE53E3E),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: const Color(0xFFE53E3E),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: user.isPrivate ? const Color(0xFF10B981) : const Color(0xFFE53E3E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.isPrivate ? const Color(0xFF10B981) : const Color(0xFFE53E3E),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (authProvider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          user.isPrivate ? Icons.public : Icons.lock,
                          size: 16,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        authProvider.isLoading 
                          ? 'Updating...' 
                          : (user.isPrivate ? 'Make Public' : 'Make Private'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightsSection(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return FutureBuilder<HighlightsListResponse>(
      future: HighlightService.getHighlights(
        token: authProvider.authToken ?? '',
        page: 1,
        limit: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
          print('ProfileScreen: Highlights error - ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final highlights = snapshot.data!.highlights;
        print('ProfileScreen: Found ${highlights.length} highlights');
        
        // Always show the highlights section, even if empty (to show "New" button)
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Highlights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (highlights.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HighlightsScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: highlights.length + 1, // +1 for "New" highlight button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "New" highlight button
                      return _buildNewHighlightButton();
                    } else {
                      final highlight = highlights[index - 1];
                      return _buildHighlightItem(highlight);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewHighlightButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateHighlightScreen(),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
                color: Colors.grey[50],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'New',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(Highlight highlight) {
    return GestureDetector(
      onTap: () {
        // Navigate to highlight viewer to show stories
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HighlightViewerScreen(highlight: highlight),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: highlight.stories.isNotEmpty && highlight.stories.first.media.isNotEmpty
                    ? Image.network(
                        highlight.stories.first.media,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.star,
                              color: Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.star,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              highlight.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 