import 'package:flutter/material.dart';
import '../widgets/follow_button.dart';

/// Test screen to verify private account follow request functionality
class TestPrivateAccountScreen extends StatefulWidget {
  const TestPrivateAccountScreen({super.key});

  @override
  State<TestPrivateAccountScreen> createState() => _TestPrivateAccountScreenState();
}

class _TestPrivateAccountScreenState extends State<TestPrivateAccountScreen> {
  bool _isFollowing = false;
  bool _isPrivate = true; // Simulate private account

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EBE1),
        elevation: 0,
        title: const Text(
          'Test Private Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username
                  const Text(
                    'Rupesh Sahu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Bio
                  const Text(
                    'I am Rupesh',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('6', 'posts'),
                      _buildStatItem('2', 'reels'),
                      _buildStatItem('0', 'followers'),
                      _buildStatItem('4', 'following'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Follow Button
                  FollowButton(
                    targetUserId: 'rupesh_test',
                    targetUserName: 'Rupesh Sahu',
                    isPrivate: _isPrivate,
                    isFollowing: _isFollowing,
                    onFollowChanged: () {
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Privacy Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isPrivate ? Colors.orange[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPrivate ? Colors.orange[200]! : Colors.green[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPrivate ? Icons.lock : Icons.public,
                    color: _isPrivate ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPrivate ? 'Private Account' : 'Public Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isPrivate ? Colors.orange[800] : Colors.green[800],
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isPrivate 
                            ? 'Follow requests are required to see posts'
                            : 'Anyone can follow and see posts',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isPrivate ? Colors.orange[700] : Colors.green[700],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Controls
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Controls',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle Privacy
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Account Privacy',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Switch(
                        value: _isPrivate,
                        onChanged: (value) {
                          setState(() {
                            _isPrivate = value;
                            _isFollowing = false; // Reset following when privacy changes
                          });
                        },
                        activeColor: Colors.orange,
                        inactiveThumbColor: Colors.green,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Reset Following
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isFollowing = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reset Following State',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }
}
