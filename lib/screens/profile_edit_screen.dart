import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/dp_widget.dart';
import '../services/theme_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;
  Religion? _selectedReligion;
  bool _isLoading = false;
  
  // Local user object for editing
  late UserModel _editingUser;
  
  // Track original values to detect changes
  late String _originalFullName;
  late String _originalBio;
  late String _originalWebsite;
  late String _originalLocation;
  late Religion? _originalReligion;

  @override
  void initState() {
    super.initState();
    // Create a local copy of the user for editing
    _editingUser = widget.user;
    
    _fullNameController = TextEditingController(text: _editingUser.name);
    _bioController = TextEditingController(text: _editingUser.bio ?? '');
    _websiteController = TextEditingController(text: _editingUser.website ?? '');
    _locationController = TextEditingController(text: _editingUser.location ?? '');
    _selectedReligion = _editingUser.selectedReligion;
    
    // Store original values
    _originalFullName = _editingUser.name;
    _originalBio = _editingUser.bio ?? '';
    _originalWebsite = _editingUser.website ?? '';
    _originalLocation = _editingUser.location ?? '';
    _originalReligion = _editingUser.selectedReligion;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE1), // Same as login page
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EBE1),
        elevation: 0,
        leading: IconButton(
          onPressed: () => _handleBackNavigation(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2C2A)), // Deep Brown
        ),
        title: const Text(
          'Edit profile',
          style: TextStyle(
            color: Color(0xFF4A2C2A), // Deep Brown
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showLogoutMenu(),
            icon: const Icon(Icons.more_vert, color: Color(0xFF4A2C2A)), // Deep Brown
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              _buildInstagramProfileSection(),
              
              // Profile Information Fields
              _buildInstagramProfileFields(),
              
              // Additional Sections
              _buildInstagramAdditionalSections(),
              
              // Save Button
              _buildSaveButton(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Single profile picture
          Center(
            child: GestureDetector(
              onTap: () => _changeProfilePicture(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4A2C2A), width: 2),
                ),
                child: ClipOval(
                  child: _editingUser.profileImageUrl != null && _editingUser.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          _editingUser.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4A2C2A).withOpacity(0.1),
                                    const Color(0xFF4A2C2A).withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4A2C2A).withOpacity(0.1),
                                const Color(0xFF4A2C2A).withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Change profile picture text
          GestureDetector(
            onTap: () => _changeProfilePicture(),
            child: const Text(
              'Change profile picture',
              style: TextStyle(
                color: Color(0xFF4A2C2A), // Deep Brown
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInstagramProfileFields() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Name field
          _buildInstagramField(
            label: 'Name',
            controller: _fullNameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Username field
          _buildInstagramField(
            label: 'Username',
            controller: TextEditingController(text: _editingUser.username ?? ''),
            readOnly: true, // Username is usually not editable
          ),
          
          const SizedBox(height: 16),
          
          // Pronouns field
          _buildInstagramField(
            label: 'Pronouns',
            controller: TextEditingController(), // New field for pronouns
          ),
          
          const SizedBox(height: 16),
          
          // Bio field
          _buildInstagramField(
            label: 'Bio',
            controller: _bioController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A2C2A), // Deep Brown
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          validator: validator,
          style: const TextStyle(
            color: Color(0xFF4A2C2A), // Deep Brown
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8), // Same as login page
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2E5D4F), width: 2), // Deep Green
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstagramAdditionalSections() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Links section
          _buildInstagramSection(
            title: 'Links',
            subtitle: '1',
            onTap: () => _manageLinks(),
          ),
          
          const SizedBox(height: 16),
          
          // Add banners section
          _buildInstagramSection(
            title: 'Add banners',
            onTap: () => _addBanners(),
          ),
          
          const SizedBox(height: 16),
          
          // Gender section
          _buildInstagramSection(
            title: 'Gender',
            subtitle: 'Male',
            trailing: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A2C2A)),
            onTap: () => _selectGender(),
          ),
          
          const SizedBox(height: 16),
          
          // Music section
          _buildInstagramSection(
            title: 'Music',
            subtitle: 'Add music to your profile >',
            onTap: () => _addMusic(),
          ),
          
          const SizedBox(height: 24),
          
          // Threads badge section
          _buildThreadsBadgeSection(),
        ],
      ),
    );
  }

  Widget _buildInstagramSection({
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF4A2C2A), // Deep Brown
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildThreadsBadgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Show Threads badge',
                style: TextStyle(
                  color: Color(0xFF4A2C2A), // Deep Brown
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: false, // Default to off
              onChanged: (value) {
                // Handle Threads badge toggle
              },
              activeColor: const Color(0xFF2E5D4F), // Deep Green
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'When turned off, the Instagram badge on your Threads profile will also disappear.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1), // Muted Gold border
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4A2C2A),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFF4A2C2A), // Deep Brown
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  void _showLogoutMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0EBE1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF4A2C2A)),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFF4A2C2A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0EBE1),
        title: const Text(
          'Logout',
          style: TextStyle(color: Color(0xFF4A2C2A)),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF4A2C2A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF4A2C2A)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFF2E5D4F)),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _changeProfilePicture() {
    // Implement profile picture change functionality using DPWidget
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0EBE1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A2C2A),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4A2C2A)),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Color(0xFF4A2C2A)),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement camera functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4A2C2A)),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Color(0xFF4A2C2A)),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _selectAvatar() {
    // Implement avatar selection functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Select Avatar', style: TextStyle(color: Colors.white)),
        content: const Text('Avatar selection functionality', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _manageLinks() {
    // Implement links management functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Manage Links', style: TextStyle(color: Colors.white)),
        content: const Text('Links management functionality', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _addBanners() {
    // Implement add banners functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Banners', style: TextStyle(color: Colors.white)),
        content: const Text('Add banners functionality', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _selectGender() {
    // Implement gender selection functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Select Gender', style: TextStyle(color: Colors.white)),
        content: const Text('Gender selection functionality', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _addMusic() {
    // Implement add music functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Music', style: TextStyle(color: Colors.white)),
        content: const Text('Add music functionality', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        website: _websiteController.text.trim(),
        location: _locationController.text.trim(),
        religion: _selectedReligion?.toString().split('.').last,
      );

      if (success) {
        // Update theme if religion was changed
        if (_selectedReligion != null && _selectedReligion != _originalReligion) {
          final themeService = Provider.of<ThemeService>(context, listen: false);
          themeService.setUserReligion(_selectedReligion.toString().split('.').last);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! Theme updated based on your religion selection.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getReligionColor(Religion? religion) {
    switch (religion) {
      case Religion.hinduism:
        return ThemeService.hinduSaffronOrange;
      case Religion.islam:
        return ThemeService.islamDarkGreen;
      case Religion.christianity:
        return ThemeService.christianDeepBlue;
      case Religion.buddhism:
        return ThemeService.buddhistMonkOrange;
      case Religion.sikhism:
        return const Color(0xFFFFD700);
      case Religion.judaism:
        return Colors.indigo;
      case Religion.other:
        return const Color(0xFF9370DB);
      default:
        return ThemeService.defaultPrimary;
    }
  }

  void _handleBackNavigation() {
    // Check if any values have changed
    final hasChanges = _fullNameController.text.trim() != _originalFullName ||
        _bioController.text.trim() != _originalBio ||
        _websiteController.text.trim() != _originalWebsite ||
        _locationController.text.trim() != _originalLocation ||
        _selectedReligion != _originalReligion;

    if (hasChanges) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Are you sure you want to go back?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Stay on the screen
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Go back
                child: const Text('Discard'),
              ),
            ],
          );
        },
      ).then((value) {
        if (value == true) {
          Navigator.of(context).pop(true); // Return true to indicate discard
        }
      });
    } else {
      Navigator.of(context).pop(true); // No unsaved changes, go back
    }
  }
}
