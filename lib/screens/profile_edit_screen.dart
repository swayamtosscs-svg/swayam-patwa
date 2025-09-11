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
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _handleBackNavigation(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              _buildProfileImageSection(),
              
              const SizedBox(height: 24),
              
              // Full Name Field
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Bio Field
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell us about yourself',
                icon: Icons.description,
                maxLines: 3,
              ),
              
              const SizedBox(height: 20),
              
              // Website Field
              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                hint: 'https://yourwebsite.com',
                icon: Icons.link,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // Basic URL validation
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Website must start with http:// or https://';
                    }
                    try {
                      Uri.parse(value);
                    } catch (e) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Location Field
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'Enter your location',
                icon: Icons.location_on,
              ),
              
              const SizedBox(height: 20),
              
              // Religion Selection
              _buildReligionSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          // Display Picture Widget
          DPWidget(
            currentImageUrl: _editingUser.profileImageUrl,
            userId: _editingUser.id,
            token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
            onImageChanged: (String newImageUrl) async {
              // Update the user profile with new image URL
              setState(() {
                // Create a new user object with updated profile image
                _editingUser = _editingUser.copyWith(
                  profileImageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                );
              });
              
              // Also update the auth provider for consistency
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.userProfile != null) {
                final updatedAuthUser = authProvider.userProfile!.copyWith(
                  profileImageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                );
                authProvider.updateLocalUserProfile(updatedAuthUser);
              }
            },
            size: 100,
            borderColor: _getReligionColor(_selectedReligion),
            showEditButton: true,
          ),
          
          const SizedBox(height: 12),
          
          // Info text
          Text(
            'Tap the camera icon to change or delete your profile picture',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
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
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF666666),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReligionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Religion',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedReligion != null
                  ? _getReligionColor(_selectedReligion)
                  : Colors.grey[300]!,
              width: _selectedReligion != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<Religion>(
            value: _selectedReligion,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.self_improvement, color: Color(0xFF666666)),
            ),
            hint: const Text(
              'Select your religion',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
            ),
            items: Religion.values.map((Religion religion) {
              return DropdownMenuItem<Religion>(
                value: religion,
                child: Row(
                  children: [
                    Text(
                      religion.religionSymbol,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      religion.religionDisplayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (Religion? newValue) {
              setState(() {
                _selectedReligion = newValue;
              });
              
              // Update theme immediately when religion changes
              if (newValue != null) {
                final themeService = Provider.of<ThemeService>(context, listen: false);
                themeService.setUserReligion(newValue.toString().split('.').last);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a religion';
              }
              return null;
            },
          ),
        ),
      ],
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
